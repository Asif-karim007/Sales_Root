import 'package:salesroot/core/utils/json_fields.dart';

enum ReportScope { mine, team }

enum ReportRange { thisMonth, lastMonth, thisQuarter, custom }

/// The report filter: whose numbers, and which dates (inclusive).
class ReportQuery {
  const ReportQuery({
    required this.scope,
    required this.range,
    required this.from,
    required this.to,
  });

  final ReportScope scope;
  final ReportRange range;
  final DateTime from;
  final DateTime to;

  factory ReportQuery.preset(
    ReportRange range, {
    required DateTime now,
    ReportScope scope = ReportScope.mine,
  }) {
    final (from, to) = switch (range) {
      ReportRange.lastMonth => (
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month, 0),
      ),
      ReportRange.thisQuarter => (
        DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1),
        DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 4, 0),
      ),
      _ => (
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1, 0),
      ),
    };
    return ReportQuery(scope: scope, range: range, from: from, to: to);
  }

  ReportQuery copyWith({
    ReportScope? scope,
    ReportRange? range,
    DateTime? from,
    DateTime? to,
  }) => ReportQuery(
    scope: scope ?? this.scope,
    range: range ?? this.range,
    from: from ?? this.from,
    to: to ?? this.to,
  );

  /// Whether the period is one calendar month.
  bool get isMonth =>
      from.day == 1 &&
      from.year == to.year &&
      from.month == to.month &&
      DateTime(to.year, to.month + 1, 0).day == to.day;

  /// The period as the report endpoints take it; [memberId] narrows the
  /// numbers to one member.
  Map<String, dynamic> toQuery({String? memberId}) => {
    ...switch (range) {
      ReportRange.thisMonth => const {'preset': 'this_month'},
      ReportRange.lastMonth => const {'preset': 'last_month'},
      ReportRange.thisQuarter => const {'preset': 'this_quarter'},
      ReportRange.custom => period(from, to),
    },
    if (scope == ReportScope.mine) 'ownerId': memberId,
  };

  /// A custom period, both days included.
  static Map<String, dynamic> period(DateTime from, DateTime to) => {
    'preset': 'custom',
    'from': dayString(from),
    'to': dayString(to),
  };

  /// `2026-10-04`.
  static String dayString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

int _amount(dynamic value) => jsonDouble(value)?.round() ?? 0;

class SourceStat {
  const SourceStat({
    required this.source,
    required this.leads,
    required this.won,
  });

  final String source;
  final int leads;
  final int won;

  /// A `bySource` row of `reports/conversion`.
  factory SourceStat.fromJson(Map<String, dynamic> json) => SourceStat(
    source: json['key'] as String? ?? '',
    leads: jsonInt(json['newLeads']) ?? 0,
    won: jsonInt(json['won']) ?? 0,
  );
}

/// The reports home: outcomes in the period and new leads per week.
class ReportOverview {
  const ReportOverview({
    required this.won,
    required this.lost,
    required this.open,
    required this.weeklyNewLeads,
    required this.sources,
  });

  final int won;
  final int lost;
  final int open;

  /// Up to eight weeks, oldest first, ending with the period's last week.
  final List<int> weeklyNewLeads;

  /// Most leads first.
  final List<SourceStat> sources;

  double get winRate => won + lost == 0 ? 0 : won / (won + lost);

  /// The last four weeks against the four before, as a fraction.
  double? get weeklyTrend {
    if (weeklyNewLeads.length < 8) return null;
    final before = weeklyNewLeads.take(4).fold<int>(0, (a, b) => a + b);
    final after = weeklyNewLeads.skip(4).fold<int>(0, (a, b) => a + b);
    if (before == 0) return null;
    return (after - before) / before;
  }

