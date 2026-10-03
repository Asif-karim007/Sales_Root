import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final List<RouteBase> growthRoutes = [
  GoRoute(
    path: Routes.growthChannels,
    redirect: requireAccess(AppModule.leadSources),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.growthFacebook,
    redirect: requireAccess(AppModule.leadSources, ModuleRight.edit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.newLeads,
    redirect: requireAccess(AppModule.inbox),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.newLead,
    redirect: requireAccess(AppModule.inbox),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.newLeadAccept,
    redirect: requireAccess(AppModule.inbox, ModuleRight.edit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.distribution,
    redirect: requireAccess(AppModule.distribution),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.distributionRule,
    redirect: requireAccess(AppModule.distribution, ModuleRight.edit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.messages,
    redirect: requireAccess(AppModule.inbox),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.messageThread,
    redirect: requireAccess(AppModule.inbox),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.campaigns,
    redirect: requireAccess(AppModule.campaign),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.campaignSms,
    redirect: requireAccess(AppModule.campaign, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.campaignEmail,
    redirect: requireAccess(AppModule.campaign, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.campaignCredits,
    redirect: requireAccess(AppModule.campaign),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.campaign,
    redirect: requireAccess(AppModule.campaign),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.notices,
    redirect: requireAccess(AppModule.notice),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.noticeNew,
    redirect: requireAccess(AppModule.notice, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.notice,
    redirect: requireAccess(AppModule.notice),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
