// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(billingRepository)
final billingRepositoryProvider = BillingRepositoryProvider._();

final class BillingRepositoryProvider
    extends
        $FunctionalProvider<
          BillingRepository,
          BillingRepository,
          BillingRepository
        >
    with $Provider<BillingRepository> {
  BillingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingRepositoryHash();

  @$internal
  @override
  $ProviderElement<BillingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BillingRepository create(Ref ref) {
    return billingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingRepository>(value),
    );
  }
}

String _$billingRepositoryHash() => r'80809d26bfdc8cca73bff47c7abc6c3377261238';

@ProviderFor(billingCatalog)
final billingCatalogProvider = BillingCatalogProvider._();

final class BillingCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<BillingCatalog>,
          BillingCatalog,
          FutureOr<BillingCatalog>
        >
    with $FutureModifier<BillingCatalog>, $FutureProvider<BillingCatalog> {
  BillingCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingCatalogHash();

  @$internal
  @override
  $FutureProviderElement<BillingCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BillingCatalog> create(Ref ref) {
    return billingCatalog(ref);
  }
}

String _$billingCatalogHash() => r'51adda40ac37960ad2d4a04089cbe72e200ccf95';

@ProviderFor(subscription)
final subscriptionProvider = SubscriptionProvider._();

final class SubscriptionProvider
    extends
        $FunctionalProvider<
          AsyncValue<Subscription>,
          Subscription,
          FutureOr<Subscription>
        >
    with $FutureModifier<Subscription>, $FutureProvider<Subscription> {
  SubscriptionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionHash();

  @$internal
  @override
  $FutureProviderElement<Subscription> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Subscription> create(Ref ref) {
    return subscription(ref);
  }
}

String _$subscriptionHash() => r'f607bcb94a00d3640caec51ca7c155c861f0a915';

@ProviderFor(billingOverview)
final billingOverviewProvider = BillingOverviewProvider._();

final class BillingOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<BillingOverview>,
          BillingOverview,
          FutureOr<BillingOverview>
        >
    with $FutureModifier<BillingOverview>, $FutureProvider<BillingOverview> {
  BillingOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingOverviewHash();

  @$internal
  @override
  $FutureProviderElement<BillingOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BillingOverview> create(Ref ref) {
    return billingOverview(ref);
  }
}

String _$billingOverviewHash() => r'ac1e85f6489be969d7bff78127d162cc1deda58b';

@ProviderFor(InvoicesNotifier)
final invoicesProvider = InvoicesNotifierProvider._();

final class InvoicesNotifierProvider
    extends $AsyncNotifierProvider<InvoicesNotifier, Paged<Invoice>> {
  InvoicesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoicesNotifierHash();

  @$internal
  @override
  InvoicesNotifier create() => InvoicesNotifier();
}

String _$invoicesNotifierHash() => r'a3485e9aeeefd9a10cf91c7630f1af68c4ffe9f8';

abstract class _$InvoicesNotifier extends $AsyncNotifier<Paged<Invoice>> {
  FutureOr<Paged<Invoice>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Invoice>>, Paged<Invoice>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Invoice>>, Paged<Invoice>>,
              AsyncValue<Paged<Invoice>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(invoice)
final invoiceProvider = InvoiceFamily._();

final class InvoiceProvider
    extends $FunctionalProvider<AsyncValue<Invoice>, Invoice, FutureOr<Invoice>>
    with $FutureModifier<Invoice>, $FutureProvider<Invoice> {
  InvoiceProvider._({
    required InvoiceFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'invoiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invoiceHash();

  @override
  String toString() {
    return r'invoiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Invoice> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Invoice> create(Ref ref) {
    final argument = this.argument as int;
    return invoice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InvoiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invoiceHash() => r'52b1d4d9f6e6a26e5a00b342fc224152b7c42315';

final class InvoiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Invoice>, int> {
  InvoiceFamily._()
    : super(
        retry: null,
        name: r'invoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InvoiceProvider call(int id) => InvoiceProvider._(argument: id, from: this);

  @override
  String toString() => r'invoiceProvider';
}

@ProviderFor(checkoutData)
final checkoutDataProvider = CheckoutDataProvider._();

final class CheckoutDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<CheckoutData>,
          CheckoutData,
          FutureOr<CheckoutData>
        >
    with $FutureModifier<CheckoutData>, $FutureProvider<CheckoutData> {
  CheckoutDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkoutDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkoutDataHash();

  @$internal
  @override
  $FutureProviderElement<CheckoutData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CheckoutData> create(Ref ref) {
    return checkoutData(ref);
  }
}

String _$checkoutDataHash() => r'0edc3a9b476d87c4316bdaae066eb4ccce0eff37';

/// The payment run: review → processing → done, or failed with a retry.

@ProviderFor(CheckoutFlowNotifier)
final checkoutFlowProvider = CheckoutFlowNotifierProvider._();

/// The payment run: review → processing → done, or failed with a retry.
final class CheckoutFlowNotifierProvider
    extends $NotifierProvider<CheckoutFlowNotifier, CheckoutFlow> {
  /// The payment run: review → processing → done, or failed with a retry.
  CheckoutFlowNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkoutFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkoutFlowNotifierHash();

  @$internal
  @override
  CheckoutFlowNotifier create() => CheckoutFlowNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckoutFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckoutFlow>(value),
    );
  }
}

String _$checkoutFlowNotifierHash() =>
    r'7a129a3e89bf53f3e6ebe0a6a6a9f98248d2cd8f';

/// The payment run: review → processing → done, or failed with a retry.

abstract class _$CheckoutFlowNotifier extends $Notifier<CheckoutFlow> {
  CheckoutFlow build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CheckoutFlow, CheckoutFlow>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CheckoutFlow, CheckoutFlow>,
              CheckoutFlow,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
