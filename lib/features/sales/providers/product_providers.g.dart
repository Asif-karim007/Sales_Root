// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The catalogue matching [search] in [category], 20 at a time.

@ProviderFor(ProductList)
final productListProvider = ProductListFamily._();

/// The catalogue matching [search] in [category], 20 at a time.
final class ProductListProvider
    extends $AsyncNotifierProvider<ProductList, Paged<Product>> {
  /// The catalogue matching [search] in [category], 20 at a time.
  ProductListProvider._({
    required ProductListFamily super.from,
    required (String, ProductCategory?) super.argument,
  }) : super(
         retry: null,
         name: r'productListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productListHash();

  @override
  String toString() {
    return r'productListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ProductList create() => ProductList();

  @override
  bool operator ==(Object other) {
    return other is ProductListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productListHash() => r'b50605570277a6aa732df33a9e02769101c321c1';

/// The catalogue matching [search] in [category], 20 at a time.

final class ProductListFamily extends $Family
    with
        $ClassFamilyOverride<
          ProductList,
          AsyncValue<Paged<Product>>,
          Paged<Product>,
          FutureOr<Paged<Product>>,
          (String, ProductCategory?)
        > {
  ProductListFamily._()
    : super(
        retry: null,
        name: r'productListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The catalogue matching [search] in [category], 20 at a time.

  ProductListProvider call(String search, ProductCategory? category) =>
      ProductListProvider._(argument: (search, category), from: this);

  @override
  String toString() => r'productListProvider';
}

/// The catalogue matching [search] in [category], 20 at a time.

abstract class _$ProductList extends $AsyncNotifier<Paged<Product>> {
  late final _$args = ref.$arg as (String, ProductCategory?);
  String get search => _$args.$1;
  ProductCategory? get category => _$args.$2;

  FutureOr<Paged<Product>> build(String search, ProductCategory? category);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Product>>, Paged<Product>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Product>>, Paged<Product>>,
              AsyncValue<Paged<Product>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(ProductFilterNotifier)
final productFilterProvider = ProductFilterNotifierProvider._();

final class ProductFilterNotifierProvider
    extends $NotifierProvider<ProductFilterNotifier, ProductFilter> {
  ProductFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productFilterNotifierHash();

  @$internal
  @override
  ProductFilterNotifier create() => ProductFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductFilter>(value),
    );
  }
}

String _$productFilterNotifierHash() =>
    r'dbea913dad6df1c83dd829539b02370551ba4482';

abstract class _$ProductFilterNotifier extends $Notifier<ProductFilter> {
  ProductFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProductFilter, ProductFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProductFilter, ProductFilter>,
              ProductFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
