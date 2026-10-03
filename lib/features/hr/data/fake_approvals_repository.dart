import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/hr/data/approvals_repository.dart';
import 'package:salesroot/features/hr/data/collection_approval_fixtures.dart';
import 'package:salesroot/features/hr/data/expense_fixtures.dart';
import 'package:salesroot/features/hr/data/hr_people.dart';
import 'package:salesroot/features/hr/data/leave_fixtures.dart';
import 'package:salesroot/features/hr/models/approval.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/models/leave.dart';

/// Decides on the same leave, expense and collection rows the requesters
/// read, so a decision shows up on their screens.
class FakeApprovalsRepository implements ApprovalsRepository {
  FakeApprovalsRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _leave => _backend.table('leave', leaveFixtures);
  FakeTable get _expenses => _backend.table('expenses', expenseFixtures);
  FakeTable get _collections =>
      _backend.table('collection_approvals', collectionApprovalFixtures);

  bool get _isOwner => _backend.role == WorkspaceRole.owner;

  @override
  Future<PageResult<ApprovalItem>> list(ApprovalQuery query) => _backend.run(
    'Approvals list',
    () {
      final all = _items();
      final pending = all.where(_waitingOnMe).toList();
      final done = all
          .where((row) => row['State'] != ApprovalState.pending.wire)
          .toList();
      final rows = switch (query.filter) {
        ApprovalFilter.pending => pending,
        ApprovalFilter.done => done,
        final filter =>
          pending.where((row) => row['Kind'] == filter.wire).toList(),
      };
      return PageResult.fromJson(
        fakePage(
          rows,
          page: query.page,
          extra: {
            'Counts': {
              ApprovalFilter.pending.wire: pending.length,
              for (final kind in ApprovalKind.values)
                kind.wire: pending
                    .where((row) => row['Kind'] == kind.wire)
                    .length,
              ApprovalFilter.done.wire: done.length,
            },
          },
        ),
        ApprovalItem.fromJson,
      );
    },
    module: AppModule.approvals,
    right: ModuleRight.approve,
  );

  @override
  Future<ApprovalItem> decide(ApprovalDecision decision) => _backend.run(
    'Approval ${decision.kind.wire} ${decision.id}',
    () {
      if (!decision.approve) {
        fakeRequire(decision.toJson(), ['Reason']);
      }
      return ApprovalItem.fromJson(_apply(decision));
    },
    module: AppModule.approvals,
    right: ModuleRight.approve,
  );

  @override
  Future<int> approveAll(List<ApprovalItem> items) => _backend.run(
    'Approvals approve all',
    () {
      var approved = 0;
      for (final item in items) {
        final row = _itemFor(item.kind, item.id);
        if (row == null || !_waitingOnMe(row)) continue;
        _apply(ApprovalDecision(kind: item.kind, id: item.id, approve: true));
        approved++;
      }
      return approved;
    },
    module: AppModule.approvals,
    right: ModuleRight.approve,
  );

  Map<String, dynamic> _apply(ApprovalDecision decision) {
    final row = _itemFor(decision.kind, decision.id);
    if (row == null) throw const ApiFailure(404, 'Record not found');
    if (!_waitingOnMe(row)) {
      throw const ApiFailure(409, 'This request has already been decided.');
    }
    final me = memberOrNull(_backend.graph, _backend.meId);
    final now = jsonUtc(DateTime.now());
    final reason = decision.toJson()['Reason'];
    switch (decision.kind) {
      case ApprovalKind.leave:
        _leave.update(decision.id, {
          'StatusId': decision.approve
              ? LeaveStatusRef.approved
              : LeaveStatusRef.rejected,
          'StatusUpdatedAt': now,
          'Remarks': reason,
          ...personFields('ApproverName', me),
        });
      case ApprovalKind.expense:
        _expenses.update(decision.id, _expenseDecision(decision, reason, me));
      case ApprovalKind.collection:
        _collections.update(decision.id, {
          'Status': decision.approve
              ? ApprovalState.approved.wire
              : ApprovalState.rejected.wire,
          'DecisionNote': reason,
          ...personFields('DecidedByName', me),
        });
    }
    return _itemFor(decision.kind, decision.id) ?? row;
  }

