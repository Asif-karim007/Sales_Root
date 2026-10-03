import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/data/product_fixtures.dart';
import 'package:salesroot/features/sales/data/sales_fixtures.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

/// The fake server's sales tables and the joins it does on read: what has
/// been paid on each instalment comes from the collections, and ages are
/// counted on the server's clock.
class SalesLedger {
  SalesLedger(this.backend);

  final FakeBackend backend;

  FakeTable get products => backend.table('sales/products', productFixtures);
  FakeTable get customers => backend.table('sales/customers', customerFixtures);
  FakeTable get quotations =>
      backend.table('sales/quotations', quotationFixtures);
  FakeTable get orders => backend.table('sales/orders', orderFixtures);
  FakeTable get invoices => backend.table('sales/invoices', invoiceFixtures);
  FakeTable get collections =>
      backend.table('sales/collections', collectionFixtures);

  DateTime get today => AppDateUtils.dateOnly(DateTime.now());

  int daysSince(DateTime? date) =>
      date == null ? 0 : today.difference(AppDateUtils.dateOnly(date)).inDays;

  static int totalOf(Map<String, dynamic> row) => computeTotals(
    jsonList(row['Lines'], SalesLine.fromJson),
    discountBps: jsonInt(row['DiscountBps']) ?? 0,
    vatBps: jsonInt(row['VatBps']) ?? standardVatBps,
  ).total;

  /// Collected so far per instalment, keyed `orderId/seq`.
  Map<String, int> paidByInstalment() {
    final paid = <String, int>{};
    for (final row in collections.rows) {
      for (final allocation in _maps(row['Allocations'])) {
        final key = '${allocation['OrderId']}/${allocation['Seq']}';
        paid[key] = (paid[key] ?? 0) + (jsonInt(allocation['Amount']) ?? 0);
      }
    }
    return paid;
  }

  List<Map<String, dynamic>> instalmentsOf(
    Map<String, dynamic> order,
    Map<String, int> paid,
  ) => [
    for (final row in _maps(order['Instalments']))
      {
        ...row,
        'Paid': paid['${order['Id']}/${row['Seq']}'] ?? 0,
        'DaysOverdue': daysSince(jsonDate(row['DueDate'])),
      },
  ];

  Map<String, dynamic> orderJson(
    Map<String, dynamic> order, [
    Map<String, int>? paid,
  ]) => {
    ...order,
    'Instalments': instalmentsOf(order, paid ?? paidByInstalment()),
  };

  Map<String, dynamic> invoiceJson(
    Map<String, dynamic> invoice, [
    Map<String, int>? paid,
  ]) {
    final order = orders.byIdOrNull(jsonInt(invoice['OrderId']) ?? 0);
    return {
      ...invoice,
      'Instalments': order == null
          ? const <Map<String, dynamic>>[]
          : instalmentsOf(order, paid ?? paidByInstalment()),
      'AgeDays': daysSince(jsonDate(invoice['IssuedAt'])),
    };
  }

  /// What is still owed on [invoice].
  int invoiceDue(Map<String, dynamic> invoice, Map<String, int> paid) {
    final order = orders.byIdOrNull(jsonInt(invoice['OrderId']) ?? 0);
    if (order == null) return totalOf(invoice);
    final collected = instalmentsOf(
      order,
      paid,
    ).fold<int>(0, (sum, row) => sum + (jsonInt(row['Paid']) ?? 0));
    return totalOf(invoice) - collected;
  }

  /// Every instalment not yet paid in full, as due rows with their order and
  /// bill.
  List<Map<String, dynamic>> openInstalments({int? companyId}) {
    final paid = paidByInstalment();
    return [
      for (final order in orders.rows)
        if (companyId == null || order['CompanyId'] == companyId)
          for (final row in instalmentsOf(order, paid))
            if ((jsonInt(row['Amount']) ?? 0) > (jsonInt(row['Paid']) ?? 0))
              {
                ...row,
                'OrderId': order['Id'],
                'OrderNumber': order['Number'],
                'InvoiceId': order['InvoiceId'],
                'InvoiceNumber': order['InvoiceNumber'],
                'CompanyId': order['CompanyId'],
                'CompanyName': order['CompanyName'],
                'OwnerId': order['OwnerId'],
              },
    ];
  }

  /// What the customer owes on all their orders.
  int balanceOf(int companyId) => openInstalments(companyId: companyId).fold(
    0,
    (sum, row) =>
        sum + (jsonInt(row['Amount']) ?? 0) - (jsonInt(row['Paid']) ?? 0),
  );

  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? [
          for (final item in value)
            if (item is Map<String, dynamic>) item,
        ]
      : const [];
}
