import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/models/product.dart';

abstract interface class ProductRepository {
  /// A page of the catalogue, with a `CategoryCounts` facet.
  Future<PageResult<Product>> list(ProductQuery query);
}
