import 'package:salesroot/features/hr/models/payroll.dart';

abstract interface class PayrollRepository {
  /// The issued payslips, newest first. Without [employeeId] they are the
  /// signed-in employee's; with it, the payroll runs that can hold theirs.
  Future<List<PayslipRef>> payslips({String? employeeId});

  /// The payslip [ref], or [employeeId]'s slip in that payroll run; null
  /// when the run has none for them.
  Future<Payslip?> payslip(PayslipRef ref, {String? employeeId});

  Future<EmployeeCard> employeeCard({String? employeeId});

  Future<void> saveSalary(
    String employeeId,
    SalaryStructure current,
    SalaryInput input,
  );
}
