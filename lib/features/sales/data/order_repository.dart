import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';

abstract interface class OrderRepository {
  Future<SalesOverview> overview();

  Future<PageResult<SalesOrder>> list(OrderQuery query);

  Future<SalesOrder> get(int id);

  /// Replaces the payment schedule; it has to add up to the order total.
  Future<SalesOrder> updateSchedule(int id, List<Instalment> instalments);

  Future<SalesOrder> logDelivery(int id, DeliveryInput input);

  Future<Invoice> createInvoice(int orderId);

  Future<PageResult<Invoice>> invoices(int page);

  Future<Invoice> invoice(int id);
}
