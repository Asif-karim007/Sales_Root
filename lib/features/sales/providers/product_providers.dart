import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/providers/paging.dart';

part 'product_providers.g.dart';

/// The catalogue matching [search] in [category], 20 at a time.
@riverpod
class ProductList extends _$ProductList {
  @override
  Future<Paged<Product>> build(String search, ProductCategory? category) async {
    final result = await ref
        .watch(productRepositoryProvider)
        .list(ProductQuery(search: search, category: category));
    return Paged.first(result, facetKeys: const ['CategoryCounts']);
  }

  Future<void> loadMore() => loadNextPage(
    current: state.value,
    fetch: (page) => ref
        .read(productRepositoryProvider)
        .list(ProductQuery(search: search, category: category, page: page)),
    mounted: () => ref.mounted,
    emit: (next) => state = AsyncData(next),
  );
}

class ProductFilter {
  const ProductFilter({
    this.search = '',
    this.category,
    this.priceList = PriceList.list,
  });

  final String search;
  final ProductCategory? category;
  final PriceList priceList;
}

@riverpod
class ProductFilterNotifier extends _$ProductFilterNotifier {
  @override
  ProductFilter build() => const ProductFilter();

  void setSearch(String search) => state = ProductFilter(
    search: search,
    category: state.category,
    priceList: state.priceList,
  );

  void setCategory(ProductCategory? category) => state = ProductFilter(
    search: state.search,
    category: category,
    priceList: state.priceList,
  );

  void togglePriceList() => state = ProductFilter(
    search: state.search,
    category: state.category,
    priceList: state.priceList == PriceList.list
        ? PriceList.dealer
        : PriceList.list,
  );
}
