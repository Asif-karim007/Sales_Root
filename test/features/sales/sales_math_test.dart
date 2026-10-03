import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

SalesLine _line(int qty, int price, {int discountBps = 0}) => SalesLine(
  productId: price,
  code: 'P$price',
  name: 'Item $price',
  nameBn: '',
  unit: 'piece',
  qty: qty,
  unitPrice: price,
  discountBps: discountBps,
);

DueItem _due(int orderId, int seq, int amount, DateTime date, {int paid = 0}) =>
    DueItem(
      orderId: orderId,
      orderNumber: 'SO-$orderId',
      instalment: Instalment(
        seq: seq,
        kind: InstalmentKind.onDelivery,
        dueDate: date,
        amount: amount,
        paid: paid,
      ),
    );

void main() {
  group('quotation totals', () {
    test('discount comes off the subtotal and VAT is charged on the rest', () {
      final totals = computeTotals(
        [_line(12, 17200), _line(1, 63000), _line(6, 4000)],
        discountBps: 500,
        vatBps: standardVatBps,
      );

      expect(totals.subtotal, 293400);
      expect(totals.discount, 14670);
      expect(totals.taxable, 278730);
      expect(totals.vat, 41810);
      expect(totals.total, 320540);
    });

    test('line discounts apply before the overall discount', () {
      final totals = computeTotals(
        [_line(10, 1000, discountBps: 1000), _line(1, 500)],
        discountBps: 1000,
        vatBps: 1500,
      );

      expect(totals.gross, 10500);
      expect(totals.lineDiscount, 1000);
      expect(totals.subtotal, 9500);
      expect(totals.discount, 950);
      expect(totals.vat, 1283);
      expect(totals.total, 9833);
    });

    test('rounding is half up to whole taka', () {
      expect(applyBps(1, 5000), 1);
      expect(applyBps(3, 5000), 2);
      expect(applyBps(99, 1500), 15);
      expect(roundDiv(-5, 2), -3);
      expect(bpsFromPercent(7.5), 750);
    });

    test('no lines add up to zero', () {
      final totals = computeTotals(const [], discountBps: 500, vatBps: 1500);

      expect(totals.total, 0);
    });
  });

  group('payment terms', () {
    test('every schedule adds up to the total exactly', () {
      final start = DateTime(2026, 10, 1);
      for (final terms in PaymentTerms.values) {
        final rows = terms.schedule(320541, start, 14);
        expect(
          rows.fold<int>(0, (s, r) => s + r.amount),
          320541,
          reason: '$terms',
        );
      }
    });

    test('50% advance is due at once and the rest on delivery', () {
      final rows = PaymentTerms.advance50.schedule(
        320540,
        DateTime(2026, 10, 1),
        14,
      );

      expect(rows.map((r) => r.amount), [160270, 160270]);
      expect(rows.last.dueDate, DateTime(2026, 10, 15));
    });
  });

  group('collection allocation', () {
    final oldest = DateTime(2026, 9, 1);
    final newer = DateTime(2026, 9, 20);

    test('fills the oldest instalment first', () {
      final allocations = allocateOldestFirst([
        _due(2, 1, 40000, newer),
        _due(1, 2, 50000, oldest, paid: 20000),
      ], 45000);

      expect(allocations.map((a) => (a.orderId, a.amount)), [
        (1, 30000),
        (2, 15000),
      ]);
    });

    test('leaves what does not fit unallocated', () {
      final allocations = allocateOldestFirst([
        _due(1, 1, 10000, oldest),
      ], 15000);

      expect(allocations.single.amount, 10000);
    });
  });

  group('aging buckets', () {
    test('bucket edges', () {
      expect(AgingBucket.of(0), AgingBucket.upTo30);
      expect(AgingBucket.of(30), AgingBucket.upTo30);
      expect(AgingBucket.of(31), AgingBucket.upTo60);
      expect(AgingBucket.of(60), AgingBucket.upTo60);
      expect(AgingBucket.of(61), AgingBucket.upTo90);
      expect(AgingBucket.of(90), AgingBucket.upTo90);
      expect(AgingBucket.of(91), AgingBucket.over90);
    });

    test('sums dues into their buckets', () {
      final buckets = agingOf([(3, 100), (45, 200), (12, 50), (120, 400)]);

      expect(buckets, {
        AgingBucket.upTo30: 150,
        AgingBucket.upTo60: 200,
        AgingBucket.upTo90: 0,
        AgingBucket.over90: 400,
      });
    });
  });
}
