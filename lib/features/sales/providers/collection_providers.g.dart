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

@ProviderFor(DueList)
final dueListProvider = DueListProvider._();

final class DueListProvider
    extends $AsyncNotifierProvider<DueList, Paged<DueRow>> {
  DueListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dueListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dueListHash();

  @$internal
  @override
  DueList create() => DueList();
}

String _$dueListHash() => r'e1bb79f81477acf22027bf0d73c5f93947201a9a';

abstract class _$DueList extends $AsyncNotifier<Paged<DueRow>> {
  FutureOr<Paged<DueRow>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<DueRow>>, Paged<DueRow>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<DueRow>>, Paged<DueRow>>,
              AsyncValue<Paged<DueRow>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

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
    required int super.argument,
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
    final argument = this.argument as int;
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

String _$collectionHash() => r'7fb77f51029147c5fbc1aff58d0b20674997d73c';

final class CollectionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Collection>, int> {
  CollectionFamily._()
    : super(
        retry: null,
        name: r'collectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CollectionProvider call(int id) =>
      CollectionProvider._(argument: id, from: this);

  @override
  String toString() => r'collectionProvider';
}

@ProviderFor(customerDues)
final customerDuesProvider = CustomerDuesFamily._();

final class CustomerDuesProvider
    extends
        $FunctionalProvider<
          AsyncValue<CustomerDues>,
          CustomerDues,
          FutureOr<CustomerDues>
        >
    with $FutureModifier<CustomerDues>, $FutureProvider<CustomerDues> {
  CustomerDuesProvider._({
    required CustomerDuesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'customerDuesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerDuesHash();

  @override
  String toString() {
    return r'customerDuesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CustomerDues> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CustomerDues> create(Ref ref) {
    final argument = this.argument as int;
    return customerDues(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerDuesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerDuesHash() => r'316bfb325cc20f2b75a78b4f77ef6cd416838896';

final class CustomerDuesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CustomerDues>, int> {
  CustomerDuesFamily._()
    : super(
        retry: null,
        name: r'customerDuesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerDuesProvider call(int companyId) =>
      CustomerDuesProvider._(argument: companyId, from: this);

  @override
  String toString() => r'customerDuesProvider';
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

/// Customers with unpaid bills under [filter], 20 at a time.

@ProviderFor(OutstandingList)
final outstandingListProvider = OutstandingListFamily._();

/// Customers with unpaid bills under [filter], 20 at a time.
final class OutstandingListProvider
    extends
        $AsyncNotifierProvider<OutstandingList, Paged<CustomerOutstanding>> {
  /// Customers with unpaid bills under [filter], 20 at a time.
  OutstandingListProvider._({
    required OutstandingListFamily super.from,
    required (OutstandingFilter, {String search}) super.argument,
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
        '$argument';
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

String _$outstandingListHash() => r'1509b86c0083259f3703aa7f4fa4462a1b1655d3';

/// Customers with unpaid bills under [filter], 20 at a time.

final class OutstandingListFamily extends $Family
    with
        $ClassFamilyOverride<
          OutstandingList,
          AsyncValue<Paged<CustomerOutstanding>>,
          Paged<CustomerOutstanding>,
          FutureOr<Paged<CustomerOutstanding>>,
          (OutstandingFilter, {String search})
        > {
  OutstandingListFamily._()
    : super(
        retry: null,
        name: r'outstandingListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Customers with unpaid bills under [filter], 20 at a time.

  OutstandingListProvider call(
    OutstandingFilter filter, {
    String search = '',
  }) =>
      OutstandingListProvider._(argument: (filter, search: search), from: this);

  @override
  String toString() => r'outstandingListProvider';
}

/// Customers with unpaid bills under [filter], 20 at a time.

abstract class _$OutstandingList
    extends $AsyncNotifier<Paged<CustomerOutstanding>> {
  late final _$args = ref.$arg as (OutstandingFilter, {String search});
  OutstandingFilter get filter => _$args.$1;
  String get search => _$args.search;

  FutureOr<Paged<CustomerOutstanding>> build(
    OutstandingFilter filter, {
    String search = '',
  });
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
    return element.handleCreate(
      ref,
      () => build(_$args.$1, search: _$args.search),
    );
  }
}

/// The record-a-collection form. Opened for a customer, a bill or an order,
/// it starts on the oldest instalment due there.

@ProviderFor(CollectionEntry)
final collectionEntryProvider = CollectionEntryFamily._();

/// The record-a-collection form. Opened for a customer, a bill or an order,
/// it starts on the oldest instalment due there.
final class CollectionEntryProvider
    extends $AsyncNotifierProvider<CollectionEntry, CollectionDraft> {
  /// The record-a-collection form. Opened for a customer, a bill or an order,
  /// it starts on the oldest instalment due there.
  CollectionEntryProvider._({
    required CollectionEntryFamily super.from,
    required ({int? customerId, int? invoiceId, int? orderId}) super.argument,
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

String _$collectionEntryHash() => r'9ec43f571c24508a68e546d01c9253a2f2d9e559';

/// The record-a-collection form. Opened for a customer, a bill or an order,
/// it starts on the oldest instalment due there.

final class CollectionEntryFamily extends $Family
    with
        $ClassFamilyOverride<
          CollectionEntry,
          AsyncValue<CollectionDraft>,
          CollectionDraft,
          FutureOr<CollectionDraft>,
          ({int? customerId, int? invoiceId, int? orderId})
        > {
  CollectionEntryFamily._()
    : super(
        retry: null,
        name: r'collectionEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The record-a-collection form. Opened for a customer, a bill or an order,
  /// it starts on the oldest instalment due there.

  CollectionEntryProvider call({
    int? customerId,
    int? invoiceId,
    int? orderId,
  }) => CollectionEntryProvider._(
    argument: (customerId: customerId, invoiceId: invoiceId, orderId: orderId),
    from: this,
  );

  @override
  String toString() => r'collectionEntryProvider';
}

/// The record-a-collection form. Opened for a customer, a bill or an order,
/// it starts on the oldest instalment due there.

abstract class _$CollectionEntry extends $AsyncNotifier<CollectionDraft> {
  late final _$args =
      ref.$arg as ({int? customerId, int? invoiceId, int? orderId});
  int? get customerId => _$args.customerId;
  int? get invoiceId => _$args.invoiceId;
  int? get orderId => _$args.orderId;

  FutureOr<CollectionDraft> build({
    int? customerId,
    int? invoiceId,
    int? orderId,
  });
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
      () => build(
        customerId: _$args.customerId,
        invoiceId: _$args.invoiceId,
        orderId: _$args.orderId,
      ),
    );
  }
}
