import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/instalment.dart';

/// How old an unpaid bill is, in days since it was issued.
enum AgingBucket {
  upTo30('0-30'),
  upTo60('31-60'),
  upTo90('61-90'),
  over90('90+');

  const AgingBucket(this.wire);

  final String wire;

  static AgingBucket of(int days) {
    if (days <= 30) return upTo30;
    if (days <= 60) return upTo60;
    if (days <= 90) return upTo90;
    return over90;
  }
}

/// Sums [dues] (age in days, amount due) into the four buckets.
Map<AgingBucket, int> agingOf(Iterable<(int, int)> dues) {
  final buckets = {for (final bucket in AgingBucket.values) bucket: 0};
  for (final (days, amount) in dues) {
    final bucket = AgingBucket.of(days);
    buckets[bucket] = (buckets[bucket] ?? 0) + amount;
  }
  return buckets;
}

enum OutstandingFilter { all, overdue, mine, byCustomer }

class OutstandingSummary {
  const OutstandingSummary({
    required this.total,
    required this.overdue,
    required this.customerCount,
    required this.buckets,
  });

  final int total;
  final int overdue;
  final int customerCount;
  final Map<AgingBucket, int> buckets;

  factory OutstandingSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['Aging'];
    return OutstandingSummary(
      total: jsonInt(json['Total']) ?? 0,
      overdue: jsonInt(json['Overdue']) ?? 0,
      customerCount: jsonInt(json['CustomerCount']) ?? 0,
      buckets: {
        for (final bucket in AgingBucket.values)
          bucket: raw is Map ? jsonInt(raw[bucket.wire]) ?? 0 : 0,
      },
    );
  }
}

/// One customer's unpaid bills.
class CustomerOutstanding {
  const CustomerOutstanding({
    required this.companyId,
    required this.companyName,
    required this.bills,
    required this.oldestDays,
    required this.due,
    required this.overdue,
    this.nextDueDate,
    this.nextOrderNumber,
    this.instalmentsLeft = 0,
  });

  final int companyId;
  final String companyName;
  final int bills;
  final int oldestDays;
  final int due;
  final bool overdue;
  final DateTime? nextDueDate;
  final String? nextOrderNumber;
  final int instalmentsLeft;

  factory CustomerOutstanding.fromJson(Map<String, dynamic> json) =>
      CustomerOutstanding(
        companyId: jsonInt(json['CompanyId']) ?? 0,
        companyName: json['CompanyName'] as String? ?? '',
        bills: jsonInt(json['Bills']) ?? 0,
        oldestDays: jsonInt(json['OldestDays']) ?? 0,
        due: jsonInt(json['Due']) ?? 0,
        overdue: jsonBool(json['Overdue']),
        nextDueDate: jsonDate(json['NextDueDate']),
        nextOrderNumber: json['NextOrderNumber'] as String?,
        instalmentsLeft: jsonInt(json['InstalmentsLeft']) ?? 0,
      );
}

/// An open instalment on the collection list, with its customer.
class DueRow {
  const DueRow({
    required this.companyId,
    required this.companyName,
    required this.orderId,
    required this.orderNumber,
    required this.instalment,
    this.invoiceId,
    this.invoiceNumber,
  });

  final int companyId;
  final String companyName;
  final int orderId;
  final String orderNumber;
  final int? invoiceId;
  final String? invoiceNumber;
  final Instalment instalment;

  factory DueRow.fromJson(Map<String, dynamic> json) => DueRow(
    companyId: jsonInt(json['CompanyId']) ?? 0,
    companyName: json['CompanyName'] as String? ?? '',
    orderId: jsonInt(json['OrderId']) ?? 0,
    orderNumber: json['OrderNumber'] as String? ?? '',
    invoiceId: jsonInt(json['InvoiceId']),
    invoiceNumber: json['InvoiceNumber'] as String?,
    instalment: Instalment.fromJson(json),
  );
}

/// The collection home figures.
class CollectionSummary {
  const CollectionSummary({
    required this.collectedToday,
    required this.collectedYesterday,
    required this.collectedThisMonth,
    required this.todayCash,
    required this.todayMobile,
    required this.todayBank,
    required this.receivable,
    required this.overdue,
    required this.dueToday,
    required this.dueTodayCustomers,
  });

  final int collectedToday;
  final int collectedYesterday;
  final int collectedThisMonth;
  final int todayCash;
  final int todayMobile;
  final int todayBank;
  final int receivable;
  final int overdue;
  final int dueToday;
  final int dueTodayCustomers;

  /// Change on yesterday in percent; null when nothing came in yesterday.
  double? get changeOnYesterday => collectedYesterday == 0
      ? null
      : (collectedToday - collectedYesterday) * 100 / collectedYesterday;

  factory CollectionSummary.fromJson(Map<String, dynamic> json) =>
      CollectionSummary(
        collectedToday: jsonInt(json['CollectedToday']) ?? 0,
        collectedYesterday: jsonInt(json['CollectedYesterday']) ?? 0,
        collectedThisMonth: jsonInt(json['CollectedThisMonth']) ?? 0,
        todayCash: jsonInt(json['TodayCash']) ?? 0,
        todayMobile: jsonInt(json['TodayMobile']) ?? 0,
        todayBank: jsonInt(json['TodayBank']) ?? 0,
        receivable: jsonInt(json['Receivable']) ?? 0,
        overdue: jsonInt(json['Overdue']) ?? 0,
        dueToday: jsonInt(json['DueToday']) ?? 0,
        dueTodayCustomers: jsonInt(json['DueTodayCustomers']) ?? 0,
      );
}
