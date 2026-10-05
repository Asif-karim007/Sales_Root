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
    required String super.argument,
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
    final argument = this.argument as String;
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

String _$orderHash() => r'92a74ced9f71470c172d61f3db0dd6d407d7d25b';

final class OrderFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SalesOrder>, String> {
  OrderFamily._()
    : super(
        retry: null,
        name: r'orderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderProvider call(String id) => OrderProvider._(argument: id, from: this);

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

String _$invoiceHash() => r'81a7fb5428d4651ec69087bcaa9c3cad17a2f08c';

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

/// Bills one order. The screen listens for the new bill to open it.

@ProviderFor(OrderActions)
final orderActionsProvider = OrderActionsFamily._();

/// Bills one order. The screen listens for the new bill to open it.
final class OrderActionsProvider
    extends $NotifierProvider<OrderActions, AsyncValue<Invoice?>> {
  /// Bills one order. The screen listens for the new bill to open it.
  OrderActionsProvider._({
    required OrderActionsFamily super.from,
    required String super.argument,
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
  Override overrideWithValue(AsyncValue<Invoice?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Invoice?>>(value),
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

String _$orderActionsHash() => r'a3f56f4eeaa2c7438b632b936a18495b49943879';

/// Bills one order. The screen listens for the new bill to open it.

final class OrderActionsFamily extends $Family
    with
        $ClassFamilyOverride<
          OrderActions,
          AsyncValue<Invoice?>,
          AsyncValue<Invoice?>,
          AsyncValue<Invoice?>,
          String
        > {
  OrderActionsFamily._()
    : super(
        retry: null,
        name: r'orderActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Bills one order. The screen listens for the new bill to open it.

  OrderActionsProvider call(String id) =>
      OrderActionsProvider._(argument: id, from: this);

  @override
  String toString() => r'orderActionsProvider';
}

/// Bills one order. The screen listens for the new bill to open it.

abstract class _$OrderActions extends $Notifier<AsyncValue<Invoice?>> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  AsyncValue<Invoice?> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Invoice?>, AsyncValue<Invoice?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Invoice?>, AsyncValue<Invoice?>>,
              AsyncValue<Invoice?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Splits one bill into instalments or cancels it.

@ProviderFor(InvoiceActions)
final invoiceActionsProvider = InvoiceActionsFamily._();

/// Splits one bill into instalments or cancels it.
final class InvoiceActionsProvider
    extends $NotifierProvider<InvoiceActions, AsyncValue<InvoiceChange?>> {
  /// Splits one bill into instalments or cancels it.
  InvoiceActionsProvider._({
    required InvoiceActionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invoiceActionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invoiceActionsHash();

  @override
  String toString() {
    return r'invoiceActionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InvoiceActions create() => InvoiceActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<InvoiceChange?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<InvoiceChange?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InvoiceActionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invoiceActionsHash() => r'35db06094d7d2d80f9be26517a24e02000d54435';

/// Splits one bill into instalments or cancels it.

final class InvoiceActionsFamily extends $Family
    with
        $ClassFamilyOverride<
          InvoiceActions,
          AsyncValue<InvoiceChange?>,
          AsyncValue<InvoiceChange?>,
          AsyncValue<InvoiceChange?>,
          String
        > {
  InvoiceActionsFamily._()
    : super(
        retry: null,
        name: r'invoiceActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Splits one bill into instalments or cancels it.

  InvoiceActionsProvider call(String id) =>
      InvoiceActionsProvider._(argument: id, from: this);

  @override
  String toString() => r'invoiceActionsProvider';
}

/// Splits one bill into instalments or cancels it.

abstract class _$InvoiceActions extends $Notifier<AsyncValue<InvoiceChange?>> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  AsyncValue<InvoiceChange?> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<InvoiceChange?>, AsyncValue<InvoiceChange?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<InvoiceChange?>,
                AsyncValue<InvoiceChange?>
              >,
              AsyncValue<InvoiceChange?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Marks one order delivered, and bills it at once when asked.

@ProviderFor(DeliveryForm)
final deliveryFormProvider = DeliveryFormFamily._();

/// Marks one order delivered, and bills it at once when asked.
final class DeliveryFormProvider
    extends $AsyncNotifierProvider<DeliveryForm, DeliveryDraft> {
  /// Marks one order delivered, and bills it at once when asked.
  DeliveryFormProvider._({
    required DeliveryFormFamily super.from,
    required String super.argument,
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

String _$deliveryFormHash() => r'272f7913963d5f08ba120c1fb2f40024f0058fa5';

/// Marks one order delivered, and bills it at once when asked.

final class DeliveryFormFamily extends $Family
    with
        $ClassFamilyOverride<
          DeliveryForm,
          AsyncValue<DeliveryDraft>,
          DeliveryDraft,
          FutureOr<DeliveryDraft>,
          String
        > {
  DeliveryFormFamily._()
    : super(
        retry: null,
        name: r'deliveryFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Marks one order delivered, and bills it at once when asked.

  DeliveryFormProvider call(String orderId) =>
      DeliveryFormProvider._(argument: orderId, from: this);

  @override
  String toString() => r'deliveryFormProvider';
}

/// Marks one order delivered, and bills it at once when asked.

abstract class _$DeliveryForm extends $AsyncNotifier<DeliveryDraft> {
  late final _$args = ref.$arg as String;
  String get orderId => _$args;

  FutureOr<DeliveryDraft> build(String orderId);
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
