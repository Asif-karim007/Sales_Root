import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/hr/data/leave_fixtures.dart';
import 'package:salesroot/features/hr/models/approval.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/providers/approvals_providers.dart';
import 'package:salesroot/features/hr/providers/expense_providers.dart';
import 'package:salesroot/features/hr/providers/leave_providers.dart';

import 'hr_test_utils.dart';

void main() {
  Future<ApprovalItem> firstPending(
    ProviderContainer container,
    ApprovalFilter filter, [
    bool Function(ApprovalItem item)? where,
  ]) async {
    container.read(approvalFilterProvider.notifier).set(filter);
    final list = await container.read(approvalListProvider.future);
    return list.items.firstWhere(where ?? (_) => true);
  }

  test('a member has no approvals', () async {
    final container = await hrContainer();
    keep(container, approvalListProvider);

    await expectLater(
      container.read(approvalListProvider.future),
      throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
    );
  });

  test('pending counts add up by kind', () async {
    final container = await hrContainer(role: WorkspaceRole.teamLead);
    keep(container, approvalListProvider);

    final list = await container.read(approvalListProvider.future);
    final counts = list.facets[approvalCountsFacet] ?? const {};

    expect(list.items, isNotEmpty);
    expect(
      counts['Pending'],
      (counts['Leave'] ?? 0) +
          (counts['Expense'] ?? 0) +
          (counts['Collection'] ?? 0),
    );
    expect(list.items.every((i) => i.state == ApprovalState.pending), isTrue);
  });

  test('approving leave updates the requester’s list and balance', () async {
    final container = await hrContainer(role: WorkspaceRole.teamLead);
    keep(container, approvalListProvider);
    keep(container, approvalActionsProvider);
    final item = await firstPending(
      container,
      ApprovalFilter.leave,
      (i) => i.leave?.leaveTypeId == casualLeaveId,
    );
    final leave = item.leave;
    final repository = container.read(leaveRepositoryProvider);
    final requester = item.employeeId;
    final before = (await repository.balances(
      employeeId: requester,
    )).where((b) => b.leaveTypeId == leave?.leaveTypeId).firstOrNull;

    await container
        .read(approvalActionsProvider.notifier)
        .decide(ApprovalDecision(kind: item.kind, id: item.id, approve: true));

    final theirs = await repository.list(LeaveQuery(employeeId: requester));
    final updated = theirs.items.firstWhere((r) => r.id == item.id);
    expect(updated.isApproved, isTrue);
    expect(updated.approverName?.en, 'Karim Hossain');
    final after = (await repository.balances(
      employeeId: requester,
    )).where((b) => b.leaveTypeId == leave?.leaveTypeId).firstOrNull;
    expect(after?.taken, (before?.taken ?? 0) + (leave?.noOfDays ?? 0));
    expect(after?.pending, (before?.pending ?? 0) - (leave?.noOfDays ?? 0));
    final pending = await container.read(approvalListProvider.future);
    expect(pending.items.any((i) => i.key == item.key), isFalse);
  });

  test('a rejection needs a reason and reaches the claim', () async {
    final container = await hrContainer(role: WorkspaceRole.owner);
    keep(container, approvalListProvider);
    keep(container, approvalActionsProvider);
    final item = await firstPending(container, ApprovalFilter.expense);
    final actions = container.read(approvalActionsProvider.notifier);

    await actions.decide(
      ApprovalDecision(kind: item.kind, id: item.id, approve: false),
    );
    expect(
      container.read(approvalActionsProvider).error,
      isA<ApiFailure>().having((f) => f.statusCode, 'status', 400),
    );

    await actions.decide(
      ApprovalDecision(
        kind: item.kind,
        id: item.id,
        approve: false,
        reason: 'Bill missing',
      ),
    );
    final decided = container.read(approvalActionsProvider).value?.item;
    expect(decided?.state, ApprovalState.rejected);
    expect(decided?.expense?.stage, ExpenseStage.rejected);
    expect(decided?.expense?.note, 'Bill missing');
  });

  test('a team lead’s approval above the limit waits for the owner', () async {
    final container = await hrContainer(role: WorkspaceRole.teamLead);
    final repository = container.read(approvalsRepositoryProvider);
    final pending = await repository.list(
      const ApprovalQuery(filter: ApprovalFilter.expense),
    );
    final big = pending.items.firstWhere((i) => (i.expense?.cost ?? 0) > 2000);

    final after = await repository.decide(
      ApprovalDecision(kind: big.kind, id: big.id, approve: true),
    );

    expect(after.state, ApprovalState.pending);
    expect(after.expense?.approvalStep, 2);
    setRole(container, WorkspaceRole.owner);
    final owner = container.read(approvalsRepositoryProvider);
    final settled = await owner.decide(
      ApprovalDecision(kind: big.kind, id: big.id, approve: true),
    );
    expect(settled.expense?.stage, ExpenseStage.approved);
  });

  test('approve all clears the pending queue', () async {
    final container = await hrContainer(role: WorkspaceRole.owner);
    keep(container, approvalListProvider);
    keep(container, approvalActionsProvider);
    keep(container, expenseListProvider);
    final list = await container.read(approvalListProvider.future);

    await container
        .read(approvalActionsProvider.notifier)
        .approveAll(list.items);

    expect(
      container.read(approvalActionsProvider).value?.count,
      list.items.length,
    );
    final after = await container.read(approvalListProvider.future);
    expect(
      after.facets[approvalCountsFacet]?['Pending'],
      list.totalCount - list.items.length,
    );
  });
}
