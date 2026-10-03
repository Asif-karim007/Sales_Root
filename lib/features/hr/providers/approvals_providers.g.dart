// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approvals_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(approvalsRepository)
final approvalsRepositoryProvider = ApprovalsRepositoryProvider._();

final class ApprovalsRepositoryProvider
    extends
        $FunctionalProvider<
          ApprovalsRepository,
          ApprovalsRepository,
          ApprovalsRepository
        >
    with $Provider<ApprovalsRepository> {
  ApprovalsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'approvalsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$approvalsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ApprovalsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ApprovalsRepository create(Ref ref) {
    return approvalsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApprovalsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApprovalsRepository>(value),
    );
  }
}

String _$approvalsRepositoryHash() =>
    r'1aebd4e298387728b456e1021d166b8d2dd3ea64';

@ProviderFor(ApprovalFilterNotifier)
final approvalFilterProvider = ApprovalFilterNotifierProvider._();

final class ApprovalFilterNotifierProvider
    extends $NotifierProvider<ApprovalFilterNotifier, ApprovalFilter> {
  ApprovalFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'approvalFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$approvalFilterNotifierHash();

  @$internal
  @override
  ApprovalFilterNotifier create() => ApprovalFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApprovalFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApprovalFilter>(value),
    );
  }
}

String _$approvalFilterNotifierHash() =>
    r'9c33504a942c49f14e51abdd0d93ed27b31c2eac';

abstract class _$ApprovalFilterNotifier extends $Notifier<ApprovalFilter> {
  ApprovalFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ApprovalFilter, ApprovalFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ApprovalFilter, ApprovalFilter>,
              ApprovalFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ApprovalListNotifier)
final approvalListProvider = ApprovalListNotifierProvider._();

final class ApprovalListNotifierProvider
    extends $AsyncNotifierProvider<ApprovalListNotifier, Paged<ApprovalItem>> {
  ApprovalListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'approvalListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$approvalListNotifierHash();

  @$internal
  @override
  ApprovalListNotifier create() => ApprovalListNotifier();
}

String _$approvalListNotifierHash() =>
    r'f62ad82b5ec760784d57716167c8859fd084ccb0';

abstract class _$ApprovalListNotifier
    extends $AsyncNotifier<Paged<ApprovalItem>> {
  FutureOr<Paged<ApprovalItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<ApprovalItem>>, Paged<ApprovalItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<ApprovalItem>>, Paged<ApprovalItem>>,
              AsyncValue<Paged<ApprovalItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ApprovalActionsNotifier)
final approvalActionsProvider = ApprovalActionsNotifierProvider._();

final class ApprovalActionsNotifierProvider
    extends
        $NotifierProvider<
          ApprovalActionsNotifier,
          AsyncValue<ApprovalOutcome?>
        > {
  ApprovalActionsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'approvalActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$approvalActionsNotifierHash();

  @$internal
  @override
  ApprovalActionsNotifier create() => ApprovalActionsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ApprovalOutcome?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ApprovalOutcome?>>(value),
    );
  }
}

String _$approvalActionsNotifierHash() =>
    r'715b83e10e68a7e97155170a8f95258423fc5ae5';

abstract class _$ApprovalActionsNotifier
    extends $Notifier<AsyncValue<ApprovalOutcome?>> {
  AsyncValue<ApprovalOutcome?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ApprovalOutcome?>, AsyncValue<ApprovalOutcome?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ApprovalOutcome?>,
                AsyncValue<ApprovalOutcome?>
              >,
              AsyncValue<ApprovalOutcome?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
