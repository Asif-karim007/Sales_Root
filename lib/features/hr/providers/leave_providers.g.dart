// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(leaveRepository)
final leaveRepositoryProvider = LeaveRepositoryProvider._();

final class LeaveRepositoryProvider
    extends
        $FunctionalProvider<LeaveRepository, LeaveRepository, LeaveRepository>
    with $Provider<LeaveRepository> {
  LeaveRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaveRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaveRepositoryHash();

  @$internal
  @override
  $ProviderElement<LeaveRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LeaveRepository create(Ref ref) {
    return leaveRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeaveRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeaveRepository>(value),
    );
  }
}

String _$leaveRepositoryHash() => r'fe92142a5e0d0c4a44ff855eddf12311eee95255';

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
    extends $NotifierProvider<LeaveStatusFilterNotifier, int?> {
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
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$leaveStatusFilterNotifierHash() =>
    r'ddcd99ceb0eb15e4123ba9b7e94984a6b3bcd3b1';

/// The status chip on the leave list; null shows every request.

abstract class _$LeaveStatusFilterNotifier extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
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

String _$leaveListNotifierHash() => r'd026b910a7fa208f9d993f40b6e458e3dbcf7c04';

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
    extends $NotifierProvider<LeaveWithdrawNotifier, AsyncValue<int?>> {
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
  Override overrideWithValue(AsyncValue<int?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<int?>>(value),
    );
  }
}

String _$leaveWithdrawNotifierHash() =>
    r'c15e1306963692a86c7887700dfcc0fba06a222a';

/// Withdrawing a pending request from its detail sheet.

abstract class _$LeaveWithdrawNotifier extends $Notifier<AsyncValue<int?>> {
  AsyncValue<int?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int?>, AsyncValue<int?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int?>, AsyncValue<int?>>,
              AsyncValue<int?>,
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

String _$leaveFormNotifierHash() => r'c8f7bfbd5093e24ce17a53a073ca6b7d71a02e04';

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
