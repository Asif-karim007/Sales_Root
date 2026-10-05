// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

@ProviderFor(invoices)
final invoicesProvider = InvoicesProvider._();

final class InvoicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Invoice>>,
          List<Invoice>,
          FutureOr<List<Invoice>>
        >
    with $FutureModifier<List<Invoice>>, $FutureProvider<List<Invoice>> {
  InvoicesProvider._()
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
  String debugGetCreateSourceHash() => _$invoicesHash();

  @$internal
  @override
  $FutureProviderElement<List<Invoice>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Invoice>> create(Ref ref) {
    return invoices(ref);
  }
}

String _$invoicesHash() => r'813feb33ec60c4d280117ebe8303203848adcae2';

@ProviderFor(invoice)
final invoiceProvider = InvoiceFamily._();

final class InvoiceProvider
    extends $FunctionalProvider<AsyncValue<Invoice>, Invoice, FutureOr<Invoice>>
    with $FutureModifier<Invoice>, $FutureProvider<Invoice> {
  InvoiceProvider._({
    required InvoiceFamily super.from,
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$invoiceHash() => r'13e5130ac836495fefb3d5c684ceabb0c56f7f08';

final class InvoiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Invoice>, String> {
  InvoiceFamily._()
    : super(
        retry: null,
        name: r'invoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InvoiceProvider call(String id) =>
      InvoiceProvider._(argument: id, from: this);

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

/// The server's price for [request] paid by [method].

@ProviderFor(checkoutQuote)
final checkoutQuoteProvider = CheckoutQuoteFamily._();

/// The server's price for [request] paid by [method].

final class CheckoutQuoteProvider
    extends $FunctionalProvider<AsyncValue<Quote>, Quote, FutureOr<Quote>>
    with $FutureModifier<Quote>, $FutureProvider<Quote> {
  /// The server's price for [request] paid by [method].
  CheckoutQuoteProvider._({
    required CheckoutQuoteFamily super.from,
    required (CheckoutRequest, PaymentKind, bool) super.argument,
  }) : super(
         retry: null,
         name: r'checkoutQuoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checkoutQuoteHash();

  @override
  String toString() {
    return r'checkoutQuoteProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Quote> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Quote> create(Ref ref) {
    final argument = this.argument as (CheckoutRequest, PaymentKind, bool);
    return checkoutQuote(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is CheckoutQuoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checkoutQuoteHash() => r'841cec6ff061a88d101e9e8ba07d94c369138854';

/// The server's price for [request] paid by [method].

final class CheckoutQuoteFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Quote>,
          (CheckoutRequest, PaymentKind, bool)
        > {
  CheckoutQuoteFamily._()
    : super(
        retry: null,
        name: r'checkoutQuoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The server's price for [request] paid by [method].

  CheckoutQuoteProvider call(
    CheckoutRequest request,
    PaymentKind method,
    bool useCredits,
  ) => CheckoutQuoteProvider._(
    argument: (request, method, useCredits),
    from: this,
  );

  @override
  String toString() => r'checkoutQuoteProvider';
}

/// The payment run: review → processing → paying at the gateway → done, or
/// failed with a retry.

@ProviderFor(CheckoutFlowNotifier)
final checkoutFlowProvider = CheckoutFlowNotifierProvider._();

/// The payment run: review → processing → paying at the gateway → done, or
/// failed with a retry.
final class CheckoutFlowNotifierProvider
    extends $NotifierProvider<CheckoutFlowNotifier, CheckoutFlow> {
  /// The payment run: review → processing → paying at the gateway → done, or
  /// failed with a retry.
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
    r'99643e3d12fc3ab247244c50a0262afbc15094d4';

/// The payment run: review → processing → paying at the gateway → done, or
/// failed with a retry.

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
