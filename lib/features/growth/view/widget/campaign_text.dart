import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/models/sms_count.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

String campaignChannelLabel(AppLocalizations l10n, CampaignChannel channel) =>
    switch (channel) {
      CampaignChannel.sms => l10n.growthCampaignSms,
      CampaignChannel.email => l10n.growthCampaignEmail,
    };

/// "19 people · All open leads", or just the count when the audience is not
/// one of the app's segments.
String campaignPeople(BuildContext context, Campaign campaign) {
  final l10n = context.l10n;
  final count = context.fmt.number(campaign.recipients);
  final segment = campaign.segment;
  return segment == null
      ? l10n.growthCampaignCount(count)
      : l10n.growthCampaignPeople(count, segment.label(l10n));
}

/// The results line under a campaign, or when and to whom it will go.
String campaignSummary(BuildContext context, Campaign campaign) {
  final l10n = context.l10n;
  final fmt = context.fmt;
  final people = campaignPeople(context, campaign);
  final scheduledAt = campaign.scheduledAt;
  return switch (campaign.status) {
    CampaignStatus.scheduled when scheduledAt != null =>
      '$people · ${fmt.dayTime(scheduledAt)}',
    CampaignStatus.cancelled => '${l10n.growthCampaignCancelledTag} · $people',
    CampaignStatus.scheduled || CampaignStatus.sending => people,
    CampaignStatus.done => [
      l10n.growthCampaignSent(fmt.number(campaign.sent)),
      l10n.growthCampaignDelivered(fmt.percent(campaign.deliveredShare * 100)),
      if (campaign.replies > 0)
        l10n.growthCampaignReplies(fmt.number(campaign.replies)),
    ].join(' · '),
  };
}

/// "Characters 138 / 160 (Bangla: 70)".
String smsLengthLine(BuildContext context, SmsCount count) {
  final l10n = context.l10n;
  final fmt = context.fmt;
  final used = l10n.growthCampaignOf(
    fmt.number(count.length),
    fmt.number(count.capacity),
  );
  return count.isUnicode
      ? l10n.growthSmsLengthBangla(used, fmt.number(70))
      : l10n.growthSmsLengthEnglish(used, fmt.number(160));
}

class CampaignStatusTag extends StatelessWidget {
  const CampaignStatusTag({super.key, required this.status});

  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (status) {
      CampaignStatus.done => SrTag(l10n.growthCampaignDoneTag, tone: SrTone.ok),
      CampaignStatus.scheduled => SrTag(
        l10n.growthCampaignScheduledTag,
        tone: SrTone.warn,
      ),
      CampaignStatus.sending => SrTag(
        l10n.growthCampaignSendingTag,
        tone: SrTone.info,
      ),
      CampaignStatus.cancelled => SrTag(l10n.growthCampaignCancelledTag),
    };
  }
}
