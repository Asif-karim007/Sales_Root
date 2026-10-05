import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/hr/data/api_approvals_repository.dart';
import 'package:salesroot/features/hr/data/api_expense_repository.dart';
import 'package:salesroot/features/hr/data/api_leave_repository.dart';
import 'package:salesroot/features/hr/data/api_payroll_repository.dart';
import 'package:salesroot/features/hr/data/api_ticket_repository.dart';
import 'package:salesroot/features/hr/data/approvals_repository.dart';
import 'package:salesroot/features/hr/data/expense_repository.dart';
import 'package:salesroot/features/hr/data/hr_api.dart';
import 'package:salesroot/features/hr/data/leave_repository.dart';
import 'package:salesroot/features/hr/data/payroll_repository.dart';
import 'package:salesroot/features/hr/data/ticket_repository.dart';

part 'hr_repositories.g.dart';

@Riverpod(keepAlive: true)
HrApi hrApi(Ref ref) => HrApi(ref.watch(dioProvider));

/// The API, rebuilding each repository on a workspace switch.
HrApi _api(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ref.watch(hrApiProvider);
}

/// The signed-in member in the current workspace.
String? _me(Ref ref) =>
    ref.watch(currentWorkspaceProvider.select((w) => w?.membershipId));

@Riverpod(keepAlive: true)
LeaveRepository leaveRepository(Ref ref) =>
    ApiLeaveRepository(_api(ref), membershipId: _me(ref));

@Riverpod(keepAlive: true)
ExpenseRepository expenseRepository(Ref ref) =>
    ApiExpenseRepository(_api(ref), membershipId: _me(ref));

@Riverpod(keepAlive: true)
ApprovalsRepository approvalsRepository(Ref ref) =>
    ApiApprovalsRepository(_api(ref));

@Riverpod(keepAlive: true)
PayrollRepository payrollRepository(Ref ref) =>
    ApiPayrollRepository(_api(ref), membershipId: _me(ref));

@Riverpod(keepAlive: true)
TicketRepository ticketRepository(Ref ref) => ApiTicketRepository(_api(ref));
