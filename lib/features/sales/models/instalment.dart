import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

enum InstalmentState { paid, partial, upcoming, dueToday, overdue }

/// One receivable: a bill's instalment, or an opening balance carried in.
class Instalment {
  const Instalment({
    required this.id,
    required this.label,
    required this.dueDate,
    required this.amount,
    this.seq,
    this.paid = 0,
    this.daysOverdue,
    this.invoiceId,
  });

  final String id;

  /// The server's name for it: `1st instalment`, `1/2 instalment`, or the
  /// old bill number for an opening balance.
  final String label;

  /// The instalment number; null for a receivable not split from a bill.
  final int? seq;
  final DateTime dueDate;
  final double amount;
  final double paid;
  final String? invoiceId;

  /// Days past the due date: 0 on the day, negative before it.
  final int? daysOverdue;

  double get due => amount - paid;

  InstalmentState get state {
    if (due <= 0) return InstalmentState.paid;
    final days = daysOverdue ?? -1;
    if (days > 0) return InstalmentState.overdue;
    if (days == 0) return InstalmentState.dueToday;
    return paid > 0 ? InstalmentState.partial : InstalmentState.upcoming;
  }

  /// A row of `receivables` or of `GET companies/{id}/dues`. The due date is
  /// a calendar date, so how late it is counts from [today].
  factory Instalment.fromJson(Map<String, dynamic> json, {DateTime? today}) {
    final dueDate = jsonDate(json['dueDate']) ?? DateTime(2000);
    final day = today;
    return Instalment(
      id: jsonId(json['id']) ?? '',
      label: json['label'] as String? ?? '',
      seq: jsonInt(json['instalmentNo']),
      dueDate: dueDate,
      amount: jsonDouble(json['amount']) ?? 0,
      paid: jsonDouble(json['paidAmt']) ?? 0,
      invoiceId: jsonId(json['invoiceId']),
      daysOverdue: day == null
          ? null
          : AppDateUtils.dateOnly(
              day,
            ).difference(AppDateUtils.dateOnly(dueDate)).inDays,
    );
  }
}

/// `POST invoices/{id}/instalments`: the bill's balance split into [count]
/// equal parts, [intervalDays] apart from [firstDueDate].
class InstalmentPlan {
  const InstalmentPlan({
    required this.count,
    required this.intervalDays,
    required this.firstDueDate,
  });

  final int count;
  final int intervalDays;
  final DateTime firstDueDate;

  /// The parts as the server makes them: equal, the last taking the
  /// rounding.
  List<double> split(double total) {
    final part = (total / count * 100).floorToDouble() / 100;
    return [
      for (var i = 0; i < count; i++)
        i == count - 1 ? roundMoney(total - part * (count - 1)) : part,
    ];
  }

  DateTime dueOf(int index) => DateTime(
    firstDueDate.year,
    firstDueDate.month,
    firstDueDate.day + intervalDays * index,
  );

  Map<String, dynamic> toJson() => {
    'count': count,
    'intervalDays': intervalDays,
    'firstDueDate': AppDateUtils.toApiDateOnly(firstDueDate),
  };
}
