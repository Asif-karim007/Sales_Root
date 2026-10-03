import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/hr/data/expense_fixtures.dart';
import 'package:salesroot/features/hr/data/hr_people.dart';
import 'package:salesroot/features/hr/data/leave_fixtures.dart';
import 'package:salesroot/features/hr/data/payroll_fixtures.dart';
import 'package:salesroot/features/hr/data/payroll_repository.dart';
import 'package:salesroot/features/hr/models/payroll.dart';

/// Payslips are worked out on read from the profile, won deals, approved
/// claims and approved leave, so decisions elsewhere show up in pay.
class FakePayrollRepository implements PayrollRepository {
  FakePayrollRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _salaryEdits => _backend.table('payroll_salary', (_) => []);

  @override
  Future<List<DateTime>> payslipMonths({int? employeeId}) => _backend.run(
    'Payslip months',
    () => issuedPayslipMonths(_backend.graph, _profile(employeeId)),
    module: AppModule.payroll,
    right: _rightFor(employeeId),
  );

  @override
  Future<Payslip?> payslip(DateTime month, {int? employeeId}) => _backend.run(
    'Payslip ${month.year}-${month.month}',
    () {
      final graph = _backend.graph;
      final profile = _profile(employeeId);
      final issued = issuedPayslipMonths(
        graph,
        profile,
      ).any((m) => m.year == month.year && m.month == month.month);
      if (!issued) return null;
      return Payslip.fromJson(
        payslipRow(
          graph: graph,
          profile: profile,
          leaveRows: _backend.table('leave', leaveFixtures).rows,
          expenseRows: _backend.table('expenses', expenseFixtures).rows,
          month: DateTime(month.year, month.month),
        ),
      );
    },
    module: AppModule.payroll,
    right: _rightFor(employeeId),
  );

  @override
  Future<EmployeeCard> employeeCard({int? employeeId}) => _backend.run(
    'Employee card',
    () => EmployeeCard.fromJson({
      ..._profile(employeeId),
      'CanEdit': _backend.role == WorkspaceRole.owner,
    }),
    module: AppModule.payroll,
    right: _rightFor(employeeId),
  );

  @override
  Future<EmployeeCard> saveSalary(int employeeId, SalaryInput input) =>
      _backend.run(
        'Salary save',
        () {
          final body = input.toJson();
          fakeRequire(body, ['Basic']);
          final invalid = body.entries.where((e) => (e.value as num) < 0);
          if (invalid.isNotEmpty) {
            final field = invalid.first.key;
            throw ApiFailure(
              400,
              '$field cannot be negative.',
              fieldErrors: {field: '$field cannot be negative.'},
            );
          }
          _profile(employeeId);
          final existing = _salaryEdits.byIdOrNull(employeeId);
          existing == null
              ? _salaryEdits.insert({'Id': employeeId, ...body})
              : _salaryEdits.update(employeeId, body);
          return EmployeeCard.fromJson({
            ..._profile(employeeId),
            'CanEdit': true,
          });
        },
        module: AppModule.payroll,
        right: ModuleRight.edit,
      );

  ModuleRight _rightFor(int? employeeId) =>
      employeeId == null || employeeId == _backend.meId
      ? ModuleRight.view
      : ModuleRight.edit;

  Map<String, dynamic> _profile(int? employeeId) {
    final member = memberOrNull(_backend.graph, employeeId ?? _backend.meId);
    if (member == null) throw const ApiFailure(404, 'Employee not found');
    final edits = _salaryEdits.byIdOrNull(member.id) ?? const {};
    return {
      ...payrollProfileRow(_backend.graph, member),
      for (final entry in edits.entries)
        if (entry.key != 'Id') entry.key: entry.value,
    };
  }
}
