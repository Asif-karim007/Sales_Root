import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/billing/data/fake_referral_ledger.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';

import 'billing_test_setup.dart';

void main() {
  test('the overview agrees with the invites and the wallet', () async {
    final container = await billingContainer();
    final overview = await container.read(referralOverviewProvider.future);
    expect(overview.code, 'KH7R2M');
    expect(overview.invited, 26);
    expect(overview.joined, 12);
    expect(overview.paid, 3);
    expect(overview.onHold, 20);
    expect(overview.holdCount, 2);
    expect(overview.used, 500);
    expect(overview.balance, overview.earned - 199 - 500 - overview.onHold);
    expect(overview.nextMilestone?.paid, 5);
    expect(overview.expiringAmount, 60);
    expect(
      overview.recent.map((r) => r.name.en),
      containsAll(['Rashed Khan', 'Sumi Begum']),
    );
  });

  test('the list pages 20 at a time and filters by status', () async {
    final container = await billingContainer();
    container.listen(referralsProvider, (_, _) {});
    final first = await container.read(referralsProvider.future);
    expect(first.items, hasLength(20));
    expect(first.facets['StatusCounts']?['Pending'], 7);

    await container.read(referralsProvider.notifier).loadMore();
    expect(container.read(referralsProvider).requireValue.items, hasLength(26));

    container.read(referralFilterProvider.notifier).set(ReferralStatus.pending);
    final pending = await container.read(referralsProvider.future);
    expect(pending.items, hasLength(7));
    expect(pending.items.every((r) => r.daysLeft > 0), isTrue);
  });

  group('invite eligibility (#184)', () {
    Future<InviteCheck> check(ProviderContainer container, String contact) =>
        container.read(referralRepositoryProvider).check(contact);

    test('a new BD mobile is eligible for the registration reward', () async {
      final container = await billingContainer();
      final result = await check(container, '01819 334 455');
      expect(result.eligibility, InviteEligibility.eligible);
      expect(result.reward, 10);
    });

    test('garbage and foreign numbers are invalid', () async {
      final container = await billingContainer();
      for (final input in ['abc', '0123', '+4420794600', 'me@x']) {
        final result = await check(container, input);
        expect(result.eligibility, InviteEligibility.invalid, reason: input);
      }
    });

    test('a pending invite says how many days are left', () async {
      final container = await billingContainer();
      final result = await check(container, '+880 1819-226655');
      expect(result.eligibility, InviteEligibility.alreadyInvited);
      expect(result.daysLeft, 88);
    });

    test('people already on SalesRoot are not eligible', () async {
      final container = await billingContainer();
      final member = container.read(seedGraphProvider).members.first;
      expect(
        (await check(container, member.phone)).eligibility,
        InviteEligibility.alreadyUser,
      );
      expect(
        (await check(container, '01715288144')).eligibility,
        InviteEligibility.alreadyUser,
      );
    });

    test('a contact referred by someone else is not eligible', () async {
      final container = await billingContainer();
      final contact = container
          .read(seedGraphProvider)
          .contacts
          .firstWhere((c) => c.id % 4 == 0);
      final result = await check(container, contact.phone);
      expect(result.eligibility, InviteEligibility.referredByOther);
    });
  });

  test('an invite is recorded once and then reads as invited', () async {
    final container = await billingContainer();
    container.listen(inviteProvider, (_, _) {});
    await container
        .read(inviteProvider.notifier)
        .send('01819334455', sms: true);
    final saved = container.read(inviteProvider).value;
    expect(saved?.status, ReferralStatus.pending);
    expect(saved?.phoneMasked, FakeReferralLedger.mask('01819334455'));

    final again = await container
        .read(referralRepositoryProvider)
        .check('01819334455');
    expect(again.eligibility, InviteEligibility.alreadyInvited);
    expect(again.daysLeft, 90);
    final overview = await container.read(referralOverviewProvider.future);
    expect(overview.invited, 27);
  });

  test('inviting someone who is not eligible fails', () async {
    final container = await billingContainer();
    final repository = container.read(referralRepositoryProvider);
    await expectLater(
      repository.invite('01715288144', sendSms: true),
      throwsA(isA<ApiFailure>().having((f) => f.isConflict, 'conflict', true)),
    );
    await expectLater(
      repository.invite('123', sendSms: false),
      throwsA(isA<ApiFailure>().having((f) => f.isValidation, 'invalid', true)),
    );
  });

  test('the reward moment shows once', () async {
    final container = await billingContainer();
    container.listen(pendingRewardProvider, (_, _) {});
    final moment = await container.read(pendingRewardProvider.future);
    expect(moment?.amount, 10);
    expect(moment?.name.en, 'Sumi Begum');
    expect(moment?.holdHours, greaterThan(0));

    await container
        .read(pendingRewardProvider.notifier)
        .markSeen(moment?.id ?? 0);
    container.invalidate(pendingRewardProvider);
    expect(await container.read(pendingRewardProvider.future), isNull);
  });

  test('the wallet pages its entries newest first', () async {
    final container = await billingContainer();
    final entries = await container.read(walletEntriesProvider.future);
    expect(entries.totalCount, greaterThan(15));
    final dates = [for (final e in entries.items) e.at];
    expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
    expect(entries.items.where((e) => e.held), hasLength(2));
  });
}
