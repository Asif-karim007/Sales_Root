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

  Map<String, dynamic> toQuery() => {
    'Scope': scope == ReportScope.team ? 'Team' : 'Mine',
    'From': dayString(from),
    'To': dayString(to),
  };

  /// `2026-10-04`.
  static String dayString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class SourceStat {
  const SourceStat({
    required this.source,
    required this.leads,
    required this.won,
  });

  final String source;
  final int leads;
  final int won;

  factory SourceStat.fromJson(Map<String, dynamic> json) => SourceStat(
    source: json['Source'] as String? ?? '',
    leads: jsonInt(json['Leads']) ?? 0,
    won: jsonInt(json['Won']) ?? 0,
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

  /// Eight weeks, oldest first, ending with the period's last week.
  final List<int> weeklyNewLeads;
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

  factory ReportOverview.fromJson(Map<String, dynamic> json) => ReportOverview(
    won: jsonInt(json['Won']) ?? 0,
    lost: jsonInt(json['Lost']) ?? 0,
    open: jsonInt(json['Open']) ?? 0,
    weeklyNewLeads: jsonInts(json['WeeklyNewLeads']),
    sources: jsonList(json['Sources'], SourceStat.fromJson),
  );
}

class MonthValue {
  const MonthValue({required this.month, required this.value});

  final DateTime month;
  final int value;

  factory MonthValue.fromJson(Map<String, dynamic> json) => MonthValue(
    month: DateTime.tryParse(json['Month'] as String? ?? '') ?? DateTime(2000),
    value: jsonInt(json['Value']) ?? 0,
  );
}

class MemberSales {
  const MemberSales({
    required this.memberId,
    required this.name,
    required this.leads,
    required this.won,
    required this.wonValue,
    required this.openValue,
  });

  final int memberId;
  final LocalizedName name;
  final int leads;
  final int won;
  final int wonValue;
  final int openValue;

  factory MemberSales.fromJson(Map<String, dynamic> json) => MemberSales(
    memberId: jsonInt(json['MemberId']) ?? 0,
    name: LocalizedName.fromJson(json),
    leads: jsonInt(json['Leads']) ?? 0,
    won: jsonInt(json['Won']) ?? 0,
    wonValue: jsonInt(json['WonValue']) ?? 0,
    openValue: jsonInt(json['OpenValue']) ?? 0,
  );
}

class CategorySales {
  const CategorySales({required this.category, required this.value});

  final String category;
  final int value;

  factory CategorySales.fromJson(Map<String, dynamic> json) => CategorySales(
    category: json['Category'] as String? ?? '',
    value: jsonInt(json['Value']) ?? 0,
  );
}

class SalesReport {
  const SalesReport({
    required this.total,
    required this.previousTotal,
    required this.target,
    required this.months,
    required this.members,
    required this.categories,
  });

  /// Won value in the period.
  final int total;

  /// Won value in the period of the same length just before.
  final int previousTotal;
  final int target;
  final List<MonthValue> months;
  final List<MemberSales> members;
  final List<CategorySales> categories;

  double? get growth =>
      previousTotal == 0 ? null : (total - previousTotal) / previousTotal;

  double get targetShare => target == 0 ? 0 : total / target;

  factory SalesReport.fromJson(Map<String, dynamic> json) => SalesReport(
    total: jsonInt(json['Total']) ?? 0,
    previousTotal: jsonInt(json['PreviousTotal']) ?? 0,
    target: jsonInt(json['Target']) ?? 0,
    months: jsonList(json['Months'], MonthValue.fromJson),
    members: jsonList(json['Members'], MemberSales.fromJson),
    categories: jsonList(json['Categories'], CategorySales.fromJson),
  );
}
