import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/expense_fixtures.dart';
import 'package:salesroot/features/hr/data/expense_repository.dart';
import 'package:salesroot/features/hr/data/hr_people.dart';
import 'package:salesroot/features/hr/models/expense.dart';

class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository(this._backend);

  final FakeBackend _backend;

  static const int _entryDaysLimit = 30;

  FakeTable get _table => _backend.table('expenses', expenseFixtures);

  @override
  Future<ExpenseLookups> lookups() => _backend.run('Expense lookups', () {
    final graph = _backend.graph;
    final approver = approverOf(graph, _backend.meId);
    final owner = ownerOf(graph);
    return ExpenseLookups.fromJson({
      'Types': expenseTypeRows,
      'Visits': [for (var id = 1; id <= 6; id++) expenseVisitRow(graph, id)],
      ...personFields('ApproverName', approver),
      if (approver != null && owner != null && owner.id != approver.id)
        ...personFields('ManagerName', owner),
      'Policy': {
        'ManagerApprovalAbove': managerApprovalAbove,
        'EntryDaysLimit': _entryDaysLimit,
      },
    });
  }, module: AppModule.expense);

  @override
  Future<ExpenseVisit> visit(int id) => _backend.run(
    'Expense visit $id',
    () => ExpenseVisit.fromJson(expenseVisitRow(_backend.graph, id)),
    module: AppModule.expense,
  );

  @override
  Future<PageResult<ExpenseClaim>> list(ExpenseQuery query) => _backend.run(
    'Expense list',
    () {
      final mine = _table.rows
          .where((row) => row['ClaimedBy'] == _backend.meId)
          .map(_withRights)
          .toList();
      final stage = query.stage;
      final rows =
          mine.where((row) => stage == null || _stageOf(row) == stage).toList()
            ..sort((a, b) {
              final day = '${b['IncurredFrom']}'.compareTo(
                '${a['IncurredFrom']}',
              );
              return day != 0 ? day : (b['Id'] as int) - (a['Id'] as int);
            });
      return PageResult.fromJson(
        fakePage(
          rows,
          page: query.page,
          extra: {
            'StatusCounts': {
              for (final s in ExpenseStage.values)
                s.wire: mine.where((row) => _stageOf(row) == s).length,
            },
            'StatusTotals': {
              for (final s in ExpenseStage.values)
                s.wire: mine
                    .where((row) => _stageOf(row) == s)
                    .fold<double>(
                      0,
                      (sum, row) =>
                          sum + (jsonDouble(row['ClaimedTotal']) ?? 0),
                    )
                    .round(),
            },
          },
        ),
        ExpenseClaim.fromJson,
      );
    },
    module: AppModule.expense,
  );

  @override
  Future<ExpenseClaim> create(ExpenseInput input) => _backend.run(
    'Expense create',
    () {
      final body = input.toJson();
      fakeRequire(body, [
        'Title',
        'ExpenseTypeId',
        'IncurredOn',
        'ClaimedAmount',
      ]);
      final amount = jsonDouble(body['ClaimedAmount']) ?? 0;
      if (amount <= 0) {
        throw _invalid('ClaimedAmount', 'Amount must be more than zero.');
      }
      if (input.personCount < 1) {
        throw _invalid('PersonCount', 'PersonCount must be at least 1.');
      }
      _checkDate(body['IncurredOn'] as String);
      final type = expenseTypeRows
          .where((row) => row['Id'] == input.expenseTypeId)
          .firstOrNull;
      if (type == null) {
        throw _invalid('ExpenseTypeId', 'Unknown expense type.');
      }
      final threshold = jsonDouble(type['ReceiptRequiredAbove']);
      if (threshold != null &&
          amount > threshold &&
          input.attachments.isEmpty) {
        throw _invalid('Attachments', 'A receipt is required for this amount.');
      }
      final graph = _backend.graph;
      final me = _backend.meId;
      final row = expenseRow(
        graph: graph,
        id: _table.nextId(),
        employeeId: me,
        typeId: input.expenseTypeId ?? 0,
        amount: amount,
        day: expenseDay(body['IncurredOn']) ?? DateTime.now(),
        stage: approverOf(graph, me) == null
            ? ExpenseStage.approved
            : ExpenseStage.pending,
        description: body['Description'] as String?,
        from: body['StartLocation'] as String?,
        to: body['EndLocation'] as String?,
        prospectId: input.prospectId,
        visitId: input.visitId,
        personCount: input.personCount,
        receipts: [for (final file in input.attachments) file.name],
      );
      row['Attachments'] = [
        for (final file in input.attachments) file.toJson(),
      ];
      row['CreatedOn'] = jsonUtc(DateTime.now());
      return ExpenseClaim.fromJson(_withRights(_table.insert(row)));
    },
    module: AppModule.expense,
    right: ModuleRight.add,
    quota: input.attachments.isEmpty ? null : QuotaKind.storage,
  );

  @override
  Future<ExpenseClaim> withdraw(int id) => _backend.run('Expense withdraw', () {
    final row = _table.byId(id);
    if (row['ClaimedBy'] != _backend.meId ||
        _stageOf(row) != ExpenseStage.pending) {
      throw const ApiFailure(409, 'Only a pending claim can be withdrawn.');
    }
    final updated = _table.update(id, {'WorkflowStatus': 'withdrawn'});
    return ExpenseClaim.fromJson(_withRights(updated));
  }, module: AppModule.expense);

  void _checkDate(String incurredOn) {
    final today = AppDateUtils.dateOnly(DateTime.now());
    final day = expenseDay(incurredOn);
    if (day == null) {
      throw _invalid('IncurredOn', 'IncurredOn is required');
    }
    if (day.isAfter(today)) {
      throw _invalid('IncurredOn', 'Expense date cannot be a future date.');
    }
    if (today.difference(day).inDays > _entryDaysLimit) {
      throw _invalid(
        'IncurredOn',
        'Claims older than $_entryDaysLimit days cannot be filed.',
      );
    }
  }

  static ApiFailure _invalid(String field, String message) =>
      ApiFailure(400, message, fieldErrors: {field: message});

  static ExpenseStage _stageOf(Map<String, dynamic> row) =>
      ExpenseStage.fromWire(
        row['WorkflowStatus'] as String?,
        row['SettlementStatus'] as String?,
      );

  Map<String, dynamic> _withRights(Map<String, dynamic> row) => {
    ...row,
    'CanWithdraw':
        row['ClaimedBy'] == _backend.meId &&
        _stageOf(row) == ExpenseStage.pending,
  };
}
