import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/models/product.dart';

abstract interface class ProductRepository {
  /// The active catalogue matching the query; the server sends it whole.
  Future<PageResult<Product>> list(ProductQuery query);

  Future<Product> create(ProductInput input);

  Future<Product> save(String id, ProductInput input);
}
