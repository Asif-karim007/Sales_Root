// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(salesOverview)
final salesOverviewProvider = SalesOverviewProvider._();

final class SalesOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<SalesOverview>,
          SalesOverview,
          FutureOr<SalesOverview>
        >
    with $FutureModifier<SalesOverview>, $FutureProvider<SalesOverview> {
  SalesOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesOverviewHash();

  @$internal
  @override
  $FutureProviderElement<SalesOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SalesOverview> create(Ref ref) {
    return salesOverview(ref);
  }
}

String _$salesOverviewHash() => r'7abc89f33b6b3d3c28238bb197cd3fe405816bfd';

/// Orders, or only those still to deliver, 20 at a time.

@ProviderFor(OrderList)
final orderListProvider = OrderListFamily._();

/// Orders, or only those still to deliver, 20 at a time.
final class OrderListProvider
    extends $AsyncNotifierProvider<OrderList, Paged<SalesOrder>> {
  /// Orders, or only those still to deliver, 20 at a time.
  OrderListProvider._({
    required OrderListFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'orderListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderListHash();

  @override
  String toString() {
    return r'orderListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrderList create() => OrderList();

  @override
  bool operator ==(Object other) {
    return other is OrderListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderListHash() => r'5c17bfeb08a27af1160f8082b0487bacce331e16';

/// Orders, or only those still to deliver, 20 at a time.

final class OrderListFamily extends $Family
    with
        $ClassFamilyOverride<
          OrderList,
          AsyncValue<Paged<SalesOrder>>,
          Paged<SalesOrder>,
          FutureOr<Paged<SalesOrder>>,
          bool
        > {
  OrderListFamily._()
    : super(
        retry: null,
        name: r'orderListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Orders, or only those still to deliver, 20 at a time.

  OrderListProvider call({bool toDeliver = false}) =>
      OrderListProvider._(argument: toDeliver, from: this);

  @override
  String toString() => r'orderListProvider';
}

/// Orders, or only those still to deliver, 20 at a time.

abstract class _$OrderList extends $AsyncNotifier<Paged<SalesOrder>> {
  late final _$args = ref.$arg as bool;
  bool get toDeliver => _$args;

  FutureOr<Paged<SalesOrder>> build({bool toDeliver = false});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<SalesOrder>>, Paged<SalesOrder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<SalesOrder>>, Paged<SalesOrder>>,
              AsyncValue<Paged<SalesOrder>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(toDeliver: _$args));
  }
}

@ProviderFor(InvoiceList)
final invoiceListProvider = InvoiceListProvider._();

final class InvoiceListProvider
    extends $AsyncNotifierProvider<InvoiceList, Paged<Invoice>> {
  InvoiceListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceListHash();

  @$internal
  @override
  InvoiceList create() => InvoiceList();
}

String _$invoiceListHash() => r'caa5acb4f8b13690fe6aafa94fd4241a0770b82c';

abstract class _$InvoiceList extends $AsyncNotifier<Paged<Invoice>> {
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

@ProviderFor(order)
final orderProvider = OrderFamily._();

final class OrderProvider
    extends
        $FunctionalProvider<
          AsyncValue<SalesOrder>,
          SalesOrder,
          FutureOr<SalesOrder>
        >
    with $FutureModifier<SalesOrder>, $FutureProvider<SalesOrder> {
  OrderProvider._({
    required OrderFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'orderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderHash();

  @override
  String toString() {
    return r'orderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SalesOrder> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SalesOrder> create(Ref ref) {
    final argument = this.argument as int;
    return order(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderHash() => r'b32ae799077ff4257f0b14deba7c597191cee0b2';

final class OrderFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SalesOrder>, int> {
  OrderFamily._()
    : super(
        retry: null,
        name: r'orderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderProvider call(int id) => OrderProvider._(argument: id, from: this);

  @override
  String toString() => r'orderProvider';
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

String _$invoiceHash() => r'1bb07b5b345fbe02a21230e921d576dc0f9fbabc';

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

@ProviderFor(OrderActions)
final orderActionsProvider = OrderActionsFamily._();

final class OrderActionsProvider
    extends $NotifierProvider<OrderActions, AsyncValue<OrderOutcome?>> {
  OrderActionsProvider._({
    required OrderActionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'orderActionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderActionsHash();

  @override
  String toString() {
    return r'orderActionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrderActions create() => OrderActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<OrderOutcome?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<OrderOutcome?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OrderActionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderActionsHash() => r'ed6a7734f3d7d119a1bc885e30c76d945c960653';

final class OrderActionsFamily extends $Family
    with
        $ClassFamilyOverride<
          OrderActions,
          AsyncValue<OrderOutcome?>,
          AsyncValue<OrderOutcome?>,
          AsyncValue<OrderOutcome?>,
          int
        > {
  OrderActionsFamily._()
    : super(
        retry: null,
        name: r'orderActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderActionsProvider call(int id) =>
      OrderActionsProvider._(argument: id, from: this);

  @override
  String toString() => r'orderActionsProvider';
}

abstract class _$OrderActions extends $Notifier<AsyncValue<OrderOutcome?>> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  AsyncValue<OrderOutcome?> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OrderOutcome?>, AsyncValue<OrderOutcome?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OrderOutcome?>, AsyncValue<OrderOutcome?>>,
              AsyncValue<OrderOutcome?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The delivery or service completion form for one order.

@ProviderFor(DeliveryForm)
final deliveryFormProvider = DeliveryFormFamily._();

/// The delivery or service completion form for one order.
final class DeliveryFormProvider
    extends $AsyncNotifierProvider<DeliveryForm, DeliveryDraft> {
  /// The delivery or service completion form for one order.
  DeliveryFormProvider._({
    required DeliveryFormFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'deliveryFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deliveryFormHash();

  @override
  String toString() {
    return r'deliveryFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DeliveryForm create() => DeliveryForm();

  @override
  bool operator ==(Object other) {
    return other is DeliveryFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deliveryFormHash() => r'83e0352025b191b015cd7762c80b36914b662934';

/// The delivery or service completion form for one order.

final class DeliveryFormFamily extends $Family
    with
        $ClassFamilyOverride<
          DeliveryForm,
          AsyncValue<DeliveryDraft>,
          DeliveryDraft,
          FutureOr<DeliveryDraft>,
          int
        > {
  DeliveryFormFamily._()
    : super(
        retry: null,
        name: r'deliveryFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The delivery or service completion form for one order.

  DeliveryFormProvider call(int orderId) =>
      DeliveryFormProvider._(argument: orderId, from: this);

  @override
  String toString() => r'deliveryFormProvider';
}

/// The delivery or service completion form for one order.

abstract class _$DeliveryForm extends $AsyncNotifier<DeliveryDraft> {
  late final _$args = ref.$arg as int;
  int get orderId => _$args;

  FutureOr<DeliveryDraft> build(int orderId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DeliveryDraft>, DeliveryDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DeliveryDraft>, DeliveryDraft>,
              AsyncValue<DeliveryDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
