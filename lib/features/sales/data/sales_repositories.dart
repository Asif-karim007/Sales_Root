import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/features/sales/data/collection_repository.dart';
import 'package:salesroot/features/sales/data/fake_collection_repository.dart';
import 'package:salesroot/features/sales/data/fake_order_repository.dart';
import 'package:salesroot/features/sales/data/fake_product_repository.dart';
import 'package:salesroot/features/sales/data/fake_quotation_repository.dart';
import 'package:salesroot/features/sales/data/order_repository.dart';
import 'package:salesroot/features/sales/data/product_repository.dart';
import 'package:salesroot/features/sales/data/quotation_repository.dart';

part 'sales_repositories.g.dart';

@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) =>
    FakeProductRepository(ref.watch(fakeBackendProvider));

@Riverpod(keepAlive: true)
QuotationRepository quotationRepository(Ref ref) =>
    FakeQuotationRepository(ref.watch(fakeBackendProvider));

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) =>
    FakeOrderRepository(ref.watch(fakeBackendProvider));

@Riverpod(keepAlive: true)
CollectionRepository collectionRepository(Ref ref) =>
    FakeCollectionRepository(ref.watch(fakeBackendProvider));
