import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/sales/data/api_collection_repository.dart';
import 'package:salesroot/features/sales/data/api_order_repository.dart';
import 'package:salesroot/features/sales/data/api_product_repository.dart';
import 'package:salesroot/features/sales/data/api_quotation_repository.dart';
import 'package:salesroot/features/sales/data/collection_repository.dart';
import 'package:salesroot/features/sales/data/order_repository.dart';
import 'package:salesroot/features/sales/data/product_repository.dart';
import 'package:salesroot/features/sales/data/quotation_repository.dart';
import 'package:salesroot/features/sales/data/sales_api.dart';

part 'sales_repositories.g.dart';

@Riverpod(keepAlive: true)
SalesApi salesApi(Ref ref) => SalesApi(ref.watch(dioProvider));

/// The API, rebuilding each repository on a workspace switch.
SalesApi _api(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ref.watch(salesApiProvider);
}

@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) => ApiProductRepository(_api(ref));

@Riverpod(keepAlive: true)
QuotationRepository quotationRepository(Ref ref) =>
    ApiQuotationRepository(_api(ref));

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) => ApiOrderRepository(_api(ref));

@Riverpod(keepAlive: true)
CollectionRepository collectionRepository(Ref ref) =>
    ApiCollectionRepository(_api(ref));
