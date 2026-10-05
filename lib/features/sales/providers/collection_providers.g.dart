// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(collectionSummary)
final collectionSummaryProvider = CollectionSummaryProvider._();

final class CollectionSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CollectionSummary>,
          CollectionSummary,
          FutureOr<CollectionSummary>
        >
    with
        $FutureModifier<CollectionSummary>,
        $FutureProvider<CollectionSummary> {
  CollectionSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectionSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collectionSummaryHash();

  @$internal
  @override
  $FutureProviderElement<CollectionSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CollectionSummary> create(Ref ref) {
    return collectionSummary(ref);
  }
}

String _$collectionSummaryHash() => r'dc8054a31d7b2469858392b242e9267f3021af1a';

@ProviderFor(CollectionList)
final collectionListProvider = CollectionListProvider._();

final class CollectionListProvider
    extends $AsyncNotifierProvider<CollectionList, Paged<Collection>> {
  CollectionListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectionListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collectionListHash();

  @$internal
  @override
  CollectionList create() => CollectionList();
}

String _$collectionListHash() => r'031a20e212e96882251ffa5946e85f3e0843b1dc';

abstract class _$CollectionList extends $AsyncNotifier<Paged<Collection>> {
  FutureOr<Paged<Collection>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<Collection>>, Paged<Collection>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Collection>>, Paged<Collection>>,
              AsyncValue<Paged<Collection>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(collection)
final collectionProvider = CollectionFamily._();

final class CollectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<Collection>,
          Collection,
          FutureOr<Collection>
        >
    with $FutureModifier<Collection>, $FutureProvider<Collection> {
  CollectionProvider._({
    required CollectionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'collectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$collectionHash();

  @override
  String toString() {
    return r'collectionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Collection> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Collection> create(Ref ref) {
    final argument = this.argument as String;
    return collection(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CollectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$collectionHash() => r'8a660336a4cf9934a1990db0ccf0fbfe7ce0aa60';

final class CollectionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Collection>, String> {
  CollectionFamily._()
    : super(
        retry: null,
        name: r'collectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CollectionProvider call(String id) =>
      CollectionProvider._(argument: id, from: this);

  @override
  String toString() => r'collectionProvider';
}

@ProviderFor(outstandingSummary)
final outstandingSummaryProvider = OutstandingSummaryProvider._();

final class OutstandingSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<OutstandingSummary>,
          OutstandingSummary,
          FutureOr<OutstandingSummary>
        >
    with
        $FutureModifier<OutstandingSummary>,
        $FutureProvider<OutstandingSummary> {
  OutstandingSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outstandingSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outstandingSummaryHash();

  @$internal
  @override
  $FutureProviderElement<OutstandingSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OutstandingSummary> create(Ref ref) {
    return outstandingSummary(ref);
  }
}

String _$outstandingSummaryHash() =>
    r'3dcaf46f659a1ad9584c823953496159d94f7c84';

@ProviderFor(OutstandingFilterNotifier)
final outstandingFilterProvider = OutstandingFilterNotifierProvider._();

final class OutstandingFilterNotifierProvider
    extends $NotifierProvider<OutstandingFilterNotifier, OutstandingFilter> {
  OutstandingFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outstandingFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outstandingFilterNotifierHash();

  @$internal
  @override
  OutstandingFilterNotifier create() => OutstandingFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OutstandingFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OutstandingFilter>(value),
    );
  }
}

String _$outstandingFilterNotifierHash() =>
    r'c4c0f541aa75d881cd05cb9f3cdf6c9377243f7a';

abstract class _$OutstandingFilterNotifier
    extends $Notifier<OutstandingFilter> {
  OutstandingFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OutstandingFilter, OutstandingFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OutstandingFilter, OutstandingFilter>,
              OutstandingFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Customers with dues under [filter], most overdue first, 20 at a time.

@ProviderFor(OutstandingList)
final outstandingListProvider = OutstandingListFamily._();

/// Customers with dues under [filter], most overdue first, 20 at a time.
final class OutstandingListProvider
    extends
        $AsyncNotifierProvider<OutstandingList, Paged<CustomerOutstanding>> {
  /// Customers with dues under [filter], most overdue first, 20 at a time.
  OutstandingListProvider._({
    required OutstandingListFamily super.from,
    required OutstandingFilter super.argument,
  }) : super(
         retry: null,
         name: r'outstandingListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$outstandingListHash();

  @override
  String toString() {
    return r'outstandingListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OutstandingList create() => OutstandingList();

  @override
  bool operator ==(Object other) {
    return other is OutstandingListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$outstandingListHash() => r'f8f750f48a5666522c2cf73ea436d0b5f23613a3';

/// Customers with dues under [filter], most overdue first, 20 at a time.

final class OutstandingListFamily extends $Family
    with
        $ClassFamilyOverride<
          OutstandingList,
          AsyncValue<Paged<CustomerOutstanding>>,
          Paged<CustomerOutstanding>,
          FutureOr<Paged<CustomerOutstanding>>,
          OutstandingFilter
        > {
  OutstandingListFamily._()
    : super(
        retry: null,
        name: r'outstandingListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Customers with dues under [filter], most overdue first, 20 at a time.

  OutstandingListProvider call(OutstandingFilter filter) =>
      OutstandingListProvider._(argument: filter, from: this);

  @override
  String toString() => r'outstandingListProvider';
}

/// Customers with dues under [filter], most overdue first, 20 at a time.

abstract class _$OutstandingList
    extends $AsyncNotifier<Paged<CustomerOutstanding>> {
  late final _$args = ref.$arg as OutstandingFilter;
  OutstandingFilter get filter => _$args;

  FutureOr<Paged<CustomerOutstanding>> build(OutstandingFilter filter);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Paged<CustomerOutstanding>>,
              Paged<CustomerOutstanding>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Paged<CustomerOutstanding>>,
                Paged<CustomerOutstanding>
              >,
              AsyncValue<Paged<CustomerOutstanding>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Changes the cheque's status or cancels one receipt.

@ProviderFor(ReceiptActions)
final receiptActionsProvider = ReceiptActionsFamily._();

/// Changes the cheque's status or cancels one receipt.
final class ReceiptActionsProvider
    extends $NotifierProvider<ReceiptActions, AsyncValue<Collection?>> {
  /// Changes the cheque's status or cancels one receipt.
  ReceiptActionsProvider._({
    required ReceiptActionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'receiptActionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$receiptActionsHash();

  @override
  String toString() {
    return r'receiptActionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReceiptActions create() => ReceiptActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Collection?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Collection?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptActionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$receiptActionsHash() => r'e74e712397d615b7911f5bef830befe34f0c0fc1';

/// Changes the cheque's status or cancels one receipt.

final class ReceiptActionsFamily extends $Family
    with
        $ClassFamilyOverride<
          ReceiptActions,
          AsyncValue<Collection?>,
          AsyncValue<Collection?>,
          AsyncValue<Collection?>,
          String
        > {
  ReceiptActionsFamily._()
    : super(
        retry: null,
        name: r'receiptActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Changes the cheque's status or cancels one receipt.

  ReceiptActionsProvider call(String id) =>
      ReceiptActionsProvider._(argument: id, from: this);

  @override
  String toString() => r'receiptActionsProvider';
}

/// Changes the cheque's status or cancels one receipt.

abstract class _$ReceiptActions extends $Notifier<AsyncValue<Collection?>> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  AsyncValue<Collection?> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Collection?>, AsyncValue<Collection?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Collection?>, AsyncValue<Collection?>>,
              AsyncValue<Collection?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The record-a-collection form. Opened for a customer or a bill, it starts
/// on the oldest receivable due there.

@ProviderFor(CollectionEntry)
final collectionEntryProvider = CollectionEntryFamily._();

/// The record-a-collection form. Opened for a customer or a bill, it starts
/// on the oldest receivable due there.
final class CollectionEntryProvider
    extends $AsyncNotifierProvider<CollectionEntry, CollectionDraft> {
  /// The record-a-collection form. Opened for a customer or a bill, it starts
  /// on the oldest receivable due there.
  CollectionEntryProvider._({
    required CollectionEntryFamily super.from,
    required ({String? customerId, String? invoiceId}) super.argument,
  }) : super(
         retry: null,
         name: r'collectionEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$collectionEntryHash();

  @override
  String toString() {
    return r'collectionEntryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CollectionEntry create() => CollectionEntry();

  @override
  bool operator ==(Object other) {
    return other is CollectionEntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$collectionEntryHash() => r'a2697df82737f44c86d0ba6345f5ed771ff19899';

/// The record-a-collection form. Opened for a customer or a bill, it starts
/// on the oldest receivable due there.

final class CollectionEntryFamily extends $Family
    with
        $ClassFamilyOverride<
          CollectionEntry,
          AsyncValue<CollectionDraft>,
          CollectionDraft,
          FutureOr<CollectionDraft>,
          ({String? customerId, String? invoiceId})
        > {
  CollectionEntryFamily._()
    : super(
        retry: null,
        name: r'collectionEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The record-a-collection form. Opened for a customer or a bill, it starts
  /// on the oldest receivable due there.

  CollectionEntryProvider call({String? customerId, String? invoiceId}) =>
      CollectionEntryProvider._(
        argument: (customerId: customerId, invoiceId: invoiceId),
        from: this,
      );

  @override
  String toString() => r'collectionEntryProvider';
}

/// The record-a-collection form. Opened for a customer or a bill, it starts
/// on the oldest receivable due there.

abstract class _$CollectionEntry extends $AsyncNotifier<CollectionDraft> {
  late final _$args = ref.$arg as ({String? customerId, String? invoiceId});
  String? get customerId => _$args.customerId;
  String? get invoiceId => _$args.invoiceId;

  FutureOr<CollectionDraft> build({String? customerId, String? invoiceId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CollectionDraft>, CollectionDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CollectionDraft>, CollectionDraft>,
              AsyncValue<CollectionDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(customerId: _$args.customerId, invoiceId: _$args.invoiceId),
    );
  }
}
