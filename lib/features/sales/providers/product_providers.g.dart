// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The catalogue matching [search].

@ProviderFor(productList)
final productListProvider = ProductListFamily._();

/// The catalogue matching [search].

final class ProductListProvider
    extends
        $FunctionalProvider<
          AsyncValue<Paged<Product>>,
          Paged<Product>,
          FutureOr<Paged<Product>>
        >
    with $FutureModifier<Paged<Product>>, $FutureProvider<Paged<Product>> {
  /// The catalogue matching [search].
  ProductListProvider._({
    required ProductListFamily super.from,
    required String super.argument,
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
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Paged<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Paged<Product>> create(Ref ref) {
    final argument = this.argument as String;
    return productList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productListHash() => r'f005394a2ea6fe72ff8bdafea1d4d11d06d3143b';

/// The catalogue matching [search].

final class ProductListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Paged<Product>>, String> {
  ProductListFamily._()
    : super(
        retry: null,
        name: r'productListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The catalogue matching [search].

  ProductListProvider call(String search) =>
      ProductListProvider._(argument: search, from: this);

  @override
  String toString() => r'productListProvider';
}

@ProviderFor(ProductSearch)
final productSearchProvider = ProductSearchProvider._();

final class ProductSearchProvider
    extends $NotifierProvider<ProductSearch, String> {
  ProductSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productSearchHash();

  @$internal
  @override
  ProductSearch create() => ProductSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$productSearchHash() => r'a06b7ab1429701cccf93227a65a3f6b5ed1d13f9';

abstract class _$ProductSearch extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Adds a product to the catalogue, or saves one; null until the first save.

@ProviderFor(ProductEditor)
final productEditorProvider = ProductEditorFamily._();

/// Adds a product to the catalogue, or saves one; null until the first save.
final class ProductEditorProvider
    extends $NotifierProvider<ProductEditor, AsyncValue<Product>?> {
  /// Adds a product to the catalogue, or saves one; null until the first save.
  ProductEditorProvider._({
    required ProductEditorFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'productEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productEditorHash();

  @override
  String toString() {
    return r'productEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProductEditor create() => ProductEditor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Product>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Product>?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productEditorHash() => r'1972238ac24d75c773c3c8ca82a862e67ea71b83';

/// Adds a product to the catalogue, or saves one; null until the first save.

final class ProductEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          ProductEditor,
          AsyncValue<Product>?,
          AsyncValue<Product>?,
          AsyncValue<Product>?,
          String?
        > {
  ProductEditorFamily._()
    : super(
        retry: null,
        name: r'productEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Adds a product to the catalogue, or saves one; null until the first save.

  ProductEditorProvider call(String? id) =>
      ProductEditorProvider._(argument: id, from: this);

  @override
  String toString() => r'productEditorProvider';
}

/// Adds a product to the catalogue, or saves one; null until the first save.

abstract class _$ProductEditor extends $Notifier<AsyncValue<Product>?> {
  late final _$args = ref.$arg as String?;
  String? get id => _$args;

  AsyncValue<Product>? build(String? id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Product>?, AsyncValue<Product>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Product>?, AsyncValue<Product>?>,
              AsyncValue<Product>?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
