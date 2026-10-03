// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(payrollRepository)
final payrollRepositoryProvider = PayrollRepositoryProvider._();

final class PayrollRepositoryProvider
    extends
        $FunctionalProvider<
          PayrollRepository,
          PayrollRepository,
          PayrollRepository
        >
    with $Provider<PayrollRepository> {
  PayrollRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'payrollRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$payrollRepositoryHash();

  @$internal
  @override
  $ProviderElement<PayrollRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PayrollRepository create(Ref ref) {
    return payrollRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PayrollRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PayrollRepository>(value),
    );
  }
}

String _$payrollRepositoryHash() => r'0bca44db84e4a053d22dcc01c740e5ac13bed7f5';

/// Issued months, newest first; [employeeId] null is the signed-in employee.

@ProviderFor(payslipMonths)
final payslipMonthsProvider = PayslipMonthsFamily._();

/// Issued months, newest first; [employeeId] null is the signed-in employee.

final class PayslipMonthsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DateTime>>,
          List<DateTime>,
          FutureOr<List<DateTime>>
        >
    with $FutureModifier<List<DateTime>>, $FutureProvider<List<DateTime>> {
  /// Issued months, newest first; [employeeId] null is the signed-in employee.
  PayslipMonthsProvider._({
    required PayslipMonthsFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'payslipMonthsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$payslipMonthsHash();

  @override
  String toString() {
    return r'payslipMonthsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DateTime>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DateTime>> create(Ref ref) {
    final argument = this.argument as int?;
    return payslipMonths(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PayslipMonthsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payslipMonthsHash() => r'67a32a2d06ac2c7e1e95a835e5a438ed5049ac22';

/// Issued months, newest first; [employeeId] null is the signed-in employee.

final class PayslipMonthsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DateTime>>, int?> {
  PayslipMonthsFamily._()
    : super(
        retry: null,
        name: r'payslipMonthsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Issued months, newest first; [employeeId] null is the signed-in employee.

  PayslipMonthsProvider call(int? employeeId) =>
      PayslipMonthsProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'payslipMonthsProvider';
}

/// The month picked on the payslip screen; null follows the newest issued.

@ProviderFor(PayslipMonthNotifier)
final payslipMonthProvider = PayslipMonthNotifierFamily._();

/// The month picked on the payslip screen; null follows the newest issued.
final class PayslipMonthNotifierProvider
    extends $NotifierProvider<PayslipMonthNotifier, DateTime?> {
  /// The month picked on the payslip screen; null follows the newest issued.
  PayslipMonthNotifierProvider._({
    required PayslipMonthNotifierFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'payslipMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$payslipMonthNotifierHash();

  @override
  String toString() {
    return r'payslipMonthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PayslipMonthNotifier create() => PayslipMonthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PayslipMonthNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payslipMonthNotifierHash() =>
    r'555fc234ce607e7140ef6316fb297b70dac4df9d';

/// The month picked on the payslip screen; null follows the newest issued.

final class PayslipMonthNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PayslipMonthNotifier,
          DateTime?,
          DateTime?,
          DateTime?,
          int?
        > {
  PayslipMonthNotifierFamily._()
    : super(
        retry: null,
        name: r'payslipMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The month picked on the payslip screen; null follows the newest issued.

  PayslipMonthNotifierProvider call(int? employeeId) =>
      PayslipMonthNotifierProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'payslipMonthProvider';
}

/// The month picked on the payslip screen; null follows the newest issued.

abstract class _$PayslipMonthNotifier extends $Notifier<DateTime?> {
  late final _$args = ref.$arg as int?;
  int? get employeeId => _$args;

  DateTime? build(int? employeeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(payslip)
final payslipProvider = PayslipFamily._();

final class PayslipProvider
    extends
        $FunctionalProvider<AsyncValue<Payslip?>, Payslip?, FutureOr<Payslip?>>
    with $FutureModifier<Payslip?>, $FutureProvider<Payslip?> {
  PayslipProvider._({
    required PayslipFamily super.from,
    required (int?, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'payslipProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$payslipHash();

  @override
  String toString() {
    return r'payslipProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Payslip?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Payslip?> create(Ref ref) {
    final argument = this.argument as (int?, DateTime);
    return payslip(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is PayslipProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payslipHash() => r'f56a9b4c96bab86fb3d8e518b1e1ed0c96ed8a7b';

final class PayslipFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Payslip?>, (int?, DateTime)> {
  PayslipFamily._()
    : super(
        retry: null,
        name: r'payslipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PayslipProvider call(int? employeeId, DateTime month) =>
      PayslipProvider._(argument: (employeeId, month), from: this);

  @override
  String toString() => r'payslipProvider';
}

@ProviderFor(employeeCard)
final employeeCardProvider = EmployeeCardFamily._();

final class EmployeeCardProvider
    extends
        $FunctionalProvider<
          AsyncValue<EmployeeCard>,
          EmployeeCard,
          FutureOr<EmployeeCard>
        >
    with $FutureModifier<EmployeeCard>, $FutureProvider<EmployeeCard> {
  EmployeeCardProvider._({
    required EmployeeCardFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'employeeCardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$employeeCardHash();

  @override
  String toString() {
    return r'employeeCardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<EmployeeCard> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EmployeeCard> create(Ref ref) {
    final argument = this.argument as int?;
    return employeeCard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeCardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$employeeCardHash() => r'cd8cdd7cfd748356369c899470558b2193b0bfb1';

final class EmployeeCardFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EmployeeCard>, int?> {
  EmployeeCardFamily._()
    : super(
        retry: null,
        name: r'employeeCardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmployeeCardProvider call(int? employeeId) =>
      EmployeeCardProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'employeeCardProvider';
}

/// Saving the salary structure from the card's edit sheet.

@ProviderFor(SalaryEditNotifier)
final salaryEditProvider = SalaryEditNotifierProvider._();

/// Saving the salary structure from the card's edit sheet.
final class SalaryEditNotifierProvider
    extends $NotifierProvider<SalaryEditNotifier, AsyncValue<EmployeeCard?>> {
  /// Saving the salary structure from the card's edit sheet.
  SalaryEditNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salaryEditProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salaryEditNotifierHash();

  @$internal
  @override
  SalaryEditNotifier create() => SalaryEditNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<EmployeeCard?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<EmployeeCard?>>(value),
    );
  }
}

String _$salaryEditNotifierHash() =>
    r'd8d0cccc769cedcd643840f9031f4fea874cd1ce';

/// Saving the salary structure from the card's edit sheet.

abstract class _$SalaryEditNotifier
    extends $Notifier<AsyncValue<EmployeeCard?>> {
  AsyncValue<EmployeeCard?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<EmployeeCard?>, AsyncValue<EmployeeCard?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EmployeeCard?>, AsyncValue<EmployeeCard?>>,
              AsyncValue<EmployeeCard?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
