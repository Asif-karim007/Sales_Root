import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final List<RouteBase> hrRoutes = [
  GoRoute(
    path: Routes.leave,
    redirect: requireAccess(AppModule.leave),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.leaveNew,
    redirect: requireAccess(AppModule.leave, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.expenses,
    redirect: requireAccess(AppModule.expense),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.expenseNew,
    redirect: requireAccess(AppModule.expense, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.approvals,
    redirect: requireAccess(AppModule.approvals),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.payslip,
    redirect: requireAccess(AppModule.payroll),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.ticketNew,
    redirect: requireAccess(AppModule.support, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.employeeCard,
    redirect: requireAccess(AppModule.payroll),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
