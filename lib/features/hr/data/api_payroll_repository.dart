import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/hr_api.dart';
import 'package:salesroot/features/hr/data/hr_sources.dart';
import 'package:salesroot/features/hr/data/payroll_repository.dart';
import 'package:salesroot/features/hr/models/hr_member.dart';
import 'package:salesroot/features/hr/models/payroll.dart';

class ApiPayrollRepository implements PayrollRepository {
  ApiPayrollRepository(
    this._api, {
    this.membershipId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final HrApi _api;

  /// The signed-in member.
  final String? membershipId;
  final DateTime Function() _clock;

  @override
  Future<List<PayslipRef>> payslips({String? employeeId}) async {
    final json = employeeId == null
        ? await apiRequest('My payslips', _api.myPayslips)
        : await apiRequest('Payroll runs', _api.payrollRuns);
    final refs = [for (final row in _rows(json)) ?PayslipRef.fromJson(row)]
      ..sort((a, b) => b.period.compareTo(a.period));
    return refs;
  }

  @override
  Future<Payslip?> payslip(PayslipRef ref, {String? employeeId}) async {
    if (employeeId == null) {
      final json = await apiRequest(
        'Payslip ${ref.id}',
        () => _api.payslip(ref.id),
      );
      return Payslip.fromJson(jsonMap(json), period: ref.period);
    }
    final run = jsonMap(
      await apiRequest('Payroll ${ref.id}', () => _api.payrollRun(ref.id)),
    );
    final slip = jsonList(
      run['slips'],
      (row) => row,
    ).where((row) => jsonId(row['membershipId']) == employeeId).firstOrNull;
    return slip == null ? null : Payslip.fromJson(slip, period: ref.period);
  }

  @override
  Future<EmployeeCard> employeeCard({String? employeeId}) async {
    final id = employeeId ?? membershipId;
    final [salary, members] = await Future.wait<dynamic>([
      employeeId == null
          ? apiRequest('My salary', _api.mySalary)
          : _latestSalary(employeeId),
      hrMembers(_api),
    ]);
    final team = members as List<HrMember>;
    final member = team.byId(id);
    final structure = SalaryStructure.fromJson(salary);
    return EmployeeCard(
      employeeId: id ?? '',
      name: member?.name ?? '',
      designation: structure?.designation ?? member?.designation,
      joinedOn: structure?.joinedOn ?? member?.joinedAt,
      reportsTo: team.managerOf(id)?.name,
      salary: structure,
    );
  }

  @override
  Future<void> saveSalary(
    String employeeId,
    SalaryStructure current,
    SalaryInput input,
  ) => apiRequest(
    'Salary save',
    () => _api.saveSalary(employeeId, input.toJson(current, _clock())),
  );

  /// The newest structure in [employeeId]'s salary history.
  Future<Map<String, dynamic>?> _latestSalary(String employeeId) async {
    final rows = _rows(
      await apiRequest('Salary history', () => _api.salaryHistory(employeeId)),
    );
    rows.sort(
      (a, b) => '${b['effectiveFrom'] ?? ''}'.compareTo(
        '${a['effectiveFrom'] ?? ''}',
      ),
    );
    return rows.firstOrNull;
  }

  /// A bare array, or the `items` of a page.
  static List<Map<String, dynamic>> _rows(dynamic json) => [
    ...jsonList(json is List ? json : jsonMap(json)['items'], (row) => row),
  ];
}
