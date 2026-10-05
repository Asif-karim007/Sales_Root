import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/data/product_repository.dart';
import 'package:salesroot/features/sales/data/sales_api.dart';
import 'package:salesroot/features/sales/models/product.dart';

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this._api);

  final SalesApi _api;

  @override
  Future<PageResult<Product>> list(ProductQuery query) async {
    final json = await apiRequest(
      'Product list',
      () => _api.products(query.toQuery()),
    );
    return PageResult.all(jsonList(json, Product.fromJson));
  }

  @override
  Future<Product> create(ProductInput input) async => Product.fromJson(
    jsonMap(
      await apiRequest(
        'Product create',
        () => _api.createProduct(input.toJson()),
      ),
    ),
  );

  @override
  Future<Product> save(String id, ProductInput input) async => Product.fromJson(
    jsonMap(
      await apiRequest(
        'Product save',
        () => _api.editProduct(id, input.toJson()),
      ),
    ),
  );
}
