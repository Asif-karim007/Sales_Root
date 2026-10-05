import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/sales/view/collection_entry_screen.dart';
import 'package:salesroot/features/sales/view/collection_screen.dart';
import 'package:salesroot/features/sales/view/delivery_screen.dart';
import 'package:salesroot/features/sales/view/invoice_screen.dart';
import 'package:salesroot/features/sales/view/order_screen.dart';
import 'package:salesroot/features/sales/view/outstanding_screen.dart';
import 'package:salesroot/features/sales/view/products_screen.dart';
import 'package:salesroot/features/sales/view/quotation_screen.dart';
import 'package:salesroot/features/sales/view/quotation_wizard_screen.dart';
import 'package:salesroot/features/sales/view/quotations_screen.dart';
import 'package:salesroot/features/sales/view/receipt_screen.dart';
import 'package:salesroot/features/sales/view/sales_home_screen.dart';

final salesBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.sales,
      redirect: requireAccess(AppModule.quotation),
      builder: (context, state) => const SalesHomeScreen(),
    ),
  ],
);

String? _query(GoRouterState state, String key) {
  final value = state.uri.queryParameters[key] ?? '';
  return value.isEmpty ? null : value;
}

final List<RouteBase> salesRoutes = [
  GoRoute(
    path: Routes.products,
    redirect: requireAccess(AppModule.product),
    builder: (context, state) => const ProductsScreen(),
  ),
  GoRoute(
    path: Routes.quotations,
    redirect: requireAccess(AppModule.quotation),
    builder: (context, state) => const QuotationsScreen(),
  ),
  GoRoute(
    path: Routes.quotationNew,
    redirect: requireAccess(AppModule.quotation, ModuleRight.add),
    builder: (context, state) => QuotationWizardScreen(
      leadId: _query(state, 'leadId'),
      editId: _query(state, 'edit'),
    ),
  ),
  GoRoute(
    path: Routes.quotation,
    redirect: requireAccess(AppModule.quotation),
    builder: (context, state) => QuotationScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.order,
    redirect: requireAccess(AppModule.order),
    builder: (context, state) => OrderScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.orderDelivery,
    redirect: requireAccess(AppModule.order, ModuleRight.edit),
    builder: (context, state) => DeliveryScreen(orderId: idParam(state)),
  ),
  GoRoute(
    path: Routes.invoice,
    redirect: requireAccess(AppModule.invoice),
    builder: (context, state) => InvoiceScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.collection,
    redirect: requireAccess(AppModule.collection),
    builder: (context, state) => const CollectionScreen(),
  ),
  GoRoute(
    path: Routes.collectionNew,
    redirect: requireAccess(AppModule.collection, ModuleRight.add),
    builder: (context, state) => CollectionEntryScreen(
      customerId: _query(state, 'customerId'),
      invoiceId: _query(state, 'invoiceId'),
    ),
  ),
  GoRoute(
    path: Routes.receipt,
    redirect: requireAccess(AppModule.collection),
    builder: (context, state) => ReceiptScreen(id: idParam(state)),
  ),
  GoRoute(
    path: Routes.outstanding,
    redirect: requireAccess(AppModule.collection),
    builder: (context, state) => const OutstandingScreen(),
  ),
];
