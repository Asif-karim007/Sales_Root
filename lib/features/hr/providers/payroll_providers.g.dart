// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Issued payslips, newest first; [employeeId] null is the signed-in
/// employee.

@ProviderFor(payslips)
final payslipsProvider = PayslipsFamily._();

/// Issued payslips, newest first; [employeeId] null is the signed-in
/// employee.

final class PayslipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PayslipRef>>,
          List<PayslipRef>,
          FutureOr<List<PayslipRef>>
        >
    with $FutureModifier<List<PayslipRef>>, $FutureProvider<List<PayslipRef>> {
  /// Issued payslips, newest first; [employeeId] null is the signed-in
  /// employee.
  PayslipsProvider._({
    required PayslipsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'payslipsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$payslipsHash();

  @override
  String toString() {
    return r'payslipsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PayslipRef>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PayslipRef>> create(Ref ref) {
    final argument = this.argument as String?;
    return payslips(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PayslipsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payslipsHash() => r'95d1d9446050bc2597293433eb6e02bea08e578f';

/// Issued payslips, newest first; [employeeId] null is the signed-in
/// employee.

final class PayslipsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PayslipRef>>, String?> {
  PayslipsFamily._()
    : super(
        retry: null,
        name: r'payslipsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Issued payslips, newest first; [employeeId] null is the signed-in
  /// employee.

  PayslipsProvider call(String? employeeId) =>
      PayslipsProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'payslipsProvider';
}

/// The payslip picked on the payslip screen; null follows the newest.

@ProviderFor(PayslipPickNotifier)
final payslipPickProvider = PayslipPickNotifierFamily._();

/// The payslip picked on the payslip screen; null follows the newest.
final class PayslipPickNotifierProvider
    extends $NotifierProvider<PayslipPickNotifier, String?> {
  /// The payslip picked on the payslip screen; null follows the newest.
  PayslipPickNotifierProvider._({
    required PayslipPickNotifierFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'payslipPickProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$payslipPickNotifierHash();

  @override
  String toString() {
    return r'payslipPickProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PayslipPickNotifier create() => PayslipPickNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PayslipPickNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payslipPickNotifierHash() =>
    r'e23b80dcfd56a7daa2ca1005b2806869921a8478';

/// The payslip picked on the payslip screen; null follows the newest.

final class PayslipPickNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PayslipPickNotifier,
          String?,
          String?,
          String?,
          String?
        > {
  PayslipPickNotifierFamily._()
    : super(
        retry: null,
        name: r'payslipPickProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The payslip picked on the payslip screen; null follows the newest.

  PayslipPickNotifierProvider call(String? employeeId) =>
      PayslipPickNotifierProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'payslipPickProvider';
}

/// The payslip picked on the payslip screen; null follows the newest.

abstract class _$PayslipPickNotifier extends $Notifier<String?> {
  late final _$args = ref.$arg as String?;
  String? get employeeId => _$args;

  String? build(String? employeeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
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
    required (String?, String) super.argument,
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
    final argument = this.argument as (String?, String);
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

String _$payslipHash() => r'afa6d734695930ecc333b64b54700f93ab9d35d4';

final class PayslipFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Payslip?>, (String?, String)> {
  PayslipFamily._()
    : super(
        retry: null,
        name: r'payslipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PayslipProvider call(String? employeeId, String id) =>
      PayslipProvider._(argument: (employeeId, id), from: this);

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
    required String? super.argument,
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
    final argument = this.argument as String?;
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

String _$employeeCardHash() => r'905016eaa71c071b106c7efb12b927512d32e0fb';

final class EmployeeCardFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EmployeeCard>, String?> {
  EmployeeCardFamily._()
    : super(
        retry: null,
        name: r'employeeCardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EmployeeCardProvider call(String? employeeId) =>
      EmployeeCardProvider._(argument: employeeId, from: this);

  @override
  String toString() => r'employeeCardProvider';
}

/// Saving the salary structure from the card's edit sheet.

@ProviderFor(SalaryEditNotifier)
final salaryEditProvider = SalaryEditNotifierProvider._();

/// Saving the salary structure from the card's edit sheet.
final class SalaryEditNotifierProvider
    extends $NotifierProvider<SalaryEditNotifier, AsyncValue<bool>> {
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
  Override overrideWithValue(AsyncValue<bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<bool>>(value),
    );
  }
}

String _$salaryEditNotifierHash() =>
    r'9bebd906ace01eb63ee2171ded94f39d55389a29';

/// Saving the salary structure from the card's edit sheet.

abstract class _$SalaryEditNotifier extends $Notifier<AsyncValue<bool>> {
  AsyncValue<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, AsyncValue<bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, AsyncValue<bool>>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
