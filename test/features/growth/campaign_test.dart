import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/models/sms_count.dart';
import 'package:salesroot/features/growth/providers/campaign_providers.dart';

import 'growth_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const message =
      'প্রিয় {{name}}, আপনার বিল বাকি আছে। bKash 01711-000000 বা অফিসে দিতে পারেন।';

  SmsCampaignInput input({bool now = true}) => SmsCampaignInput(
    name: 'Reminder',
    segment: AudienceSegment.customers,
    message: message,
    excludeDoNotContact: true,
    scheduleAt: now ? null : DateTime.now().add(const Duration(days: 1)),
  );

  test('the list puts scheduled campaigns first', () async {
    final container = await growthContainer();
    final paged = await container.read(campaignListProvider.future);
    expect(paged.items.first.status, CampaignStatus.scheduled);
    expect(paged.totalCount, paged.items.length);
  });

  test(
    'sending without enough credits fails with a 402 for SMS credits',
    () async {
      final container = await growthContainer(workspace: 100);
      final sub = container.listen(smsCampaignSubmitProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(smsCampaignSubmitProvider.notifier).submit(input());

      final state = container.read(smsCampaignSubmitProvider);
      expect(
        state.error,
        isA<ApiFailure>()
            .having((f) => f.statusCode, 'status', 402)
            .having((f) => f.quota, 'quota', QuotaKind.smsCredits),
      );
    },
  );

  test('buying credits lets the campaign go out and spends its cost', () async {
    final container = await growthContainer(workspace: 100);
    final repository = container.read(campaignRepositoryProvider);
    final audience = (await repository.audiences()).firstWhere(
      (a) => a.segment == AudienceSegment.customers,
    );
    final cost =
        SmsCount.of(message).segments *
        audience.reach(excludeDoNotContact: true);

    final bought = await repository.buyCredits(1);
    expect(bought.smsCredits, 1000);

    final campaign = await repository.sendSms(input());
    expect(campaign.status, CampaignStatus.done);
    expect(campaign.creditsUsed, cost);
    expect((await repository.balance()).smsCredits, 1000 - cost);
  });

  test('cancelling a scheduled campaign returns its credits', () async {
    final container = await growthContainer();
    final repository = container.read(campaignRepositoryProvider);
    final before = (await repository.balance()).smsCredits;

    final scheduled = await repository.sendSms(input(now: false));
    expect(scheduled.status, CampaignStatus.scheduled);
    expect(
      (await repository.balance()).smsCredits,
      before - scheduled.creditsUsed,
    );

    final cancelled = await container
        .read(campaignActionsProvider.notifier)
        .cancel(scheduled.id);
    expect(cancelled.status, CampaignStatus.cancelled);
    expect((await repository.balance()).smsCredits, before);
  });

  test('the dev quota switch blocks sending with a 402', () async {
    final container = await growthContainer();
    reachQuota(container);
    await expectLater(
      container.read(campaignRepositoryProvider).sendSms(input()),
      throwsA(isA<ApiFailure>().having((f) => f.isQuota, 'quota', true)),
    );
  });
}
