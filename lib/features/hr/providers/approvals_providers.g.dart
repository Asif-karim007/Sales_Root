// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approvals_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

@ProviderFor(approvalList)
final approvalListProvider = ApprovalListProvider._();

final class ApprovalListProvider
    extends
        $FunctionalProvider<
          AsyncValue<Paged<ApprovalItem>>,
          Paged<ApprovalItem>,
          FutureOr<Paged<ApprovalItem>>
        >
    with
        $FutureModifier<Paged<ApprovalItem>>,
        $FutureProvider<Paged<ApprovalItem>> {
  ApprovalListProvider._()
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
  String debugGetCreateSourceHash() => _$approvalListHash();

  @$internal
  @override
  $FutureProviderElement<Paged<ApprovalItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Paged<ApprovalItem>> create(Ref ref) {
    return approvalList(ref);
  }
}

String _$approvalListHash() => r'e74ed2d11b0ddde5fe0b7ca21f18c3503bc54dba';

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
    r'38c56450a13066f45d7957c3f789c364340abd34';

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
