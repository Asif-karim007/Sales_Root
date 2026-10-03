import 'package:flutter/material.dart';

import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/settings/models/more_entry.dart';
import 'package:salesroot/l10n/l10n.dart';

extension MoreEntryLabels on MoreEntry {
  String label(AppLocalizations l10n) => switch (this) {
    MoreEntry.contacts => l10n.settingsMoreContacts,
    MoreEntry.companies => l10n.settingsMoreCompanies,
    MoreEntry.calendar => l10n.settingsMoreCalendar,
    MoreEntry.visits => l10n.settingsMoreVisits,
    MoreEntry.attendance => l10n.settingsMoreAttendance,
    MoreEntry.liveTracking => l10n.settingsMoreLiveTracking,
    MoreEntry.quotations => l10n.settingsMoreQuotations,
    MoreEntry.products => l10n.settingsMoreProducts,
    MoreEntry.collection => l10n.settingsMoreCollection,
    MoreEntry.reports => l10n.settingsMoreReports,
    MoreEntry.team => l10n.settingsMoreTeam,
    MoreEntry.chat => l10n.settingsMoreChat,
    MoreEntry.files => l10n.settingsMoreFiles,
    MoreEntry.notices => l10n.settingsMoreNotices,
    MoreEntry.newLeads => l10n.settingsMoreNewLeads,
    MoreEntry.messages => l10n.settingsMoreMessages,
    MoreEntry.campaigns => l10n.settingsMoreCampaigns,
    MoreEntry.leadSources => l10n.settingsMoreLeadSources,
    MoreEntry.leave => l10n.settingsMoreLeave,
    MoreEntry.expenses => l10n.settingsMoreExpenses,
    MoreEntry.approvals => l10n.settingsMoreApprovals,
    MoreEntry.payslip => l10n.settingsMorePayslip,
    MoreEntry.employeeCard => l10n.settingsMoreEmployeeCard,
    MoreEntry.billing => l10n.settingsMoreBilling,
    MoreEntry.refer => l10n.settingsMoreRefer,
    MoreEntry.help => l10n.settingsMoreHelp,
    MoreEntry.feedback => l10n.settingsMoreFeedback,
    MoreEntry.academy => l10n.settingsMoreAcademy,
    MoreEntry.aiGuide => l10n.settingsMoreAiGuide,
    MoreEntry.dataSafety => l10n.settingsMoreDataSafety,
    MoreEntry.about => l10n.settingsMoreAbout,
    MoreEntry.settings => l10n.settingsTitle,
    MoreEntry.sync => l10n.settingsMoreSync,
  };

  IconData get icon => switch (this) {
    MoreEntry.contacts => Icons.contacts_outlined,
    MoreEntry.companies => Icons.apartment_outlined,
    MoreEntry.calendar => Icons.calendar_month_outlined,
    MoreEntry.visits => Icons.place_outlined,
    MoreEntry.attendance => Icons.fingerprint_rounded,
    MoreEntry.liveTracking => Icons.my_location_rounded,
    MoreEntry.quotations => Icons.request_quote_outlined,
    MoreEntry.products => Icons.solar_power_outlined,
    MoreEntry.collection => Icons.payments_outlined,
    MoreEntry.reports => Icons.bar_chart_rounded,
    MoreEntry.team => Icons.groups_outlined,
    MoreEntry.chat => Icons.chat_bubble_outline_rounded,
    MoreEntry.files => Icons.folder_outlined,
    MoreEntry.notices => Icons.campaign_outlined,
    MoreEntry.newLeads => Icons.move_to_inbox_outlined,
    MoreEntry.messages => Icons.forum_outlined,
    MoreEntry.campaigns => Icons.send_outlined,
    MoreEntry.leadSources => Icons.hub_outlined,
    MoreEntry.leave => Icons.beach_access_outlined,
    MoreEntry.expenses => Icons.receipt_long_outlined,
    MoreEntry.approvals => Icons.fact_check_outlined,
    MoreEntry.payslip => Icons.account_balance_wallet_outlined,
    MoreEntry.employeeCard => Icons.badge_outlined,
    MoreEntry.billing => Icons.workspace_premium_outlined,
    MoreEntry.refer => Icons.card_giftcard_rounded,
    MoreEntry.help => Icons.support_agent_rounded,
    MoreEntry.feedback => Icons.rate_review_outlined,
    MoreEntry.academy => Icons.school_outlined,
    MoreEntry.aiGuide => Icons.auto_awesome_outlined,
    MoreEntry.dataSafety => Icons.verified_user_outlined,
    MoreEntry.about => Icons.info_outline_rounded,
    MoreEntry.settings => Icons.settings_outlined,
    MoreEntry.sync => Icons.sync_rounded,
  };
}

extension MoreGroupLabels on MoreGroup {
  String label(AppLocalizations l10n) => switch (this) {
    MoreGroup.customers => l10n.settingsMoreGroupCustomers,
    MoreGroup.sales => l10n.settingsMoreGroupSales,
    MoreGroup.team => l10n.settingsMoreGroupTeam,
    MoreGroup.growth => l10n.settingsMoreGroupGrowth,
    MoreGroup.hr => l10n.settingsMoreGroupHr,
    MoreGroup.plan => l10n.settingsMoreGroupPlan,
    MoreGroup.help => l10n.settingsMoreGroupHelp,
    MoreGroup.app => l10n.settingsMoreGroupApp,
  };
}

extension WorkspaceRoleLabel on WorkspaceRole {
  String label(AppLocalizations l10n) => switch (this) {
    WorkspaceRole.owner => l10n.settingsRoleOwner,
    WorkspaceRole.teamLead => l10n.settingsRoleTeamLead,
    WorkspaceRole.member => l10n.settingsRoleMember,
  };
}