  Map<String, dynamic> _expenseDecision(
    ApprovalDecision decision,
    Object? reason,
    SeedMember? me,
  ) {
    if (!decision.approve) {
      return {'WorkflowStatus': 'rejected', 'LastReturnNote': reason};
    }
    final row = _expenses.byId(decision.id);
    final amount = jsonDouble(row['ClaimedTotal']) ?? 0;
    final step = jsonInt(row['ApprovalStep']) ?? 1;
    final needsOwner = amount > managerApprovalAbove && step == 1;
    if (needsOwner && !_isOwner && ownerOf(_backend.graph) != null) {
      return {'ApprovalStep': 2};
    }
    return {
      'WorkflowStatus': 'approved',
      'SettlementStatus': 'unpaid',
      ...personFields('ApprovedByName', me),
    };
  }

  bool _waitingOnMe(Map<String, dynamic> item) {
    if (item['State'] != ApprovalState.pending.wire) return false;
    if (item['Kind'] != ApprovalKind.expense.wire) return true;
    final step = jsonInt((item['Expense'] as Map)['ApprovalStep']) ?? 1;
    return step == 1 || _isOwner;
  }

  Map<String, dynamic>? _itemFor(ApprovalKind kind, int id) {
    final row = switch (kind) {
      ApprovalKind.leave => _leave.byIdOrNull(id),
      ApprovalKind.expense => _expenses.byIdOrNull(id),
      ApprovalKind.collection => _collections.byIdOrNull(id),
    };
    if (row == null) return null;
    return switch (kind) {
      ApprovalKind.leave => _fromLeave(row),
      ApprovalKind.expense => _fromExpense(row),
      ApprovalKind.collection => _fromCollection(row),
    };
  }

  List<Map<String, dynamic>> _items() {
    final me = _backend.meId;
    return [
      for (final row in _leave.rows)
        if (row['EmployeeId'] != me) _fromLeave(row),
      for (final row in _expenses.rows)
        if (row['ClaimedBy'] != me && row['WorkflowStatus'] != 'withdrawn')
          _fromExpense(row),
      for (final row in _collections.rows)
        if (row['EmployeeId'] != me) _fromCollection(row),
    ]..sort((a, b) => '${b['SubmittedAt']}'.compareTo('${a['SubmittedAt']}'));
  }

  Map<String, dynamic> _fromLeave(Map<String, dynamic> row) => {
    'Kind': ApprovalKind.leave.wire,
    'Id': row['Id'],
    'EmployeeId': row['EmployeeId'],
    'EmployeeName': row['EmployeeName'],
    'EmployeeNameBn': row['EmployeeNameBn'],
    'State': switch (row['StatusId']) {
      LeaveStatusRef.approved => ApprovalState.approved.wire,
      LeaveStatusRef.rejected => ApprovalState.rejected.wire,
      _ => ApprovalState.pending.wire,
    },
    'SubmittedAt': row['AppliedAt'],
    'DecisionNote': row['Remarks'],
    'DecidedByName': row['ApproverName'],
    'DecidedByNameBn': row['ApproverNameBn'],
    'Leave': row,
  };

  Map<String, dynamic> _fromExpense(Map<String, dynamic> row) {
    final stage = ExpenseStage.fromWire(
      row['WorkflowStatus'] as String?,
      row['SettlementStatus'] as String?,
    );
    return {
      'Kind': ApprovalKind.expense.wire,
      'Id': row['Id'],
      'EmployeeId': row['ClaimedBy'],
      'EmployeeName': row['ClaimedByName'],
      'EmployeeNameBn': row['ClaimedByNameBn'],
      'State': switch (stage) {
        ExpenseStage.approved ||
        ExpenseStage.paid => ApprovalState.approved.wire,
        ExpenseStage.rejected ||
        ExpenseStage.returned => ApprovalState.rejected.wire,
        _ => ApprovalState.pending.wire,
      },
      'SubmittedAt': row['CreatedOn'],
      'DecisionNote': row['LastReturnNote'],
      'DecidedByName': row['ApprovedByName'],
      'DecidedByNameBn': row['ApprovedByNameBn'],
      'Expense': row,
    };
  }

  Map<String, dynamic> _fromCollection(Map<String, dynamic> row) => {
    'Kind': ApprovalKind.collection.wire,
    'Id': row['Id'],
    'EmployeeId': row['EmployeeId'],
    'EmployeeName': row['EmployeeName'],
    'EmployeeNameBn': row['EmployeeNameBn'],
    'State': row['Status'],
    'SubmittedAt': row['CollectedAt'],
    'DecisionNote': row['DecisionNote'],
    'DecidedByName': row['DecidedByName'],
    'DecidedByNameBn': row['DecidedByNameBn'],
    'Collection': row,
  };
}
