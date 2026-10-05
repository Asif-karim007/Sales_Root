import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// How long money has been owed: not yet due, or days past the due date.
enum AgingBucket {
  current('current'),
  upTo30('b130'),
  upTo60('b3160'),
  upTo90('b6190'),
  over90('b90Plus');

  const AgingBucket(this.wire);

  /// The key of the bucket in `GET dues/summary`.
  final String wire;
}

enum OutstandingFilter {
  all(null),
  overdue('overdue');

  const OutstandingFilter(this.bucket);

  /// The `bucket` of `GET dues`.
  final String? bucket;
}

class OutstandingQuery {
  const OutstandingQuery({
    this.filter = OutstandingFilter.all,
    this.search = '',
    this.page = 1,
  });

  final OutstandingFilter filter;
  final String search;
  final int page;

  OutstandingQuery atPage(int page) =>
      OutstandingQuery(filter: filter, search: search, page: page);

  Map<String, dynamic> toQuery() => {
    'bucket': ?filter.bucket,
    if (search.trim().isNotEmpty) 'q': search.trim(),
    ...pageQuery(page),
  };
}

/// `GET dues/summary`.
class OutstandingSummary {
  const OutstandingSummary({
    required this.total,
    required this.customerCount,
    required this.buckets,
    required this.collectedToday,
    required this.collectedThisMonth,
  });

  final double total;
  final int customerCount;
  final Map<AgingBucket, double> buckets;
  final double collectedToday;
  final double collectedThisMonth;

  /// Everything past its due date.
  double get overdue => total - (buckets[AgingBucket.current] ?? 0);

  factory OutstandingSummary.fromJson(Map<String, dynamic> json) =>
      OutstandingSummary(
        total: jsonDouble(json['total']) ?? 0,
        customerCount: jsonInt(json['companies']) ?? 0,
        buckets: {
          for (final bucket in AgingBucket.values)
            bucket: jsonDouble(json[bucket.wire]) ?? 0,
        },
        collectedToday: jsonDouble(json['collectedToday']) ?? 0,
        collectedThisMonth: jsonDouble(json['collectedMonth']) ?? 0,
      );
}

/// One customer's unpaid dues: a row of `GET dues`.
class CustomerOutstanding {
  const CustomerOutstanding({
    required this.companyId,
    required this.companyName,
    required this.items,
    required this.oldestDays,
    required this.due,
    required this.overdue,
    this.oldestDueDate,
    this.area,
  });

  final String companyId;
  final String companyName;

  /// How many receivables are open.
  final int items;

  /// Days the oldest due is late; 0 when nothing is late yet.
  final int oldestDays;
  final double due;
  final double overdue;
  final DateTime? oldestDueDate;
  final String? area;

  bool get isOverdue => overdue > 0;

  factory CustomerOutstanding.fromJson(Map<String, dynamic> json) =>
      CustomerOutstanding(
        companyId: jsonId(json['companyId']) ?? '',
        companyName: json['companyName'] as String? ?? '',
        items: jsonInt(json['items']) ?? 0,
        oldestDays: jsonInt(json['maxAgeDays']) ?? 0,
        due: jsonDouble(json['outstanding']) ?? 0,
        overdue: jsonDouble(json['overdue']) ?? 0,
        oldestDueDate: jsonDate(json['oldestDue']),
        area: json['area'] as String?,
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
  });

  final double collectedToday;
  final double collectedYesterday;
  final double collectedThisMonth;
  final double todayCash;
  final double todayMobile;
  final double todayBank;
  final double receivable;
  final double overdue;

  /// What fell due today.
  final double dueToday;

  /// Change on yesterday in percent; null when nothing came in yesterday.
  double? get changeOnYesterday => collectedYesterday == 0
      ? null
      : (collectedToday - collectedYesterday) * 100 / collectedYesterday;

  /// The dues [summary] and the last seven days of `GET reports/collection`
  /// by day, today last.
  factory CollectionSummary.from(
    OutstandingSummary summary,
    Map<String, dynamic> report,
  ) {
    final days = jsonList(report['trend'], (row) => row);
    Map<String, dynamic> dayBefore(int back) =>
        days.length > back ? days[days.length - 1 - back] : const {};
    final today = dayBefore(0);
    double of(Map<String, dynamic> day, String key) =>
        jsonDouble(day[key]) ?? 0;
    return CollectionSummary(
      collectedToday: of(today, 'collected'),
      collectedYesterday: of(dayBefore(1), 'collected'),
      collectedThisMonth: summary.collectedThisMonth,
      todayCash: of(today, 'cash'),
      todayMobile: of(today, 'mobileBanking'),
      todayBank: of(today, 'bank'),
      receivable: summary.total,
      overdue: summary.overdue,
      dueToday: of(today, 'fellDue'),
    );
  }
}
