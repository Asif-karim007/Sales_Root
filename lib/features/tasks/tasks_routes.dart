import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final tasksBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.tasks,
      redirect: requireAccess(AppModule.task),
      builder: (context, state) =>
          SrComingSoonScreen(title: state.matchedLocation),
    ),
  ],
);

final List<RouteBase> tasksRoutes = [
  GoRoute(
    path: Routes.taskNew,
    redirect: requireAccess(AppModule.task, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.task,
    redirect: requireAccess(AppModule.task),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.calendar,
    redirect: requireAccess(AppModule.calendar),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.calendarEventNew,
    redirect: requireAccess(AppModule.calendar, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.scan,
    redirect: requireAccess(AppModule.cardScan, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.scanReview,
    redirect: requireAccess(AppModule.cardScan, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.scanLead,
    redirect: requireAccess(AppModule.lead, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.scanQr,
    redirect: requireAccess(AppModule.cardScan),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
