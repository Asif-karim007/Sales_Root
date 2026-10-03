import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final List<RouteBase> fieldForceRoutes = [
  GoRoute(
    path: Routes.visits,
    redirect: requireAccess(AppModule.visit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.visitRoute,
    redirect: requireAccess(AppModule.visit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.visitReport,
    redirect: requireAccess(AppModule.visit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.visit,
    redirect: requireAccess(AppModule.visit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.visitCheckIn,
    redirect: requireAccess(AppModule.visit, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.trackingConsent,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.trackingHelp,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.trackingLive,
    redirect: requireAccess(AppModule.liveTracking),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.trackingSettings,
    redirect: requireAccess(AppModule.liveTracking, ModuleRight.edit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.trackingMember,
    redirect: requireAccess(AppModule.liveTracking),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.attendance,
    redirect: requireAccess(AppModule.attendance),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.attendanceCalendar,
    redirect: requireAccess(AppModule.attendance),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.attendanceTeam,
    redirect: requireAccess(AppModule.teamAttendance),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
