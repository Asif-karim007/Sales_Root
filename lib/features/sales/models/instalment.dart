import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

enum InstalmentKind {
  advance('Advance'),
  onDelivery('OnDelivery'),
  afterInstallation('AfterInstallation'),
  onBill('OnBill');

  const InstalmentKind(this.wire);

  final String wire;

  static InstalmentKind fromWire(String? value) => values.firstWhere(
    (k) => k.wire == value,
    orElse: () => InstalmentKind.onBill,
  );
}

/// How the total is split into instalments; the last share takes the rest so
/// the schedule always adds up to the total.
enum PaymentTerms {
  fullAdvance('FullAdvance', [(InstalmentKind.advance, 10000)]),
  advance50('Advance50', [
    (InstalmentKind.advance, 5000),
    (InstalmentKind.onDelivery, 5000),
  ]),
  advance50Split('Advance50Split', [
    (InstalmentKind.advance, 5000),
    (InstalmentKind.onDelivery, 3750),
    (InstalmentKind.afterInstallation, 1250),
  ]),
  advance30('Advance30', [
    (InstalmentKind.advance, 3000),
    (InstalmentKind.onDelivery, 5000),
    (InstalmentKind.afterInstallation, 2000),
  ]),
  onDelivery('OnDelivery', [(InstalmentKind.onDelivery, 10000)]),
  credit30('Credit30', [(InstalmentKind.onBill, 10000)]);

  const PaymentTerms(this.wire, this.shares);

  final String wire;
  final List<(InstalmentKind, int)> shares;

  static PaymentTerms fromWire(String? value) => values.firstWhere(
    (t) => t.wire == value,
    orElse: () => PaymentTerms.advance50,
  );

  /// The instalments for [total], dated from [start]: advance at once, the
  /// delivery share after [deliveryDays], installation 15 days later and
  /// credit 30 days later.
  List<Instalment> schedule(int total, DateTime start, int deliveryDays) {
    final rows = <Instalment>[];
    var left = total;
    for (var i = 0; i < shares.length; i++) {
      final (kind, bps) = shares[i];
      final amount = i == shares.length - 1 ? left : applyBps(total, bps);
      left -= amount;
      rows.add(
        Instalment(
          seq: i + 1,
          kind: kind,
          dueDate: start.add(Duration(days: _offset(kind, deliveryDays))),
          amount: amount,
        ),
      );
    }
    return rows;
  }

  static int _offset(InstalmentKind kind, int deliveryDays) => switch (kind) {
    InstalmentKind.advance => 0,
    InstalmentKind.onDelivery => deliveryDays,
    InstalmentKind.afterInstallation => deliveryDays + 15,
    InstalmentKind.onBill => 30,
  };
}

enum InstalmentState { paid, partial, upcoming, dueToday, overdue }

class Instalment {
  const Instalment({
    required this.seq,
    required this.kind,
    required this.dueDate,
    required this.amount,
    this.paid = 0,
    this.daysOverdue,
  });

  final int seq;
  final InstalmentKind kind;
  final DateTime dueDate;
  final int amount;
  final int paid;

  /// Days past the due date by the server's clock: 0 on the day, negative
  /// before it.
  final int? daysOverdue;

  int get due => amount - paid;

  InstalmentState get state {
    if (due <= 0) return InstalmentState.paid;
    final days = daysOverdue ?? -1;
    if (days > 0) return InstalmentState.overdue;
    if (days == 0) return InstalmentState.dueToday;
    return paid > 0 ? InstalmentState.partial : InstalmentState.upcoming;
  }

  Instalment copyWith({DateTime? dueDate, int? amount}) => Instalment(
    seq: seq,
    kind: kind,
    dueDate: dueDate ?? this.dueDate,
    amount: amount ?? this.amount,
    paid: paid,
    daysOverdue: daysOverdue,
  );

  factory Instalment.fromJson(Map<String, dynamic> json) => Instalment(
    seq: jsonInt(json['Seq']) ?? 1,
    kind: InstalmentKind.fromWire(json['Kind'] as String?),
    dueDate: jsonDate(json['DueDate']) ?? DateTime(2000),
    amount: jsonInt(json['Amount']) ?? 0,
    paid: jsonInt(json['Paid']) ?? 0,
    daysOverdue: jsonInt(json['DaysOverdue']),
  );

  Map<String, dynamic> toJson() => {
    'Seq': seq,
    'Kind': kind.wire,
    'DueDate': jsonUtc(dueDate),
    'Amount': amount,
  };
}
