import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/features/hr/data/hr_repositories.dart';
import 'package:salesroot/features/hr/models/payroll.dart';

part 'payroll_providers.g.dart';

/// Issued payslips, newest first; [employeeId] null is the signed-in
/// employee.
@riverpod
Future<List<PayslipRef>> payslips(Ref ref, String? employeeId) =>
    ref.watch(payrollRepositoryProvider).payslips(employeeId: employeeId);

/// The payslip picked on the payslip screen; null follows the newest.
@riverpod
class PayslipPickNotifier extends _$PayslipPickNotifier {
  @override
  String? build(String? employeeId) => null;

  void set(String id) => state = id;
}

@riverpod
Future<Payslip?> payslip(Ref ref, String? employeeId, String id) async {
  final refs = await ref.watch(payslipsProvider(employeeId).future);
  final picked = refs.where((r) => r.id == id).firstOrNull;
  if (picked == null) return null;
  return ref
      .watch(payrollRepositoryProvider)
      .payslip(picked, employeeId: employeeId);
}

@riverpod
Future<EmployeeCard> employeeCard(Ref ref, String? employeeId) =>
    ref.watch(payrollRepositoryProvider).employeeCard(employeeId: employeeId);

/// Saving the salary structure from the card's edit sheet.
@riverpod
class SalaryEditNotifier extends _$SalaryEditNotifier {
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  Future<void> save(EmployeeCard card, SalaryInput input) async {
    final current = card.salary;
    if (state.isLoading || current == null) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(payrollRepositoryProvider)
          .saveSalary(card.employeeId, current, input);
      return true;
    });
    if (!ref.mounted) return;
    state = result;
    if (!result.hasValue) return;
    ref
      ..invalidate(employeeCardProvider)
      ..invalidate(payslipProvider);
  }
}
