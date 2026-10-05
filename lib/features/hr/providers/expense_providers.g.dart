// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The status chip on the claim list; null shows every claim.

@ProviderFor(ExpenseStageFilterNotifier)
final expenseStageFilterProvider = ExpenseStageFilterNotifierProvider._();

/// The status chip on the claim list; null shows every claim.
final class ExpenseStageFilterNotifierProvider
    extends $NotifierProvider<ExpenseStageFilterNotifier, ExpenseStage?> {
  /// The status chip on the claim list; null shows every claim.
  ExpenseStageFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseStageFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseStageFilterNotifierHash();

  @$internal
  @override
  ExpenseStageFilterNotifier create() => ExpenseStageFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpenseStage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpenseStage?>(value),
    );
  }
}

String _$expenseStageFilterNotifierHash() =>
    r'691624583535e434e57ee57f7edf1a753a80a288';

/// The status chip on the claim list; null shows every claim.

abstract class _$ExpenseStageFilterNotifier extends $Notifier<ExpenseStage?> {
  ExpenseStage? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExpenseStage?, ExpenseStage?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExpenseStage?, ExpenseStage?>,
              ExpenseStage?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ExpenseListNotifier)
final expenseListProvider = ExpenseListNotifierProvider._();

final class ExpenseListNotifierProvider
    extends $AsyncNotifierProvider<ExpenseListNotifier, Paged<ExpenseClaim>> {
  ExpenseListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseListNotifierHash();

  @$internal
  @override
  ExpenseListNotifier create() => ExpenseListNotifier();
}

String _$expenseListNotifierHash() =>
    r'5cff31a6aba9431b977214b5d45ea4a6d527becf';

abstract class _$ExpenseListNotifier
    extends $AsyncNotifier<Paged<ExpenseClaim>> {
  FutureOr<Paged<ExpenseClaim>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<ExpenseClaim>>, Paged<ExpenseClaim>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<ExpenseClaim>>, Paged<ExpenseClaim>>,
              AsyncValue<Paged<ExpenseClaim>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Withdrawing a pending claim from its detail sheet.

@ProviderFor(ExpenseWithdrawNotifier)
final expenseWithdrawProvider = ExpenseWithdrawNotifierProvider._();

/// Withdrawing a pending claim from its detail sheet.
final class ExpenseWithdrawNotifierProvider
    extends $NotifierProvider<ExpenseWithdrawNotifier, AsyncValue<String?>> {
  /// Withdrawing a pending claim from its detail sheet.
  ExpenseWithdrawNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseWithdrawProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseWithdrawNotifierHash();

  @$internal
  @override
  ExpenseWithdrawNotifier create() => ExpenseWithdrawNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<String?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<String?>>(value),
    );
  }
}

String _$expenseWithdrawNotifierHash() =>
    r'e64a5b794954fb99ce4be3e427d1cf5eb68dabc4';

/// Withdrawing a pending claim from its detail sheet.

abstract class _$ExpenseWithdrawNotifier
    extends $Notifier<AsyncValue<String?>> {
  AsyncValue<String?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, AsyncValue<String?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, AsyncValue<String?>>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The claim form. With [visitId] the visit is linked and the category
/// starts on travel.

@ProviderFor(ExpenseFormNotifier)
final expenseFormProvider = ExpenseFormNotifierFamily._();

/// The claim form. With [visitId] the visit is linked and the category
/// starts on travel.
final class ExpenseFormNotifierProvider
    extends $AsyncNotifierProvider<ExpenseFormNotifier, ExpenseFormState> {
  /// The claim form. With [visitId] the visit is linked and the category
  /// starts on travel.
  ExpenseFormNotifierProvider._({
    required ExpenseFormNotifierFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'expenseFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expenseFormNotifierHash();

  @override
  String toString() {
    return r'expenseFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ExpenseFormNotifier create() => ExpenseFormNotifier();

  @override
  bool operator ==(Object other) {
    return other is ExpenseFormNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseFormNotifierHash() =>
    r'92da7ecc740471e5162042a0e54eabca71233f3b';

/// The claim form. With [visitId] the visit is linked and the category
/// starts on travel.

final class ExpenseFormNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ExpenseFormNotifier,
          AsyncValue<ExpenseFormState>,
          ExpenseFormState,
          FutureOr<ExpenseFormState>,
          String?
        > {
  ExpenseFormNotifierFamily._()
    : super(
        retry: null,
        name: r'expenseFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The claim form. With [visitId] the visit is linked and the category
  /// starts on travel.

  ExpenseFormNotifierProvider call(String? visitId) =>
      ExpenseFormNotifierProvider._(argument: visitId, from: this);

  @override
  String toString() => r'expenseFormProvider';
}

/// The claim form. With [visitId] the visit is linked and the category
/// starts on travel.

abstract class _$ExpenseFormNotifier extends $AsyncNotifier<ExpenseFormState> {
  late final _$args = ref.$arg as String?;
  String? get visitId => _$args;

  FutureOr<ExpenseFormState> build(String? visitId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ExpenseFormState>, ExpenseFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExpenseFormState>, ExpenseFormState>,
              AsyncValue<ExpenseFormState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
