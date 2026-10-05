import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';

import '../../helpers/api_stub.dart';
import 'sales_test_setup.dart';

Instalment _due(String id, double amount, DateTime date, {double paid = 0}) =>
    Instalment(id: id, label: id, dueDate: date, amount: amount, paid: paid);

void main() {
  group('totals', () {
    test('the app works the totals out as the server does', () {
      final json = fixtureMap('sales_quote_created');
      final quote = Quotation.fromDetail(json);
      final local = computeTotals(quote.lines, discountBps: quote.discountBps);

      expect(quote.discountBps, 400);
      expect(quote.lines.first.discountBps, 500);
      expect(quote.lines.first.vatBps, 1500);
      expect(quote.lines.first.net, 8170);
      expect(local.subtotal, quote.totals.subtotal);
      expect(local.discount, quote.totals.discount);
      expect(local.vat, quote.totals.vat);
      expect(local.total, closeTo(10459.68, 0.001));
      expect(quote.totals.total, closeTo(10459.68, 0.001));
      expect(local.lineDiscount, 430);
    });

    test('a line goes out as a LineInput with percentages', () {
      final line = Product.fromJson(
        (fixture('sales_products') as List)[2] as Map<String, dynamic>,
      );
      final json = SalesLine.of(
        line,
        qty: 3,
      ).copyWith(discountBps: 250).toJson();

      expect(json, {
        'productId': soapId,
        'description': 'Soap 100g (carton of 48)',
        'qty': 3.0,
        'unit': 'ctn',
        'unitPrice': 4300.0,
        'discountPct': 2.5,
        'taxPct': 0.0,
      });
    });
  });

  group('parsing', () {
    test('products: names in both languages, code and unit', () {
      final products = [
        for (final row in fixture('sales_products') as List)
          Product.fromJson(row as Map<String, dynamic>),
      ];

      expect(products.map((p) => p.code), ['SVC-DEL', 'DET-1KG', 'SOAP-100']);
      expect(products.first.nameIn(bangla: true), 'ডেলিভারি সার্ভিস');
      expect(products.first.nameIn(bangla: false), 'Delivery service');
      expect(products.first.price, 1500);
      expect(products.first.stock, isNull);
    });

    test('an order with a bill shows as billed', () {
      final detail = SalesOrder.fromDetail(fixtureMap('sales_order'));
      final rows = [
        for (final row in fixtureMap('sales_orders')['items'] as List)
          SalesOrder.fromJson(row as Map<String, dynamic>),
      ];

      expect(detail.status, OrderStatus.invoiced);
      expect(detail.lines.single.qty, 47.619);
      expect(detail.invoices.single.number, 'INV-2026-00001');
      expect(detail.openInvoice?.due, 50000);
      expect(rows.map((o) => o.status), [
        OrderStatus.cancelled,
        OrderStatus.invoiced,
      ]);
      expect(
        SalesOrder.fromDetail(fixtureMap('sales_order_confirmed')).status,
        OrderStatus.confirmed,
      );
    });

    test('a bill\'s instalments count late days from today', () {
      final invoice = Invoice.fromDetail(
        fixtureMap('sales_invoice'),
        today: DateTime(2026, 10, 25),
      );

      expect(invoice.orderNumber, 'SO-2026-00001');
      expect(invoice.status, InvoiceStatus.partial);
      expect(invoice.paid, 50000);
      expect(invoice.due, 50000);
      expect(invoice.instalments.map((i) => i.state), [
        InstalmentState.paid,
        InstalmentState.overdue,
      ]);
      expect(invoice.instalments.last.daysOverdue, 2);
      expect(invoice.instalments.last.seq, 2);
    });

    test('a payment\'s allocations come as an encoded list', () {
      final payment = Collection.fromJson(fixtureMap('sales_payment'));

      expect(payment.number, 'RCPT-2026-00001');
      expect(payment.method, PaymentMethod.bkash);
      expect(payment.reference, 'BKX7H2K9Q1');
      expect(payment.receivedByName, 'Rafi Ahmed');
      expect(payment.allocations.single.label, '1st instalment');
      expect(payment.allocations.single.amount, 50000);
      expect(payment.cancelled, isFalse);

      final cheque = Collection.fromJson(fixtureMap('sales_payment_created'));
      expect(cheque.method, PaymentMethod.cheque);
      expect(cheque.chequeStatus, ChequeStatus.pending);
      expect(cheque.allocations, hasLength(2));
    });

    test('dues: by customer, with the ageing buckets', () {
      final rows = [
        for (final row in fixtureMap('sales_dues')['items'] as List)
          CustomerOutstanding.fromJson(row as Map<String, dynamic>),
      ];
      final summary = OutstandingSummary.fromJson(
        fixtureMap('sales_dues_summary'),
      );

      expect(rows.first.companyName, 'Rahim Traders');
      expect(rows.first.isOverdue, isTrue);
      expect(rows.first.oldestDays, 44);
      expect(rows.last.isOverdue, isFalse);
      expect(summary.total, 118000);
      expect(summary.overdue, 68000);
      expect(summary.customerCount, 2);
      expect(summary.buckets[AgingBucket.current], 50000);
      expect(summary.buckets[AgingBucket.upTo60], 68000);
    });

    test('the collection figures come from the last seven days', () {
      final summary = CollectionSummary.from(
        OutstandingSummary.fromJson(fixtureMap('sales_dues_summary')),
        fixtureMap('sales_report_collection_week'),
      );

      expect(summary.collectedToday, 7000);
      expect(summary.todayBank, 7000);
      expect(summary.collectedYesterday, 0);
      expect(summary.changeOnYesterday, isNull);
      expect(summary.receivable, 118000);
      expect(summary.overdue, 68000);
    });
  });

  group('allocation', () {
    test('fills the oldest due first and leaves the rest over', () {
      final items = [
        _due('b', 5000, DateTime(2026, 10, 20)),
        _due('a', 3000, DateTime(2026, 9, 1), paid: 1000),
        _due('c', 4000, DateTime(2026, 11, 1)),
      ];

      final allocations = allocateOldestFirst(items, 8000);

      expect(allocations.map((a) => (a.receivableId, a.amount)), [
        ('a', 2000),
        ('b', 5000),
        ('c', 1000),
      ]);
      expect(
        allocateOldestFirst(
          items,
          20000,
        ).fold<double>(0, (sum, a) => sum + a.amount),
        11000,
      );
    });

    test('a split is equal parts with the rest on the last', () {
      final plan = InstalmentPlan(
        count: 3,
        intervalDays: 15,
        firstDueDate: DateTime(2026, 10, 10),
      );

      expect(plan.split(10000), [3333.33, 3333.33, 3333.34]);
      expect(plan.dueOf(2), DateTime(2026, 11, 9));
      expect(plan.toJson(), {
        'count': 3,
        'intervalDays': 15,
        'firstDueDate': '2026-10-10',
      });
    });
  });
}
