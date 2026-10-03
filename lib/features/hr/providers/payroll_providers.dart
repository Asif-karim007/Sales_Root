import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/features/hr/data/fake_payroll_repository.dart';
import 'package:salesroot/features/hr/data/payroll_repository.dart';
import 'package:salesroot/features/hr/models/payroll.dart';

part 'payroll_providers.g.dart';

@Riverpod(keepAlive: true)
PayrollRepository payrollRepository(Ref ref) =>
    FakePayrollRepository(ref.watch(fakeBackendProvider));

/// Issued months, newest first; [employeeId] null is the signed-in employee.
@riverpod
Future<List<DateTime>> payslipMonths(Ref ref, int? employeeId) =>
    ref.watch(payrollRepositoryProvider).payslipMonths(employeeId: employeeId);

/// The month picked on the payslip screen; null follows the newest issued.
@riverpod
class PayslipMonthNotifier extends _$PayslipMonthNotifier {
  @override
  DateTime? build(int? employeeId) => null;

  void set(DateTime month) => state = month;
}

@riverpod
Future<Payslip?> payslip(Ref ref, int? employeeId, DateTime month) =>
    ref.watch(payrollRepositoryProvider).payslip(month, employeeId: employeeId);

@riverpod
Future<EmployeeCard> employeeCard(Ref ref, int? employeeId) =>
    ref.watch(payrollRepositoryProvider).employeeCard(employeeId: employeeId);

/// Saving the salary structure from the card's edit sheet.
@riverpod
class SalaryEditNotifier extends _$SalaryEditNotifier {
  @override
  AsyncValue<EmployeeCard?> build() => const AsyncData(null);

  Future<void> save(int employeeId, SalaryInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(payrollRepositoryProvider).saveSalary(employeeId, input),
    );
    if (!ref.mounted) return;
    state = result;
    if (!result.hasValue) return;
    ref
      ..invalidate(employeeCardProvider)
      ..invalidate(payslipProvider);
  }
}
