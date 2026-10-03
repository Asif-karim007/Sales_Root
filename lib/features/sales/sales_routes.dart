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

int? _intQuery(GoRouterState state, String key) =>
    int.tryParse(state.uri.queryParameters[key] ?? '');

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
      leadId: _intQuery(state, 'leadId'),
      fromId: _intQuery(state, 'from'),
      revise: state.uri.queryParameters['mode'] == 'revise',
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
      customerId: _intQuery(state, 'customerId'),
      invoiceId: _intQuery(state, 'invoiceId'),
      orderId: _intQuery(state, 'orderId'),
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
