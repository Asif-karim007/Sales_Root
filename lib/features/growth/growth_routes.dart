import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/view/bulk_email_screen.dart';
import 'package:salesroot/features/growth/view/bulk_sms_screen.dart';
import 'package:salesroot/features/growth/view/campaign_result_screen.dart';
import 'package:salesroot/features/growth/view/campaigns_screen.dart';
import 'package:salesroot/features/growth/view/channels_screen.dart';
import 'package:salesroot/features/growth/view/distribution_screen.dart';
import 'package:salesroot/features/growth/view/facebook_connect_screen.dart';
import 'package:salesroot/features/growth/view/message_thread_screen.dart';
import 'package:salesroot/features/growth/view/messages_screen.dart';
import 'package:salesroot/features/growth/view/new_lead_screen.dart';
import 'package:salesroot/features/growth/view/new_leads_screen.dart';
import 'package:salesroot/features/growth/view/notice_screen.dart';
import 'package:salesroot/features/growth/view/notice_write_screen.dart';
import 'package:salesroot/features/growth/view/notices_screen.dart';
import 'package:salesroot/features/growth/view/rule_edit_screen.dart';
import 'package:salesroot/features/growth/view/sms_credits_screen.dart';

final List<RouteBase> growthRoutes = [
  GoRoute(
    path: Routes.growthChannels,
    redirect: requireAccess(AppModule.leadSources),
    builder: (context, state) => const ChannelsScreen(),
  ),
  GoRoute(
    path: Routes.growthFacebook,
    redirect: requireAccess(AppModule.leadSources, ModuleRight.edit),
    builder: (context, state) => const FacebookConnectScreen(),
  ),
  GoRoute(
    path: Routes.newLeads,
    redirect: requireAccess(AppModule.inbox),
    builder: (context, state) => const NewLeadsScreen(),
  ),
  GoRoute(
    path: Routes.newLead,
    redirect: requireAccess(AppModule.inbox),
    builder: (context, state) => NewLeadScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.newLeadAccept,
    redirect: requireAccess(AppModule.inbox, ModuleRight.edit),
    builder: (context, state) =>
        NewLeadScreen(id: idParam(state), openAccept: true),
  ),
  GoRoute(
    path: Routes.distribution,
    redirect: requireAccess(AppModule.distribution),
    builder: (context, state) => const DistributionScreen(),
  ),
  GoRoute(
    path: Routes.distributionRule,
    redirect: requireAccess(AppModule.distribution, ModuleRight.edit),
    builder: (context, state) => RuleEditScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.messages,
    redirect: requireAccess(AppModule.inbox),
    builder: (context, state) => const MessagesScreen(),
  ),
  GoRoute(
    path: Routes.messageThread,
    redirect: requireAccess(AppModule.inbox),
    builder: (context, state) => MessageThreadScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.campaigns,
    redirect: requireAccess(AppModule.campaign),
    builder: (context, state) => const CampaignsScreen(),
  ),
  GoRoute(
    path: Routes.campaignSms,
    redirect: requireAccess(AppModule.campaign, ModuleRight.add),
    builder: (context, state) => const BulkSmsScreen(),
  ),
  GoRoute(
    path: Routes.campaignEmail,
    redirect: requireAccess(AppModule.campaign, ModuleRight.add),
    builder: (context, state) => const BulkEmailScreen(),
  ),
  GoRoute(
    path: Routes.campaignCredits,
    redirect: requireAccess(AppModule.campaign),
    builder: (context, state) => const SmsCreditsScreen(),
  ),
  GoRoute(
    path: Routes.campaign,
    redirect: requireAccess(AppModule.campaign),
    builder: (context, state) => CampaignResultScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.notices,
    redirect: requireAccess(AppModule.notice),
    builder: (context, state) => const NoticesScreen(),
  ),
  GoRoute(
    path: Routes.noticeNew,
    redirect: requireAccess(AppModule.notice, ModuleRight.add),
    builder: (context, state) => const NoticeWriteScreen(),
  ),
  GoRoute(
    path: Routes.notice,
    redirect: requireAccess(AppModule.notice),
    builder: (context, state) => NoticeScreen(id: idParam(state)),
  ),
];
