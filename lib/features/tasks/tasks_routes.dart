import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/tasks/view/calendar_screen.dart';
import 'package:salesroot/features/tasks/view/private_event_screen.dart';
import 'package:salesroot/features/tasks/view/qr_result_screen.dart';
import 'package:salesroot/features/tasks/view/scan_capture_screen.dart';
import 'package:salesroot/features/tasks/view/scan_lead_screen.dart';
import 'package:salesroot/features/tasks/view/scan_review_screen.dart';
import 'package:salesroot/features/tasks/view/task_detail_screen.dart';
import 'package:salesroot/features/tasks/view/task_form_screen.dart';
import 'package:salesroot/features/tasks/view/tasks_screen.dart';

final tasksBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.tasks,
      redirect: requireAccess(AppModule.task),
      builder: (context, state) => const TasksScreen(),
    ),
  ],
);

final List<RouteBase> tasksRoutes = [
  GoRoute(
    path: Routes.taskNew,
    redirect: requireAccess(AppModule.task, ModuleRight.add),
    builder: (context, state) => TaskFormScreen(
      leadId: _intQuery(state, 'leadId'),
      title: state.uri.queryParameters['title'],
      day: _dateQuery(state),
    ),
  ),
  GoRoute(
    path: Routes.task,
    redirect: requireAccess(AppModule.task),
    builder: (context, state) => TaskDetailScreen(id: idParam(state)),
    routes: [
      GoRoute(
        path: 'edit',
        redirect: requireAccess(AppModule.task, ModuleRight.edit),
        builder: (context, state) => TaskFormScreen(taskId: idParam(state)),
      ),
    ],
  ),
  GoRoute(
    path: Routes.calendar,
    redirect: requireAccess(AppModule.calendar),
    builder: (context, state) => const CalendarScreen(),
  ),
  GoRoute(
    path: Routes.calendarEventNew,
    redirect: requireAccess(AppModule.calendar, ModuleRight.add),
    builder: (context, state) => PrivateEventScreen(
      eventId: _intQuery(state, 'id'),
      day: _dateQuery(state),
    ),
  ),
  GoRoute(
    path: Routes.scan,
    redirect: requireAccess(AppModule.cardScan, ModuleRight.add),
    builder: (context, state) => const ScanCaptureScreen(),
  ),
  GoRoute(
    path: Routes.scanReview,
    redirect: requireAccess(AppModule.cardScan, ModuleRight.add),
    builder: (context, state) => const ScanReviewScreen(),
  ),
  GoRoute(
    path: Routes.scanLead,
    redirect: requireAccess(AppModule.lead, ModuleRight.add),
    builder: (context, state) => const ScanLeadScreen(),
  ),
  GoRoute(
    path: Routes.scanQr,
    redirect: requireAccess(AppModule.cardScan),
    builder: (context, state) => const QrResultScreen(),
  ),
];

int? _intQuery(GoRouterState state, String key) =>
    int.tryParse(state.uri.queryParameters[key] ?? '');

DateTime? _dateQuery(GoRouterState state) =>
    DateTime.tryParse(state.uri.queryParameters['date'] ?? '');
