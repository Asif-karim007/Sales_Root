import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/product.dart';

part 'product_providers.g.dart';

/// The catalogue matching [search].
@riverpod
Future<Paged<Product>> productList(Ref ref, String search) async => Paged.first(
  await ref.watch(productRepositoryProvider).list(ProductQuery(search: search)),
);

@riverpod
class ProductSearch extends _$ProductSearch {
  @override
  String build() => '';

  void set(String search) => state = search;
}

/// Adds a product to the catalogue, or saves one; null until the first save.
@riverpod
class ProductEditor extends _$ProductEditor {
  @override
  AsyncValue<Product>? build(String? id) => null;

  Future<void> save(ProductInput input) async {
    if (state?.isLoading ?? false) return;
    state = const AsyncLoading();
    final repository = ref.read(productRepositoryProvider);
    final productId = id;
    final result = await AsyncValue.guard(
      () => productId == null
          ? repository.create(input)
          : repository.save(productId, input),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) ref.invalidate(productListProvider);
  }
}
