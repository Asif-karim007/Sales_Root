// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(leaveBalances)
final leaveBalancesProvider = LeaveBalancesProvider._();

final class LeaveBalancesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LeaveBalance>>,
          List<LeaveBalance>,
          FutureOr<List<LeaveBalance>>
        >
    with
        $FutureModifier<List<LeaveBalance>>,
        $FutureProvider<List<LeaveBalance>> {
  LeaveBalancesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaveBalancesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaveBalancesHash();

  @$internal
  @override
  $FutureProviderElement<List<LeaveBalance>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LeaveBalance>> create(Ref ref) {
    return leaveBalances(ref);
  }
}

String _$leaveBalancesHash() => r'aa52b72a3b9d546364d86f4bf951bf29fcff7d31';

/// The status chip on the leave list; null shows every request.

@ProviderFor(LeaveStatusFilterNotifier)
final leaveStatusFilterProvider = LeaveStatusFilterNotifierProvider._();

/// The status chip on the leave list; null shows every request.
final class LeaveStatusFilterNotifierProvider
    extends $NotifierProvider<LeaveStatusFilterNotifier, LeaveStatus?> {
  /// The status chip on the leave list; null shows every request.
  LeaveStatusFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaveStatusFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaveStatusFilterNotifierHash();

  @$internal
  @override
  LeaveStatusFilterNotifier create() => LeaveStatusFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeaveStatus? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeaveStatus?>(value),
    );
  }
}

String _$leaveStatusFilterNotifierHash() =>
    r'6ff5efa63165c9155bc2722fa503479a216beb8b';

/// The status chip on the leave list; null shows every request.

abstract class _$LeaveStatusFilterNotifier extends $Notifier<LeaveStatus?> {
  LeaveStatus? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LeaveStatus?, LeaveStatus?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeaveStatus?, LeaveStatus?>,
              LeaveStatus?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LeaveListNotifier)
final leaveListProvider = LeaveListNotifierProvider._();

final class LeaveListNotifierProvider
    extends $AsyncNotifierProvider<LeaveListNotifier, Paged<LeaveRequest>> {
  LeaveListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaveListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaveListNotifierHash();

  @$internal
  @override
  LeaveListNotifier create() => LeaveListNotifier();
}

String _$leaveListNotifierHash() => r'b98d955c964acac83ed577b0ad701c03c0b74d75';

abstract class _$LeaveListNotifier extends $AsyncNotifier<Paged<LeaveRequest>> {
  FutureOr<Paged<LeaveRequest>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<LeaveRequest>>, Paged<LeaveRequest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<LeaveRequest>>, Paged<LeaveRequest>>,
              AsyncValue<Paged<LeaveRequest>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Withdrawing a pending request from its detail sheet.

@ProviderFor(LeaveWithdrawNotifier)
final leaveWithdrawProvider = LeaveWithdrawNotifierProvider._();

/// Withdrawing a pending request from its detail sheet.
final class LeaveWithdrawNotifierProvider
    extends $NotifierProvider<LeaveWithdrawNotifier, AsyncValue<String?>> {
  /// Withdrawing a pending request from its detail sheet.
  LeaveWithdrawNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaveWithdrawProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaveWithdrawNotifierHash();

  @$internal
  @override
  LeaveWithdrawNotifier create() => LeaveWithdrawNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<String?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<String?>>(value),
    );
  }
}

String _$leaveWithdrawNotifierHash() =>
    r'39682d755ee8db13a94dc3ddfed3c210f9d3fd51';

/// Withdrawing a pending request from its detail sheet.

abstract class _$LeaveWithdrawNotifier extends $Notifier<AsyncValue<String?>> {
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

@ProviderFor(LeaveFormNotifier)
final leaveFormProvider = LeaveFormNotifierProvider._();

final class LeaveFormNotifierProvider
    extends $AsyncNotifierProvider<LeaveFormNotifier, LeaveFormState> {
  LeaveFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaveFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaveFormNotifierHash();

  @$internal
  @override
  LeaveFormNotifier create() => LeaveFormNotifier();
}

String _$leaveFormNotifierHash() => r'28b0a0f50fc0c8d032a3da5a32935c2c02198255';

abstract class _$LeaveFormNotifier extends $AsyncNotifier<LeaveFormState> {
  FutureOr<LeaveFormState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LeaveFormState>, LeaveFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LeaveFormState>, LeaveFormState>,
              AsyncValue<LeaveFormState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
