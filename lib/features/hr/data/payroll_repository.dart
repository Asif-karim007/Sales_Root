import 'package:salesroot/features/hr/models/payroll.dart';

abstract interface class PayrollRepository {
  /// The months with an issued payslip, newest first. Without
  /// [employeeId] it is the signed-in employee's.
  Future<List<DateTime>> payslipMonths({int? employeeId});

  /// Null when that month's payslip has not been issued.
  Future<Payslip?> payslip(DateTime month, {int? employeeId});

  Future<EmployeeCard> employeeCard({int? employeeId});

  Future<EmployeeCard> saveSalary(int employeeId, SalaryInput input);
}
