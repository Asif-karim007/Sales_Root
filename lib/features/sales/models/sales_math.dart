/// Basis points per whole: 1% is 100 bps.
const int bpsPerWhole = 10000;

/// A percentage typed by the user (`5`, `7.5`) as basis points.
int bpsFromPercent(double percent) => (percent * 100).round();

double percentFromBps(int bps) => bps / 100;

/// [amount] rounded to paisa, as the server stores money.
double roundMoney(double amount) => (amount * 100).roundToDouble() / 100;

/// [amount] less [bps] of it.
double lessBps(double amount, int bps) =>
    amount * (bpsPerWhole - bps) / bpsPerWhole;

/// What a document's lines add up to. Line discounts come off each line, the
/// overall discount off the subtotal, and each line's VAT is charged on what
/// is left of it.
class SalesTotals {
  const SalesTotals({
    required this.gross,
    required this.subtotal,
    required this.discount,
    required this.vat,
  });

  /// Quantity × unit price over all lines.
  final double gross;

  /// Gross less line discounts.
  final double subtotal;

  /// The overall discount on [subtotal].
  final double discount;
  final double vat;

  double get lineDiscount => gross - subtotal;
  double get taxable => subtotal - discount;
  double get total => taxable + vat;

  static const zero = SalesTotals(gross: 0, subtotal: 0, discount: 0, vat: 0);
}

/// One priced line, as the totals see it.
abstract interface class PricedLine {
  double get qty;
  double get unitPrice;
  int get discountBps;
  int get vatBps;
}

extension PricedLineMath on PricedLine {
  double get gross => qty * unitPrice;
  double get net => roundMoney(lessBps(gross, discountBps));
  double get discountAmount => gross - net;
}

SalesTotals computeTotals(
  Iterable<PricedLine> lines, {
  required int discountBps,
}) {
  var gross = 0.0;
  var subtotal = 0.0;
  var vat = 0.0;
  for (final line in lines) {
    gross += line.gross;
    subtotal += line.net;
    vat += lessBps(line.net, discountBps) * line.vatBps / bpsPerWhole;
  }
  return SalesTotals(
    gross: roundMoney(gross),
    subtotal: roundMoney(subtotal),
    discount: roundMoney(subtotal * discountBps / bpsPerWhole),
    vat: roundMoney(vat),
  );
}
