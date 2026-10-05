import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/team_summary.dart';

/// The money side of the business, for owners and managers.
class MoneySummary {
  const MoneySummary({
    this.today = const CollectionPeriod(),
    this.month = const CollectionPeriod(),
    this.receivable = 0,
    this.overdue = 0,
    this.overdueCustomers = 0,
    this.salesMonth = 0,
    this.salesLastMonth,
    this.salesTarget = 0,
    this.teamToday = const TeamToday(),
    this.topSellers = const [],
    this.forecastWeeks = const [],
    this.forecastPipeline = 0,
    this.departments = const [],
    this.staleLeads = 0,
    this.overdueCustomer,
  });

  final CollectionPeriod today;
  final CollectionPeriod month;
  final double receivable;
  final double overdue;
  final int overdueCustomers;
  final double salesMonth;
  final double? salesLastMonth;
  final double salesTarget;
  final TeamToday teamToday;
  final List<TopSeller> topSellers;

  /// Won value to date at the end of each week of the month.
  final List<double> forecastWeeks;

  /// The weighted value of the open pipeline.
  final double forecastPipeline;
  final List<DepartmentScore> departments;
  final int staleLeads;

  /// The customer whose dues are longest overdue.
  final OverdueCustomer? overdueCustomer;

  int get targetPercent =>
      salesTarget <= 0 ? 0 : (salesMonth * 100 / salesTarget).round();

  int? get salesChangePercent {
    final previous = salesLastMonth;
    if (previous == null || previous == 0) return null;
    return ((salesMonth - previous) * 100 / previous).round();
  }
}

/// Money collected in a period, split by how it came in, against the period
/// before.
class CollectionPeriod {
  const CollectionPeriod({
    this.total = 0,
    this.previous,
    this.cash = 0,
    this.mobile = 0,
    this.bank = 0,
  });

  final double total;
  final double? previous;
  final double cash;
  final double mobile;
  final double bank;

  int? get changePercent {
    final previous = this.previous;
    if (previous == null || previous == 0) return null;
    return ((total - previous) * 100 / previous).round();
  }

  /// The last bucket of a `GET reports/collection` trend, against the one
  /// before it.
  factory CollectionPeriod.fromJson(Map<String, dynamic> json) {
    final trend = jsonList(json['trend'], (row) => row);
    if (trend.isEmpty) return const CollectionPeriod();
    final last = trend.last;
    return CollectionPeriod(
      total: jsonDouble(last['collected']) ?? 0,
      previous: trend.length < 2
          ? null
          : jsonDouble(trend[trend.length - 2]['collected']) ?? 0,
      cash: jsonDouble(last['cash']) ?? 0,
      mobile: jsonDouble(last['mobileBanking']) ?? 0,
      bank: jsonDouble(last['bank']) ?? 0,
    );
  }
}

class TeamToday {
  const TeamToday({
    this.calls = 0,
    this.visits = 0,
    this.newLeads = 0,
    this.present = 0,
    this.headcount = 0,
  });

  final int calls;
  final int visits;
  final int newLeads;

  /// Checked in today, on time or late.
  final int present;
  final int headcount;

  int get absent => headcount > present ? headcount - present : 0;

  factory TeamToday.from(DayNumbers day) => TeamToday(
    calls: day.calls,
    visits: day.visits,
    newLeads: day.newLeads,
    present: day.present + day.late,
    headcount: day.teamSize,
  );
}

/// One person of `GET targets` and their won sales this month.
class TopSeller {
  const TopSeller({
    required this.memberId,
    required this.name,
    required this.amount,
    this.teamId,
    this.teamName,
  });

  final String memberId;
  final String name;
  final double amount;
  final String? teamId;
  final String? teamName;

  factory TopSeller.fromJson(Map<String, dynamic> json) => TopSeller(
    memberId: jsonId(json['membershipId']) ?? '',
    name: json['name'] as String? ?? '',
    amount: jsonDouble(json['sales']) ?? 0,
    teamId: jsonId(json['teamId']),
    teamName: json['teamName'] as String?,
  );

  /// The three who sold most, leaving out those who sold nothing.
  static List<TopSeller> top(List<TopSeller> people) =>
      (people.where((p) => p.amount > 0).toList()
            ..sort((a, b) => b.amount.compareTo(a.amount)))
          .take(3)
          .toList();
}

/// A team's sales this month against its members' targets.
class DepartmentScore {
  const DepartmentScore({required this.name, required this.percent});

  final String name;
  final int percent;

  /// Teams from [people] with a target set, best first.
  static List<DepartmentScore> of(
    List<TopSeller> people,
    List<PersonTarget> targets,
  ) {
    final byMember = {for (final t in targets) t.memberId: t};
    final teams = <String, (String, double, double)>{};
    for (final person in people) {
      final teamId = person.teamId;
      final target = byMember[person.memberId];
      if (teamId == null || target == null) continue;
      final (_, actual, goal) = teams[teamId] ?? (person.teamName ?? '', 0, 0);
      teams[teamId] = (
        person.teamName ?? '',
        actual + target.actual,
        goal + target.target,
      );
    }
    return [
      for (final (name, actual, goal) in teams.values)
        if (goal > 0)
          DepartmentScore(name: name, percent: (actual * 100 / goal).round()),
    ]..sort((a, b) => b.percent.compareTo(a.percent));
  }
}

/// One row of `GET dues`.
class OverdueCustomer {
  const OverdueCustomer({
    required this.companyId,
    required this.name,
    required this.days,
    required this.amount,
    this.ownerName,
  });

  final String companyId;
  final String name;
  final int days;
  final double amount;
  final String? ownerName;

  factory OverdueCustomer.fromJson(Map<String, dynamic> json) =>
      OverdueCustomer(
        companyId: jsonId(json['companyId']) ?? '',
        name: json['companyName'] as String? ?? '',
        days: jsonInt(json['maxAgeDays']) ?? 0,
        amount: jsonDouble(json['overdue']) ?? 0,
        ownerName: json['ownerName'] as String?,
      );

  /// The longest overdue of [rows], or null when none is overdue.
  static OverdueCustomer? worst(List<OverdueCustomer> rows) {
    OverdueCustomer? worst;
    for (final row in rows) {
      if (row.amount <= 0) continue;
      if (worst == null || row.days > worst.days) worst = row;
    }
    return worst;
  }
}
