// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_repositories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(salesApi)
final salesApiProvider = SalesApiProvider._();

final class SalesApiProvider
    extends $FunctionalProvider<SalesApi, SalesApi, SalesApi>
    with $Provider<SalesApi> {
  SalesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesApiHash();

  @$internal
  @override
  $ProviderElement<SalesApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SalesApi create(Ref ref) {
    return salesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SalesApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SalesApi>(value),
    );
  }
}

String _$salesApiHash() => r'd05368beab1f6a7e6678bb9cbb72acc841df504e';

@ProviderFor(productRepository)
final productRepositoryProvider = ProductRepositoryProvider._();

final class ProductRepositoryProvider
    extends
        $FunctionalProvider<
          ProductRepository,
          ProductRepository,
          ProductRepository
        >
    with $Provider<ProductRepository> {
  ProductRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProductRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductRepository create(Ref ref) {
    return productRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductRepository>(value),
    );
  }
}

String _$productRepositoryHash() => r'eff19fdfb5b566a2ddef5ac9aa26185203e544fd';

@ProviderFor(quotationRepository)
final quotationRepositoryProvider = QuotationRepositoryProvider._();

final class QuotationRepositoryProvider
    extends
        $FunctionalProvider<
          QuotationRepository,
          QuotationRepository,
          QuotationRepository
        >
    with $Provider<QuotationRepository> {
  QuotationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quotationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quotationRepositoryHash();

  @$internal
  @override
  $ProviderElement<QuotationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  QuotationRepository create(Ref ref) {
    return quotationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuotationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuotationRepository>(value),
    );
  }
}

String _$quotationRepositoryHash() =>
    r'8ed6e9ea34b3d7310cc2466eed0a2776c434ab65';

@ProviderFor(orderRepository)
final orderRepositoryProvider = OrderRepositoryProvider._();

final class OrderRepositoryProvider
    extends
        $FunctionalProvider<OrderRepository, OrderRepository, OrderRepository>
    with $Provider<OrderRepository> {
  OrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderRepositoryHash();

  @$internal
  @override
  $ProviderElement<OrderRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrderRepository create(Ref ref) {
    return orderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderRepository>(value),
    );
  }
}

String _$orderRepositoryHash() => r'aaf64cd5f8a0c1ba04b09ce3b0277c84e492bb9a';

@ProviderFor(collectionRepository)
final collectionRepositoryProvider = CollectionRepositoryProvider._();

final class CollectionRepositoryProvider
    extends
        $FunctionalProvider<
          CollectionRepository,
          CollectionRepository,
          CollectionRepository
        >
    with $Provider<CollectionRepository> {
  CollectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<CollectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CollectionRepository create(Ref ref) {
    return collectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollectionRepository>(value),
    );
  }
}

String _$collectionRepositoryHash() =>
    r'5de6a10dad012d3576aa576bba9467882774e255';
