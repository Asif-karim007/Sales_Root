import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final leadsBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.leads,
      redirect: requireAccess(AppModule.lead),
      builder: (context, state) =>
          SrComingSoonScreen(title: state.matchedLocation),
    ),
  ],
);

final List<RouteBase> leadsRoutes = [
  GoRoute(
    path: Routes.leadBoard,
    redirect: requireAccess(AppModule.lead),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.leadNew,
    redirect: requireAccess(AppModule.lead, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.leadQuick,
    redirect: requireAccess(AppModule.lead, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.leadVoice,
    redirect: requireAccess(AppModule.lead, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.lead,
    redirect: requireAccess(AppModule.lead),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.leadEdit,
    redirect: requireAccess(AppModule.lead, ModuleRight.edit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.leadLinks,
    redirect: requireAccess(AppModule.lead),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.leadActivity,
    redirect: requireAccess(AppModule.lead, ModuleRight.edit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
