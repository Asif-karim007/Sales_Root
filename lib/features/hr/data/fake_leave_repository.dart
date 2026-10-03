import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/hr_people.dart';
import 'package:salesroot/features/hr/data/leave_fixtures.dart';
import 'package:salesroot/features/hr/data/leave_repository.dart';
import 'package:salesroot/features/hr/models/leave.dart';

class FakeLeaveRepository implements LeaveRepository {
  FakeLeaveRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _table => _backend.table('leave', leaveFixtures);

  @override
  Future<LeaveLookups> lookups() => _backend.run('Leave lookups', () {
    final graph = _backend.graph;
    return LeaveLookups.fromJson({
      'LeaveTypes': leaveTypeRows,
      ...personFields('ApproverName', approverOf(graph, _backend.meId)),
      ...personFields('CoverName', coverOf(graph, _backend.meId)),
    });
  }, module: AppModule.leave);

  @override
  Future<List<LeaveBalance>> balances({int? employeeId}) => _backend.run(
    'Leave balances',
    () => [
      for (final row in leaveBalanceRows(
        _table.rows,
        employeeId ?? _backend.meId,
      ))
        LeaveBalance.fromJson(row),
    ],
    module: AppModule.leave,
  );

  @override
  Future<PageResult<LeaveRequest>> list(
    LeaveQuery query,
  ) => _backend.run('Leave list', () {
    final employeeId = query.employeeId ?? _backend.meId;
    final rows =
        _table.rows
            .where((row) => row['EmployeeId'] == employeeId)
            .where(
              (row) =>
                  query.statusId == null || row['StatusId'] == query.statusId,
            )
            .map(_withRights)
            .toList()
          ..sort((a, b) => '${b['StartDate']}'.compareTo('${a['StartDate']}'));
    return PageResult.fromJson(
      fakePage(rows, page: query.page),
      LeaveRequest.fromJson,
    );
  }, module: AppModule.leave);

  @override
  Future<LeaveRequest> create(LeaveInput input) => _backend.run(
    'Leave create',
    () {
      final body = input.toJson();
      fakeRequire(body, ['LeaveTypeId', 'StartDate', 'EndDate']);
      final start = jsonDate(body['StartDate']);
      final end = jsonDate(body['EndDate']);
      if (start == null || end == null || end.isBefore(start)) {
        throw const ApiFailure(
          400,
          'End date cannot be before the start date.',
          fieldErrors: {'EndDate': 'End date cannot be before the start date.'},
        );
      }
      if (input.noOfDays <= 0) {
        throw const ApiFailure(
          400,
          'NoOfDays must be greater than zero.',
          fieldErrors: {'NoOfDays': 'NoOfDays must be greater than zero.'},
        );
      }
      final me = _backend.meId;
      _checkOverlap(me, start, end);
      _checkBalance(me, input);
      final graph = _backend.graph;
      final approver = approverOf(graph, me);
      final row = leaveRow(
        graph: graph,
        id: _table.nextId(),
        employeeId: me,
        typeId: input.leaveTypeId ?? 0,
        start: start,
        end: end,
        statusId: approver == null
            ? LeaveStatusRef.approved
            : LeaveStatusRef.pending,
        appliedAt: DateTime.now(),
        reason: body['Reason'] as String?,
        attachment: input.attachmentName,
      )..['NoOfDays'] = input.noOfDays;
      if (approver == null) {
        row.addAll(personFields('ApproverName', memberOrNull(graph, me)));
      }
      return LeaveRequest.fromJson(_withRights(_table.insert(row)));
    },
    module: AppModule.leave,
    right: ModuleRight.add,
  );

  @override
  Future<void> withdraw(int id) => _backend.run('Leave withdraw', () {
    final row = _table.byId(id);
    if (row['EmployeeId'] != _backend.meId ||
        row['StatusId'] != LeaveStatusRef.pending) {
      throw const ApiFailure(409, 'Only a pending request can be withdrawn.');
    }
    _table.delete(id);
  }, module: AppModule.leave);

  void _checkOverlap(int employeeId, DateTime start, DateTime end) {
    for (final row in _table.rows) {
      if (row['EmployeeId'] != employeeId ||
          row['StatusId'] == LeaveStatusRef.rejected) {
        continue;
      }
      final from = jsonDate(row['StartDate']);
      final to = jsonDate(row['EndDate']);
      if (from == null || to == null) continue;
      if (!start.isAfter(to) && !end.isBefore(from)) {
        throw const ApiFailure(
          409,
          'You already have leave on some of these days.',
        );
      }
    }
  }

  void _checkBalance(int employeeId, LeaveInput input) {
    final type = leaveTypeRow(input.leaveTypeId ?? 0);
    if (type['IsPaid'] == false) return;
    final balance = leaveBalanceRows(
      _table.rows,
      employeeId,
    ).firstWhere((row) => row['LeaveTypeId'] == input.leaveTypeId);
    final free = jsonDouble(balance['RemainingAfterPending']) ?? 0;
    if (input.noOfDays > free) {
      throw const ApiFailure(
        400,
        'Not enough leave balance for these days.',
        fieldErrors: {'NoOfDays': 'Not enough leave balance for these days.'},
      );
    }
  }

  Map<String, dynamic> _withRights(Map<String, dynamic> row) => {
    ...row,
    'CanWithdraw':
        row['EmployeeId'] == _backend.meId &&
        row['StatusId'] == LeaveStatusRef.pending,
  };
}

/// Balances per paid leave type for [employeeId], worked out from [rows].
List<Map<String, dynamic>> leaveBalanceRows(
  List<Map<String, dynamic>> rows,
  int employeeId,
) {
  double sum(int typeId, int statusId) => rows
      .where(
        (row) =>
            row['EmployeeId'] == employeeId &&
            row['LeaveTypeId'] == typeId &&
            row['StatusId'] == statusId,
      )
      .fold(0, (total, row) => total + (jsonDouble(row['NoOfDays']) ?? 0));

  return [
    for (final type in leaveTypeRows)
      if (type['IsPaid'] != false)
        _balanceRow(
          type,
          taken: sum(type['Id'] as int, LeaveStatusRef.approved),
          pending: sum(type['Id'] as int, LeaveStatusRef.pending),
        ),
  ];
}

Map<String, dynamic> _balanceRow(
  Map<String, dynamic> type, {
  required double taken,
  required double pending,
}) {
  final entitlement = jsonDouble(type['Entitlement']) ?? 0;
  return {
    'LeaveTypeId': type['Id'],
    'LeaveType': type['Name'],
    'LeaveTypeBn': type['NameBn'],
    'Entitlement': entitlement,
    'Taken': taken,
    'Pending': pending,
    'Remaining': entitlement - taken,
    'RemainingAfterPending': entitlement - taken - pending,
  };
}
