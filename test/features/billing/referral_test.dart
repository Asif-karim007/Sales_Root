import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/billing/data/billing_repositories.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';

import '../../helpers/api_stub.dart';
import 'billing_test_setup.dart';

void main() {
  test('the overview reads the code, campaign, wallet and invites', () async {
    final container = await billingContainer(billingStub());

    final overview = await container.read(referralOverviewProvider.future);

    expect(overview.code, 'Q95ED5');
    expect(overview.link, 'https://q.salesrootcrm.com/r/Q95ED5');
    expect(overview.registerReward, 10);
    expect(overview.conversionPercent, 10);
    expect(overview.conversionCap, 500);
    expect(overview.trialDays, 15);
    expect(overview.friendCredits, 50);
    expect(overview.holdDays, 7);
    expect(overview.invited, 2);
    expect(overview.nextPrize?.credits, 199);
    expect(overview.nextPrize?.referralsNeeded, 20);
    expect(overview.nextPrize?.name.en, '1 month of Personal');
    expect(overview.shareText.en, contains('Q95ED5'));
    expect(overview.recent.first.status, ReferralStatus.notEligible);
    expect(overview.recent.first.contact, '+88017****01');
    final invite = overview.recent.last;
    expect(invite.id, referralId);
    expect(invite.contact, 'se***@example.com');
    expect(invite.status, ReferralStatus.pending);
    expect(invite.invitedAt, isNotNull);
  });

  test('the list pages by offset', () async {
    final stub = billingStub();
    final container = await billingContainer(stub);
    listenTo(container, referralsProvider);

    final first = await container.read(referralsProvider.future);
    await container.read(referralsProvider.notifier).loadMore();

    expect(first.items.last.id, referralId);
    expect(first.hasMore, isFalse);
    expect(stub.last('GET', 'referrals')?.queryParameters['offset'], 0);
    expect(stub.last('GET', 'referrals')?.queryParameters['limit'], 20);
  });

  test('the wallet always asks for a date range', () async {
    final stub = billingStub();
    final container = await billingContainer(stub);
    listenTo(container, walletEntriesProvider);

    final entries = await container.read(walletEntriesProvider.future);

    expect(entries.items, isEmpty);
    final query = stub.last('GET', 'wallet/transactions')?.queryParameters;
    expect(query?['from'], '2020-01-01');
    expect(query?['to'], matches(RegExp(r'^\d{4}-\d\d-\d\d$')));
  });

  group('eligibility', () {
    test('a new number is eligible', () async {
      final stub = billingStub();
      final container = await billingContainer(stub);
      listenTo(container, inviteCheckProvider('+8801811000099'));

      expect(
        await container.read(inviteCheckProvider('+8801811000099').future),
        InviteEligibility.eligible,
      );
      expect(stub.last('GET', 'referrals/check')?.queryParameters, {
        'phone': '+8801811000099',
      });
    });

    test('someone already on SalesRoot is not', () async {
      final stub = billingStub()
        ..on('GET', 'referrals/check', fixture('billing_referral_check_user'));
      final container = await billingContainer(stub);

      expect(
        await container.read(referralRepositoryProvider).check('a@b.co'),
        InviteEligibility.alreadyUser,
      );
      expect(stub.last('GET', 'referrals/check')?.queryParameters, {
        'email': 'a@b.co',
      });
    });
  });

  test('an invite sends the contact and channel, then reloads', () async {
    final stub = billingStub();
    final container = await billingContainer(stub);
    listenTo(container, inviteProvider);

    await container
        .read(inviteProvider.notifier)
        .send('+8801811000099', sms: true);

    expect(stub.lastBody('POST', 'referrals'), {
      'phone': '+8801811000099',
      'email': null,
      'channel': 'sms',
      'name': null,
    });
    final result = container.read(inviteProvider).value;
    expect(result?.id, referralId);
    expect(result?.message.en, 'Referral sent');
  });

  test('an invite the server refuses is an error', () async {
    final stub = billingStub()..fail('POST', 'referrals', 422, message: 'Bad');
    final container = await billingContainer(stub);
    listenTo(container, inviteProvider);

    await container.read(inviteProvider.notifier).send('x', sms: false);

    expect(container.read(inviteProvider).error, isA<ApiFailure>());
  });

  test('contacts to invite are the ones with a phone', () async {
    final stub = billingStub();
    final container = await billingContainer(stub);

    final contacts = await container
        .read(referralRepositoryProvider)
        .contacts('far', 1);

    expect(contacts, isNotEmpty);
    expect(contacts.every((c) => c.phone.isNotEmpty), isTrue);
    expect(stub.last('GET', 'contacts')?.queryParameters['q'], 'far');
  });
}
