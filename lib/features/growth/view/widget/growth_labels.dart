import 'package:flutter/material.dart';

import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';
import 'package:salesroot/features/growth/models/notice.dart';
import 'package:salesroot/translations/translations.dart';

extension InboxSourceLabel on InboxSource {
  String label(AppLocalizations l10n) => switch (this) {
    InboxSource.facebook => l10n.growthSourceFacebook,
    InboxSource.website => l10n.growthSourceWebsite,
    InboxSource.whatsapp => l10n.growthSourceWhatsapp,
    InboxSource.messenger => l10n.growthSourceMessenger,
    InboxSource.sms => l10n.growthSourceSms,
    InboxSource.call => l10n.growthSourceCall,
  };

  IconData get icon => switch (this) {
    InboxSource.facebook => Icons.facebook_rounded,
    InboxSource.website => Icons.language_rounded,
    InboxSource.whatsapp => Icons.chat_rounded,
    InboxSource.messenger => Icons.forum_rounded,
    InboxSource.sms => Icons.sms_outlined,
    InboxSource.call => Icons.call_outlined,
  };
}

extension ChannelKindLabel on ChannelKind {
  String label(AppLocalizations l10n) => switch (this) {
    ChannelKind.facebook => l10n.growthChannelFacebook,
    ChannelKind.whatsapp => l10n.growthChannelWhatsapp,
    ChannelKind.messenger => l10n.growthChannelMessenger,
    ChannelKind.website => l10n.growthChannelWebsite,
    ChannelKind.hostedForm => l10n.growthChannelHostedForm,
    ChannelKind.email => l10n.growthChannelEmail,
    ChannelKind.linkedin => l10n.growthChannelLinkedin,
    ChannelKind.googleAds => l10n.growthChannelGoogleAds,
  };

  IconData get icon => switch (this) {
    ChannelKind.facebook => Icons.facebook_rounded,
    ChannelKind.whatsapp => Icons.chat_rounded,
    ChannelKind.messenger => Icons.forum_rounded,
    ChannelKind.website => Icons.code_rounded,
    ChannelKind.hostedForm => Icons.dynamic_form_outlined,
    ChannelKind.email => Icons.mail_outline_rounded,
    ChannelKind.linkedin => Icons.work_outline_rounded,
    ChannelKind.googleAds => Icons.campaign_outlined,
  };
}

extension LeadFieldLabel on LeadField {
  String label(AppLocalizations l10n) => switch (this) {
    LeadField.name => l10n.growthFieldName,
    LeadField.mobile => l10n.growthFieldMobile,
    LeadField.email => l10n.growthFieldEmail,
    LeadField.area => l10n.growthFieldArea,
    LeadField.company => l10n.growthFieldCompany,
    LeadField.note => l10n.growthFieldNote,
    LeadField.custom => l10n.growthFieldCustom,
    LeadField.skip => l10n.growthFieldSkip,
  };
}

extension LeadDestinationLabel on LeadDestination {
  String label(AppLocalizations l10n) => switch (this) {
    LeadDestination.inbox => l10n.growthDestinationInbox,
    LeadDestination.rules => l10n.growthDestinationRules,
  };
}

extension AssignModeLabel on AssignMode {
  String label(AppLocalizations l10n) => switch (this) {
    AssignMode.member => l10n.growthModeMember,
    AssignMode.roundRobin => l10n.growthModeRoundRobin,
    AssignMode.byLoad => l10n.growthModeByLoad,
    AssignMode.queue => l10n.growthModeQueue,
  };
}

extension RejectReasonLabel on RejectReason {
  String label(AppLocalizations l10n) => switch (this) {
    RejectReason.spam => l10n.growthRejectSpam,
    RejectReason.wrongNumber => l10n.growthRejectWrongNumber,
    RejectReason.notInterested => l10n.growthRejectNotInterested,
    RejectReason.duplicate => l10n.growthRejectDuplicate,
    RejectReason.outOfArea => l10n.growthRejectOutOfArea,
  };
}

extension ThreadChannelLabel on ThreadChannel {
  String label(AppLocalizations l10n) => switch (this) {
    ThreadChannel.whatsapp => l10n.growthSourceWhatsapp,
    ThreadChannel.messenger => l10n.growthSourceMessenger,
    ThreadChannel.sms => l10n.growthSourceSms,
  };
}

extension AudienceSegmentLabel on AudienceSegment {
  String label(AppLocalizations l10n) => switch (this) {
    AudienceSegment.overdueCustomers => l10n.growthSegmentOverdue,
    AudienceSegment.customers => l10n.growthSegmentCustomers,
    AudienceSegment.dealers => l10n.growthSegmentDealers,
    AudienceSegment.hotLeads => l10n.growthSegmentHotLeads,
    AudienceSegment.interestedLeads => l10n.growthSegmentInterested,
    AudienceSegment.openLeads => l10n.growthSegmentOpenLeads,
  };
}

extension NoticeAudienceLabel on NoticeAudience {
  String label(AppLocalizations l10n) => switch (this) {
    NoticeAudience.everyone => l10n.growthAudienceEveryone,
    NoticeAudience.sales => l10n.growthAudienceSales,
    NoticeAudience.field => l10n.growthAudienceField,
    NoticeAudience.leads => l10n.growthAudienceLeads,
  };
}

extension AuthorRoleLabel on AuthorRole {
  String label(AppLocalizations l10n) => switch (this) {
    AuthorRole.owner => l10n.growthRoleOwner,
    AuthorRole.admin => l10n.growthRoleAdmin,
    AuthorRole.teamLead => l10n.growthRoleTeamLead,
  };
}
