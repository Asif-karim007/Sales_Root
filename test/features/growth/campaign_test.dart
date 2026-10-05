import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/providers/campaign_providers.dart';

import '../../helpers/api_stub.dart';
import 'growth_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const input = CampaignInput(
    name: 'Eid offer',
    channel: CampaignChannel.sms,
    segment: AudienceSegment.openLeads,
    body: ' Eid Mubarak {{name}}! ',
  );

  test('the recorded empty list parses as one page', () async {
    final container = await growthContainer(stub: growthStub(empty: true));
    final paged = await container.read(campaignListProvider.future);
    expect(paged.isEmpty, isTrue);
    expect(paged.hasMore, isFalse);
  });

  test('campaigns read their audience, results and schedule', () async {
    final container = await growthContainer();
    final paged = await container.read(campaignListProvider.future);
    final [scheduled, sent] = paged.items;

    expect(scheduled.status, CampaignStatus.scheduled);
    expect(scheduled.segment, AudienceSegment.openLeads);
    expect(scheduled.scheduledAt, isNotNull);
    expect(sent.status, CampaignStatus.done);
    expect(sent.segment, AudienceSegment.customers);
    expect(sent.deliveredShare, closeTo(0.9, 0.001));
    expect(sent.failed, 4);
  });

  test('every segment is previewed with its lead filter', () async {
    final stub = growthStub();
    final container = await growthContainer(stub: stub);

    final audiences = await container.read(
      campaignAudiencesProvider(CampaignChannel.sms).future,
    );
    final previews = stub.requests.where(
      (r) => r.method == 'POST' && r.path.endsWith('campaigns/preview'),
    );
    expect(previews, hasLength(AudienceSegment.values.length));
    final byFilter = {for (final a in audiences) a.segment: a};
    final open = byFilter[AudienceSegment.openLeads];
    expect(open?.count, 6);
    expect(open?.estimatedCost, closeTo(2.1, 0.001));
    expect(byFilter[AudienceSegment.facebookLeads]?.count, 1);
  });

  test('sending posts the campaign without empty fields', () async {
    final stub = growthStub()
      ..on('POST', 'campaigns', {
        'id': scheduledCampaign,
        'status': 'scheduled',
        'recipientCount': 6,
      });
    final container = await growthContainer(stub: stub);
    final sub = container.listen(campaignSubmitProvider, (_, _) {});
    addTearDown(sub.close);

    await container
        .read(campaignSubmitProvider.notifier)
        .submit(
          CampaignInput(
            name: input.name,
            channel: input.channel,
            segment: input.segment,
            body: input.body,
            scheduledAt: DateTime.utc(2026, 10, 8, 4),
          ),
        );
    expect(stub.lastBody('POST', 'campaigns'), {
      'name': 'Eid offer',
      'channel': 'sms',
      'audience': {'status': 'open'},
      'body': 'Eid Mubarak {{name}}!',
      'scheduledAt': '2026-10-08T04:00:00.000Z',
    });
    final campaign = container.read(campaignSubmitProvider).requireValue;
    expect(campaign?.status, CampaignStatus.scheduled);
    expect(campaign?.recipients, 6);
  });

  test('not enough credits and a missing message reach the screen', () async {
    final stub = growthStub()
      ..fail('POST', 'campaigns', 402, message: 'Not enough SMS credits');
    final container = await growthContainer(stub: stub);
    final sub = container.listen(campaignSubmitProvider, (_, _) {});
    addTearDown(sub.close);
    final submit = container.read(campaignSubmitProvider.notifier);

    await submit.submit(input);
    expect(
      (container.read(campaignSubmitProvider).error as ApiFailure?)?.isQuota,
      isTrue,
    );

    stub.fail(
      'POST',
      'campaigns',
      422,
      message: 'Write the message',
      field: 'body',
    );
    await submit.submit(input);
    final failure = container.read(campaignSubmitProvider).error as ApiFailure?;
    expect(failure?.isValidation, isTrue);
    expect(failure?.fieldError('body'), isNotNull);
  });

  test('cancelling posts and reloads the campaign', () async {
    final stub = growthStub()
      ..on('POST', 'campaigns/{id}/cancel', const StubReply(204));
    final container = await growthContainer(stub: stub);

    final campaign = await container
        .read(campaignActionsProvider.notifier)
        .cancel(scheduledCampaign);
    expect(
      stub.last('POST', 'campaigns/{id}/cancel')?.uri.path,
      contains(scheduledCampaign),
    );
    expect(campaign.id, scheduledCampaign);
  });

  test('SMS credits come from the plan', () async {
    final container = await growthContainer();
    final billing = fixture('billing') as Map;
    expect(
      await container.read(smsCreditsProvider.future),
      (billing['workspace'] as Map)['smsCredits'],
    );
  });
}
