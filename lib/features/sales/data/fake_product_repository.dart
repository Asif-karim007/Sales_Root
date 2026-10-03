import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/data/product_repository.dart';
import 'package:salesroot/features/sales/data/sales_ledger.dart';
import 'package:salesroot/features/sales/models/product.dart';

class FakeProductRepository implements ProductRepository {
  FakeProductRepository(FakeBackend backend)
    : _backend = backend,
      _ledger = SalesLedger(backend);

  final FakeBackend _backend;
  final SalesLedger _ledger;

  @override
  Future<PageResult<Product>> list(ProductQuery query) =>
      _backend.run('Product list', () {
        final matching = _ledger.products.rows
            .where(
              (r) => fakeMatches(r, query.search, ['Name', 'NameBn', 'Code']),
            )
            .toList();
        final counts = <String, int>{'All': matching.length};
        for (final row in matching) {
          final key = '${row['Category']}';
          counts[key] = (counts[key] ?? 0) + 1;
        }
        final category = query.category;
        final rows = category == null
            ? matching
            : matching.where((r) => r['Category'] == category.wire).toList();
        return PageResult.fromJson(
          fakePage(rows, page: query.page, extra: {'CategoryCounts': counts}),
          Product.fromJson,
        );
      }, module: AppModule.product);
}
