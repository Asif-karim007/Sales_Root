import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';

abstract interface class OrderRepository {
  Future<SalesOverview> overview();

  Future<PageResult<SalesOrder>> list(OrderQuery query);

  Future<SalesOrder> get(String id);

  Future<SalesOrder> logDelivery(String id, DeliveryInput input);

  /// Bills the order's whole value.
  Future<Invoice> createInvoice(String orderId);

  Future<PageResult<Invoice>> invoices(int page);

  Future<Invoice> invoice(String id);

  /// Splits what is left on the bill into equal instalments.
  Future<Invoice> splitInvoice(String id, InstalmentPlan plan);

  Future<Invoice> cancelInvoice(String id, String reason);
}
