import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/features/sales/providers/collection_providers.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';

/// Reloads every sales list, summary and record after a change. A collection
/// moves the order, its bill, the outstanding and the home figures together,
/// so they are refreshed as one.
void refreshSales(Ref ref) {
  ref
    ..invalidate(quotationListProvider)
    ..invalidate(awaitingQuotationsProvider)
    ..invalidate(quotationProvider)
    ..invalidate(salesOverviewProvider)
    ..invalidate(orderListProvider)
    ..invalidate(orderProvider)
    ..invalidate(invoiceListProvider)
    ..invalidate(invoiceProvider)
    ..invalidate(collectionSummaryProvider)
    ..invalidate(dueListProvider)
    ..invalidate(collectionListProvider)
    ..invalidate(collectionProvider)
    ..invalidate(customerDuesProvider)
    ..invalidate(outstandingSummaryProvider)
    ..invalidate(outstandingListProvider);
}
