/// Basis points per whole: 1% is 100 bps, 15% VAT is 1500.
const int bpsPerWhole = 10000;

/// The standard Bangladesh VAT rate.
const int standardVatBps = 1500;

/// [numerator] / [denominator] rounded half away from zero.
int roundDiv(int numerator, int denominator) {
  if (numerator < 0) return -roundDiv(-numerator, denominator);
  return (numerator * 2 + denominator) ~/ (denominator * 2);
}

/// [amount] taka × [bps], rounded half up to whole taka.
int applyBps(int amount, int bps) => roundDiv(amount * bps, bpsPerWhole);

/// A percentage typed by the user (`5`, `7.5`) as basis points.
int bpsFromPercent(double percent) => (percent * 100).round();

double percentFromBps(int bps) => bps / 100;

/// What a document's lines add up to. Line discounts come off each line,
/// the overall discount off the subtotal, and VAT is charged on the rest.
class SalesTotals {
  const SalesTotals({
    required this.gross,
    required this.lineDiscount,
    required this.subtotal,
    required this.discount,
    required this.vat,
  });

  /// Quantity × unit price over all lines.
  final int gross;
  final int lineDiscount;

  /// Gross less line discounts.
  final int subtotal;

  /// The overall discount on [subtotal].
  final int discount;
  final int vat;

  int get taxable => subtotal - discount;
  int get total => taxable + vat;

  static const zero = SalesTotals(
    gross: 0,
    lineDiscount: 0,
    subtotal: 0,
    discount: 0,
    vat: 0,
  );
}

/// One priced line, as the totals see it.
abstract interface class PricedLine {
  int get qty;
  int get unitPrice;
  int get discountBps;
}

extension PricedLineMath on PricedLine {
  int get gross => qty * unitPrice;
  int get discountAmount => applyBps(gross, discountBps);
  int get net => gross - discountAmount;
}

SalesTotals computeTotals(
  Iterable<PricedLine> lines, {
  required int discountBps,
  required int vatBps,
}) {
  var gross = 0;
  var lineDiscount = 0;
  for (final line in lines) {
    gross += line.gross;
    lineDiscount += line.discountAmount;
  }
  final subtotal = gross - lineDiscount;
  final discount = applyBps(subtotal, discountBps);
  return SalesTotals(
    gross: gross,
    lineDiscount: lineDiscount,
    subtotal: subtotal,
    discount: discount,
    vat: applyBps(subtotal - discount, vatBps),
  );
}
