import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/data/order_repository.dart';
import 'package:salesroot/features/sales/data/sales_api.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SalesApi _api;
  final DateTime Function() _clock;

  @override
  Future<SalesOverview> overview() async {
    final [month, lastMonth, quotes, orders, dues] = await Future.wait([
      apiRequest(
        'Sales this month',
        () => _api.salesReport({'preset': 'this_month'}),
      ),
      apiRequest(
        'Sales last month',
        () => _api.salesReport({'preset': 'last_month'}),
      ),
      apiRequest(
        'Quotations awaiting',
        () => _api.quotes(
          const QuotationQuery(status: QuotationStatus.sent, size: 1).toQuery(),
        ),
      ),
      apiRequest(
        'Orders to deliver',
        () => _api.orders({
          'status': OrderStatus.confirmed.wire,
          ...pageQuery(1, size: 1),
        }),
      ),
      apiRequest('Dues summary', _api.duesSummary),
    ]);
    double booked(dynamic report) =>
        jsonDouble(jsonMap(jsonMap(report)['summary'])['orderAmount']) ?? 0;
    int total(dynamic page) => jsonInt(jsonMap(page)['total']) ?? 0;
    return SalesOverview(
      salesThisMonth: booked(month),
      salesLastMonth: booked(lastMonth),
      openQuotations: total(quotes),
      ordersToDeliver: total(orders),
      receivable: jsonDouble(jsonMap(dues)['total']) ?? 0,
    );
  }

  @override
  Future<PageResult<SalesOrder>> list(OrderQuery query) async {
    final json = await apiRequest(
      'Order list',
      () => _api.orders(query.toQuery()),
    );
    return PageResult.fromJson(jsonMap(json), SalesOrder.fromJson);
  }

  @override
  Future<SalesOrder> get(String id) async => SalesOrder.fromDetail(
    jsonMap(await apiRequest('Order $id', () => _api.order(id))),
  );

  @override
  Future<SalesOrder> logDelivery(String id, DeliveryInput input) async =>
      SalesOrder.fromDetail(
        jsonMap(
          await apiRequest(
            'Order delivered',
            () => _api.editOrder(id, input.toJson()),
          ),
        ),
      );

  @override
  Future<Invoice> createInvoice(String orderId) async {
    final json = jsonMap(
      await apiRequest('Order bill', () => _api.invoiceOrder(orderId, {})),
    );
    return invoice(jsonId(json['invoiceId']) ?? '');
  }

  @override
  Future<PageResult<Invoice>> invoices(int page) async {
    final json = await apiRequest(
      'Bill list',
      () => _api.invoices(pageQuery(page)),
    );
    return PageResult.fromJson(jsonMap(json), Invoice.fromJson);
  }

  @override
  Future<Invoice> invoice(String id) async => Invoice.fromDetail(
    jsonMap(await apiRequest('Bill $id', () => _api.invoice(id))),
    today: _clock(),
  );

  @override
  Future<Invoice> splitInvoice(String id, InstalmentPlan plan) async {
    await apiRequest(
      'Bill instalments',
      () => _api.splitInvoice(id, plan.toJson()),
    );
    return invoice(id);
  }

  @override
  Future<Invoice> cancelInvoice(String id, String reason) async {
    await apiRequest(
      'Bill cancel',
      () => _api.cancelInvoice(id, {'reason': reason.trim()}),
    );
    return invoice(id);
  }
}
