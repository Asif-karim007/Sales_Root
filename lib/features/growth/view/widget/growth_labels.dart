import 'package:flutter/material.dart';

import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/models/notice.dart';
import 'package:salesroot/translations/translations.dart';

extension RuleSourceLabel on RuleSource {
  String label(AppLocalizations l10n) => switch (this) {
    RuleSource.facebook => l10n.growthSourceFacebook,
    RuleSource.website => l10n.growthSourceWebsite,
    RuleSource.whatsapp => l10n.growthSourceWhatsapp,
    RuleSource.messenger => l10n.growthSourceMessenger,
    RuleSource.sms => l10n.growthSourceSms,
    RuleSource.call => l10n.growthSourceCall,
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

extension AssignModeLabel on AssignMode {
  String label(AppLocalizations l10n) => switch (this) {
    AssignMode.member => l10n.growthModeMember,
    AssignMode.roundRobin => l10n.growthModeRoundRobin,
    AssignMode.byLoad => l10n.growthModeByLoad,
    AssignMode.queue => l10n.growthModeQueue,
  };
}

extension ConversationChannelLabel on ConversationChannel {
  String label(AppLocalizations l10n) => switch (this) {
    ConversationChannel.whatsapp => l10n.growthSourceWhatsapp,
    ConversationChannel.messenger => l10n.growthSourceMessenger,
    ConversationChannel.sms => l10n.growthSourceSms,
  };
}

extension AudienceSegmentLabel on AudienceSegment {
  String label(AppLocalizations l10n) => switch (this) {
    AudienceSegment.openLeads => l10n.growthSegmentOpenLeads,
    AudienceSegment.customers => l10n.growthSegmentCustomers,
    AudienceSegment.lostLeads => l10n.growthSegmentLost,
    AudienceSegment.facebookLeads => l10n.growthSegmentFacebook,
    AudienceSegment.websiteLeads => l10n.growthSegmentWebsite,
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
