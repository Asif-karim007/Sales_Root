import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/role_grants.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/data/order_repository.dart';
import 'package:salesroot/features/sales/data/sales_ledger.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository(FakeBackend backend)
    : _backend = backend,
      _ledger = SalesLedger(backend);

  final FakeBackend _backend;
  final SalesLedger _ledger;

  FakeTable get _orders => _ledger.orders;
  FakeTable get _invoices => _ledger.invoices;

  @override
  Future<SalesOverview> overview() => _backend.run('Sales overview', () {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    var thisMonthSales = 0;
    var lastMonthSales = 0;
    var toDeliver = 0;
    for (final order in _orders.rows) {
      final created = jsonDate(order['CreatedAt']);
      if (created == null) continue;
      if (created.year == now.year && created.month == now.month) {
        thisMonthSales += SalesLedger.totalOf(order);
      } else if (created.year == lastMonth.year &&
          created.month == lastMonth.month) {
        lastMonthSales += SalesLedger.totalOf(order);
      }
      if (OrderStatus.fromWire(order['Status'] as String?).toDeliver) {
        toDeliver++;
      }
    }
    var open = 0;
    var openValue = 0;
    for (final quote in _ledger.quotations.rows) {
      if (QuotationStatus.fromWire(quote['Status'] as String?).isOpen) {
        open++;
        openValue += SalesLedger.totalOf(quote);
      }
    }
    final paid = _ledger.paidByInstalment();
    return SalesOverview.fromJson({
      'SalesThisMonth': thisMonthSales,
      'SalesLastMonth': lastMonthSales,
      'OpenQuotations': open,
      'OpenQuotationValue': openValue,
      'OrdersToDeliver': toDeliver,
      'Receivable': _invoices.rows.fold<int>(
        0,
        (sum, invoice) => sum + _ledger.invoiceDue(invoice, paid),
      ),
    });
  }, module: AppModule.quotation);

  @override
  Future<PageResult<SalesOrder>> list(OrderQuery query) =>
      _backend.run('Order list', () {
        final rows = _orders.rows
            .where(
              (r) =>
                  !query.toDeliver ||
                  OrderStatus.fromWire(r['Status'] as String?).toDeliver,
            )
            .toList();
        final paid = _ledger.paidByInstalment();
        final page = fakePage(rows, page: query.page);
        return PageResult.fromJson({
          ...page,
          'Items': [
            for (final row in page['Items'] as List<Map<String, dynamic>>)
              _ledger.orderJson(row, paid),
          ],
        }, SalesOrder.fromJson);
      }, module: AppModule.order);

  @override
  Future<SalesOrder> get(int id) => _backend.run(
    'Order $id',
    () => SalesOrder.fromJson(_ledger.orderJson(_orders.byId(id))),
    module: AppModule.order,
  );

  @override
  Future<SalesOrder> updateSchedule(int id, List<Instalment> instalments) =>
      _backend.run(
        'Order $id schedule',
        () {
          final order = _orders.byId(id);
          final total = SalesLedger.totalOf(order);
          final sum = instalments.fold<int>(0, (s, i) => s + i.amount);
          if (sum != total || instalments.any((i) => i.amount <= 0)) {
            throw ApiFailure(
              400,
              'The instalments must add up to $total',
              fieldErrors: {'Instalments': '$total'},
            );
          }
          final paid = _ledger.paidByInstalment();
          for (final row in instalments) {
            if ((paid['$id/${row.seq}'] ?? 0) > row.amount) {
              throw const ApiFailure(
                400,
                'An instalment cannot be less than what was collected on it',
                fieldErrors: {'Instalments': 'collected'},
              );
            }
          }
          final updated = _orders.update(id, {
            'Instalments': [for (final row in instalments) row.toJson()],
          });
          return SalesOrder.fromJson(_ledger.orderJson(updated));
        },
        module: AppModule.order,
        right: ModuleRight.edit,
      );

  @override
  Future<SalesOrder> logDelivery(int id, DeliveryInput input) => _backend.run(
    'Order $id delivery',
    () {
      final body = input.toJson();
      fakeRequire(body, ['ReceivedBy']);
      final order = _orders.byId(id);
      final status = OrderStatus.fromWire(order['Status'] as String?);
      if (!status.toDeliver) {
        throw const ApiFailure(409, 'This order is already delivered.');
      }
      final photos = body['Photos'];
      _orders.update(id, {
        'Status': OrderStatus.delivered.wire,
        'Delivery': {
          'DeliveredAt': body['DeliveredAt'],
          'ReceivedBy': body['ReceivedBy'],
          'Note': body['Note'] ?? '',
          'DeliveredProductIds': body['DeliveredProductIds'],
          'PhotoCount': photos is List ? photos.length : 0,
          'Signed': body['Signature'] != null,
        },
      });
      if (input.createBill) _bill(id);
      return SalesOrder.fromJson(_ledger.orderJson(_orders.byId(id)));
    },
    module: AppModule.order,
    right: ModuleRight.edit,
  );

  @override
  Future<Invoice> createInvoice(int orderId) => _backend.run(
    'Order $orderId bill',
    () => Invoice.fromJson(_ledger.invoiceJson(_bill(orderId))),
    module: AppModule.invoice,
    right: ModuleRight.add,
  );

  @override
  Future<PageResult<Invoice>> invoices(int page) =>
      _backend.run('Invoice list', () {
        final paid = _ledger.paidByInstalment();
        final result = fakePage(_invoices.rows, page: page);
        return PageResult.fromJson({
          ...result,
          'Items': [
            for (final row in result['Items'] as List<Map<String, dynamic>>)
              _ledger.invoiceJson(row, paid),
          ],
        }, Invoice.fromJson);
      }, module: AppModule.invoice);

  @override
  Future<Invoice> invoice(int id) => _backend.run(
    'Invoice $id',
    () => Invoice.fromJson(_ledger.invoiceJson(_invoices.byId(id))),
    module: AppModule.invoice,
  );

  Map<String, dynamic> _bill(int orderId) {
    final grant = roleGrant(_backend.role, AppModule.invoice);
    if (!ModuleAccess.fromPermission(grant).canAdd) {
      throw const ApiFailure(403, 'You do not have permission to do that.');
    }
    final order = _orders.byId(orderId);
    if (order['InvoiceId'] != null) {
      throw const ApiFailure(409, 'This order already has a bill.');
    }
    final now = DateTime.now();
    final id = _invoices.nextId();
    final invoice = _invoices.insert({
      'Id': id,
      'Number': invoiceNumber(now.year, 900 + id),
      'OrderId': orderId,
      'OrderNumber': order['Number'],
      'CompanyId': order['CompanyId'],
      'CompanyName': order['CompanyName'],
      'ContactName': order['ContactName'],
      'ContactPhone': order['ContactPhone'],
      'Lines': order['Lines'],
      'DiscountBps': order['DiscountBps'],
      'VatBps': order['VatBps'],
      'IssuedAt': jsonUtc(now),
      'OwnerId': order['OwnerId'],
    });
    _orders.update(orderId, {
      'Status': OrderStatus.invoiced.wire,
      'InvoiceId': id,
      'InvoiceNumber': invoice['Number'],
    });
    return invoice;
  }
}
