import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/hr/view/approvals_screen.dart';
import 'package:salesroot/features/hr/view/employee_card_screen.dart';
import 'package:salesroot/features/hr/view/expense_claim_screen.dart';
import 'package:salesroot/features/hr/view/expense_list_screen.dart';
import 'package:salesroot/features/hr/view/leave_request_screen.dart';
import 'package:salesroot/features/hr/view/leave_screen.dart';
import 'package:salesroot/features/hr/view/payslip_screen.dart';
import 'package:salesroot/features/hr/view/ticket_screen.dart';

final List<RouteBase> hrRoutes = [
  GoRoute(
    path: Routes.leave,
    redirect: requireAccess(AppModule.leave),
    builder: (context, state) => const LeaveScreen(),
  ),
  GoRoute(
    path: Routes.leaveNew,
    redirect: requireAccess(AppModule.leave, ModuleRight.add),
    builder: (context, state) => const LeaveRequestScreen(),
  ),
  GoRoute(
    path: Routes.expenses,
    redirect: requireAccess(AppModule.expense),
    builder: (context, state) => const ExpenseListScreen(),
  ),
  GoRoute(
    path: Routes.expenseNew,
    redirect: requireAccess(AppModule.expense, ModuleRight.add),
    builder: (context, state) =>
        ExpenseClaimScreen(visitId: _intQuery(state, 'visitId')),
  ),
  GoRoute(
    path: Routes.approvals,
    redirect: requireAccess(AppModule.approvals, ModuleRight.approve),
    builder: (context, state) => const ApprovalsScreen(),
  ),
  GoRoute(
    path: Routes.payslip,
    redirect: requireAccess(AppModule.payroll),
    builder: (context, state) =>
        PayslipScreen(employeeId: _intQuery(state, 'memberId')),
  ),
  GoRoute(
    path: Routes.ticketNew,
    redirect: requireAccess(AppModule.support, ModuleRight.add),
    builder: (context, state) => const TicketScreen(),
  ),
  GoRoute(
    path: Routes.employeeCard,
    redirect: requireAccess(AppModule.payroll),
    builder: (context, state) =>
        EmployeeCardScreen(employeeId: _intQuery(state, 'memberId')),
  ),
];

int? _intQuery(GoRouterState state, String key) =>
    int.tryParse(state.uri.queryParameters[key] ?? '');
