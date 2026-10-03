import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/field_force/view/attendance_calendar_screen.dart';
import 'package:salesroot/features/field_force/view/attendance_screen.dart';
import 'package:salesroot/features/field_force/view/check_in_screen.dart';
import 'package:salesroot/features/field_force/view/live_map_screen.dart';
import 'package:salesroot/features/field_force/view/member_day_screen.dart';
import 'package:salesroot/features/field_force/view/route_map_screen.dart';
import 'package:salesroot/features/field_force/view/team_attendance_screen.dart';
import 'package:salesroot/features/field_force/view/tracking_consent_screen.dart';
import 'package:salesroot/features/field_force/view/tracking_help_screen.dart';
import 'package:salesroot/features/field_force/view/tracking_settings_screen.dart';
import 'package:salesroot/features/field_force/view/visit_progress_screen.dart';
import 'package:salesroot/features/field_force/view/visit_report_screen.dart';
import 'package:salesroot/features/field_force/view/visits_screen.dart';

final List<RouteBase> fieldForceRoutes = [
  GoRoute(
    path: Routes.visits,
    redirect: requireAccess(AppModule.visit),
    builder: (context, state) => VisitsScreen(
      openNew: state.uri.queryParameters['new'] == '1',
      leadId: int.tryParse(state.uri.queryParameters['leadId'] ?? ''),
    ),
  ),
  GoRoute(
    path: Routes.visitRoute,
    redirect: requireAccess(AppModule.visit),
    builder: (context, state) => const RouteMapScreen(),
  ),
  GoRoute(
    path: Routes.visitReport,
    redirect: requireAccess(AppModule.visit),
    builder: (context, state) => const VisitReportScreen(),
  ),
  GoRoute(
    path: Routes.visit,
    redirect: requireAccess(AppModule.visit),
    builder: (context, state) => VisitProgressScreen(visitId: idParam(state)),
  ),
  GoRoute(
    path: Routes.visitCheckIn,
    redirect: requireAccess(AppModule.visit, ModuleRight.add),
    builder: (context, state) => CheckInScreen(visitId: idParam(state)),
  ),
  GoRoute(
    path: Routes.trackingConsent,
    builder: (context, state) => const TrackingConsentScreen(),
  ),
  GoRoute(
    path: Routes.trackingHelp,
    builder: (context, state) => const TrackingHelpScreen(),
  ),
  GoRoute(
    path: Routes.trackingLive,
    redirect: requireAccess(AppModule.liveTracking),
    builder: (context, state) => const LiveMapScreen(),
  ),
  GoRoute(
    path: Routes.trackingSettings,
    redirect: requireAccess(AppModule.liveTracking, ModuleRight.edit),
    builder: (context, state) => const TrackingSettingsScreen(),
  ),
  GoRoute(
    path: Routes.trackingMember,
    redirect: requireAccess(AppModule.liveTracking),
    builder: (context, state) => MemberDayScreen(
      memberId: idParam(state),
      date: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
    ),
  ),
  GoRoute(
    path: Routes.attendance,
    redirect: requireAccess(AppModule.attendance),
    builder: (context, state) => const AttendanceScreen(),
  ),
  GoRoute(
    path: Routes.attendanceCalendar,
    redirect: requireAccess(AppModule.attendance),
    builder: (context, state) => const AttendanceCalendarScreen(),
  ),
  GoRoute(
    path: Routes.attendanceTeam,
    redirect: requireAccess(AppModule.teamAttendance),
    builder: (context, state) => const TeamAttendanceScreen(),
  ),
];
