// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The status chip on the quotation list; null is "All".

@ProviderFor(QuotationStatusFilter)
final quotationStatusFilterProvider = QuotationStatusFilterProvider._();

/// The status chip on the quotation list; null is "All".
final class QuotationStatusFilterProvider
    extends $NotifierProvider<QuotationStatusFilter, QuotationStatus?> {
  /// The status chip on the quotation list; null is "All".
  QuotationStatusFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quotationStatusFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quotationStatusFilterHash();

  @$internal
  @override
  QuotationStatusFilter create() => QuotationStatusFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuotationStatus? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuotationStatus?>(value),
    );
  }
}

String _$quotationStatusFilterHash() =>
    r'91ce71a738366f326fc62b3307cee1c2a39ba226';

/// The status chip on the quotation list; null is "All".

abstract class _$QuotationStatusFilter extends $Notifier<QuotationStatus?> {
  QuotationStatus? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuotationStatus?, QuotationStatus?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuotationStatus?, QuotationStatus?>,
              QuotationStatus?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(QuotationList)
final quotationListProvider = QuotationListProvider._();

final class QuotationListProvider
    extends $AsyncNotifierProvider<QuotationList, Paged<Quotation>> {
  QuotationListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quotationListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quotationListHash();

  @$internal
  @override
  QuotationList create() => QuotationList();
}

String _$quotationListHash() => r'b3a3e3f6424d1250bdf33dcd24f0f842ba081bac';

abstract class _$QuotationList extends $AsyncNotifier<Paged<Quotation>> {
  FutureOr<Paged<Quotation>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<Quotation>>, Paged<Quotation>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Quotation>>, Paged<Quotation>>,
              AsyncValue<Paged<Quotation>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The newest quotations still waiting on the customer, for the sales home.

@ProviderFor(awaitingQuotations)
final awaitingQuotationsProvider = AwaitingQuotationsProvider._();

/// The newest quotations still waiting on the customer, for the sales home.

final class AwaitingQuotationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Quotation>>,
          List<Quotation>,
          FutureOr<List<Quotation>>
        >
    with $FutureModifier<List<Quotation>>, $FutureProvider<List<Quotation>> {
  /// The newest quotations still waiting on the customer, for the sales home.
  AwaitingQuotationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'awaitingQuotationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$awaitingQuotationsHash();

  @$internal
  @override
  $FutureProviderElement<List<Quotation>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Quotation>> create(Ref ref) {
    return awaitingQuotations(ref);
  }
}

String _$awaitingQuotationsHash() =>
    r'0546bccfcabb794a0477fbb3e1bc2b55c26bc687';

@ProviderFor(quotation)
final quotationProvider = QuotationFamily._();

final class QuotationProvider
    extends
        $FunctionalProvider<
          AsyncValue<Quotation>,
          Quotation,
          FutureOr<Quotation>
        >
    with $FutureModifier<Quotation>, $FutureProvider<Quotation> {
  QuotationProvider._({
    required QuotationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'quotationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quotationHash();

  @override
  String toString() {
    return r'quotationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Quotation> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Quotation> create(Ref ref) {
    final argument = this.argument as String;
    return quotation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is QuotationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quotationHash() => r'73beaa94593ace0a8619efb04e44d44ce4176481';

final class QuotationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Quotation>, String> {
  QuotationFamily._()
    : super(
        retry: null,
        name: r'quotationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  QuotationProvider call(String id) =>
      QuotationProvider._(argument: id, from: this);

  @override
  String toString() => r'quotationProvider';
}

@ProviderFor(sellerProfile)
final sellerProfileProvider = SellerProfileProvider._();

final class SellerProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<SellerProfile>,
          SellerProfile,
          FutureOr<SellerProfile>
        >
    with $FutureModifier<SellerProfile>, $FutureProvider<SellerProfile> {
  SellerProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerProfileHash();

  @$internal
  @override
  $FutureProviderElement<SellerProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SellerProfile> create(Ref ref) {
    return sellerProfile(ref);
  }
}

String _$sellerProfileHash() => r'e32a8377e3700604856a5cbf96392c83068b0981';

/// The actions on one quotation. The screen listens for the outcome to show
/// a message or move on.

@ProviderFor(QuotationActions)
final quotationActionsProvider = QuotationActionsFamily._();

/// The actions on one quotation. The screen listens for the outcome to show
/// a message or move on.
final class QuotationActionsProvider
    extends $NotifierProvider<QuotationActions, AsyncValue<QuotationOutcome?>> {
  /// The actions on one quotation. The screen listens for the outcome to show
  /// a message or move on.
  QuotationActionsProvider._({
    required QuotationActionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'quotationActionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quotationActionsHash();

  @override
  String toString() {
    return r'quotationActionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  QuotationActions create() => QuotationActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<QuotationOutcome?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<QuotationOutcome?>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QuotationActionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quotationActionsHash() => r'd980adfb8e743b649a7226aa42e8b70de8f8d789';

/// The actions on one quotation. The screen listens for the outcome to show
/// a message or move on.

final class QuotationActionsFamily extends $Family
    with
        $ClassFamilyOverride<
          QuotationActions,
          AsyncValue<QuotationOutcome?>,
          AsyncValue<QuotationOutcome?>,
          AsyncValue<QuotationOutcome?>,
          String
        > {
  QuotationActionsFamily._()
    : super(
        retry: null,
        name: r'quotationActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The actions on one quotation. The screen listens for the outcome to show
  /// a message or move on.

  QuotationActionsProvider call(String id) =>
      QuotationActionsProvider._(argument: id, from: this);

  @override
  String toString() => r'quotationActionsProvider';
}

/// The actions on one quotation. The screen listens for the outcome to show
/// a message or move on.

abstract class _$QuotationActions
    extends $Notifier<AsyncValue<QuotationOutcome?>> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  AsyncValue<QuotationOutcome?> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<QuotationOutcome?>,
              AsyncValue<QuotationOutcome?>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<QuotationOutcome?>,
                AsyncValue<QuotationOutcome?>
              >,
              AsyncValue<QuotationOutcome?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