  /// `reports/conversion` for the period, and the same report by week for
  /// the eight weeks up to its end.
  factory ReportOverview.fromJson(
    Map<String, dynamic> period, {
    required Map<String, dynamic> weeks,
  }) {
    final summary = jsonMap(period['summary']);
    final trend = [
      for (final bucket in jsonList(weeks['trend'], (b) => b))
        jsonInt(bucket['newLeads']) ?? 0,
    ];
    return ReportOverview(
      won: jsonInt(summary['won']) ?? 0,
      lost: jsonInt(summary['lost']) ?? 0,
      open: jsonInt(summary['open']) ?? 0,
      weeklyNewLeads: trend.length > 8
          ? trend.sublist(trend.length - 8)
          : trend,
      sources: jsonList(
        jsonMap(period['breakdowns'])['bySource'],
        SourceStat.fromJson,
      )..sort((a, b) => b.leads.compareTo(a.leads)),
    );
  }
}

class MonthValue {
  const MonthValue({required this.month, required this.value});

  final DateTime month;
  final int value;

  /// A `trend` row of a report grouped by month: `{bucket: "2026-07"}`.
  factory MonthValue.fromJson(Map<String, dynamic> json) => MonthValue(
    month: DateTime.tryParse('${json['bucket'] ?? ''}-01') ?? DateTime(2000),
    value: _amount(json['wonAmount']),
  );
}

class MemberSales {
  const MemberSales({
    required this.name,
    required this.leads,
    required this.won,
    required this.wonValue,
    this.memberId,
  });

  final String? memberId;
  final String name;
  final int leads;
  final int won;
  final int wonValue;

  /// A `byPerson` row of `reports/conversion`.
  factory MemberSales.fromJson(Map<String, dynamic> json) => MemberSales(
    memberId: jsonId(json['id']),
    name: json['key'] as String? ?? '',
    leads: jsonInt(json['newLeads']) ?? 0,
    won: jsonInt(json['won']) ?? 0,
    wonValue: _amount(json['wonAmount']),
  );
}

class ProductSales {
  const ProductSales({required this.product, required this.value});

  final String product;
  final int value;

  /// A `byProduct` row of `reports/sales`.
  factory ProductSales.fromJson(Map<String, dynamic> json) => ProductSales(
    product: json['key'] as String? ?? '',
    value: _amount(json['amount']),
  );
}

class SalesReport {
  const SalesReport({
    required this.total,
    required this.previousTotal,
    required this.target,
    required this.months,
    required this.members,
    required this.products,
  });

  /// Won value in the period.
  final int total;

  /// Won value in the period of the same length just before.
  final int previousTotal;
  final int target;
  final List<MonthValue> months;

  /// Most won first.
  final List<MemberSales> members;

  /// Most sold first.
  final List<ProductSales> products;

  double? get growth =>
      previousTotal == 0 ? null : (total - previousTotal) / previousTotal;

  double get targetShare => target == 0 ? 0 : total / target;

  /// `reports/sales` for the period, the period before and the months up to
  /// it; `reports/targets` and `reports/conversion` for the period. With
  /// [memberId] the target is that member's own.
  factory SalesReport.fromJson({
    required Map<String, dynamic> sales,
    required Map<String, dynamic> previous,
    required Map<String, dynamic> months,
    required Map<String, dynamic> targets,
    required Map<String, dynamic> conversion,
    String? memberId,
  }) => SalesReport(
    total: _amount(jsonMap(sales['summary'])['wonAmount']),
    previousTotal: _amount(jsonMap(previous['summary'])['wonAmount']),
    target: memberId == null
        ? _amount(jsonMap(targets['summary'])['sales_target'])
        : _amount(
            jsonList(jsonMap(targets['breakdowns'])['byPerson'], (p) => p)
                .where((p) => jsonId(p['id']) == memberId)
                .firstOrNull?['salesTarget'],
          ),
    months: jsonList(months['trend'], MonthValue.fromJson),
    members: jsonList(
      jsonMap(conversion['breakdowns'])['byPerson'],
      MemberSales.fromJson,
    )..sort((a, b) => b.wonValue.compareTo(a.wonValue)),
    products: jsonList(
      jsonMap(sales['breakdowns'])['byProduct'],
      ProductSales.fromJson,
    )..sort((a, b) => b.value.compareTo(a.value)),
  );
}
