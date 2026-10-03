import 'package:salesroot/core/utils/json_fields.dart';

/// The money side of the business, for owners and managers.
class MoneySummary {
  const MoneySummary({
    required this.today,
    required this.month,
    this.receivable = 0,
    this.overdue = 0,
    this.overdueCustomers = 0,
    this.salesMonth = 0,
    this.salesLastMonth = 0,
    this.salesTarget = 0,
    this.teamToday = const TeamToday(),
    this.topSellers = const [],
    this.forecastWeeks = const [],
    this.forecastPipeline = 0,
    this.forecastAtRisk = 0,
    this.departments = const [],
    this.staleLeads = 0,
    this.staleLeadsTeam,
    this.overdueCustomer,
  });

  final CollectionPeriod today;
  final CollectionPeriod month;
  final int receivable;
  final int overdue;
  final int overdueCustomers;
  final int salesMonth;
  final int salesLastMonth;
  final int salesTarget;
  final TeamToday teamToday;
  final List<TopSeller> topSellers;

  /// Won value to date at the end of each week of the month, then the
  /// weighted value of likely deals and of the likely ones gone quiet.
  final List<int> forecastWeeks;
  final int forecastPipeline;
  final int forecastAtRisk;
  final List<DepartmentScore> departments;
  final int staleLeads;

  /// The team holding most of [staleLeads].
  final DepartmentScore? staleLeadsTeam;
  final OverdueCustomer? overdueCustomer;

  int get targetPercent =>
      salesTarget == 0 ? 0 : (salesMonth * 100 / salesTarget).round();

  factory MoneySummary.fromJson(Map<String, dynamic> json) => MoneySummary(
    today:
        jsonObject(json['Today'], CollectionPeriod.fromJson) ??
        const CollectionPeriod(),
    month:
        jsonObject(json['Month'], CollectionPeriod.fromJson) ??
        const CollectionPeriod(),
    receivable: jsonInt(json['Receivable']) ?? 0,
    overdue: jsonInt(json['Overdue']) ?? 0,
    overdueCustomers: jsonInt(json['OverdueCustomers']) ?? 0,
    salesMonth: jsonInt(json['SalesMonth']) ?? 0,
    salesLastMonth: jsonInt(json['SalesLastMonth']) ?? 0,
    salesTarget: jsonInt(json['SalesTarget']) ?? 0,
    teamToday:
        jsonObject(json['TeamToday'], TeamToday.fromJson) ?? const TeamToday(),
    topSellers: jsonList(json['TopSellers'], TopSeller.fromJson),
    forecastWeeks: jsonInts(json['ForecastWeeks']),
    forecastPipeline: jsonInt(json['ForecastPipeline']) ?? 0,
    forecastAtRisk: jsonInt(json['ForecastAtRisk']) ?? 0,
    departments: jsonList(json['Departments'], DepartmentScore.fromJson),
    staleLeads: jsonInt(json['StaleLeads']) ?? 0,
    staleLeadsTeam: jsonObject(
      json['StaleLeadsTeam'],
      DepartmentScore.fromJson,
    ),
    overdueCustomer: jsonObject(
      json['OverdueCustomer'],
      OverdueCustomer.fromJson,
    ),
  );
}

/// Money collected in a period, split by how it came in, against the period
/// before.
class CollectionPeriod {
  const CollectionPeriod({
    this.total = 0,
    this.previous = 0,
    this.cash = 0,
    this.mobile = 0,
    this.bank = 0,
  });

  final int total;
  final int previous;
  final int cash;
  final int mobile;
  final int bank;

  int? get changePercent =>
      previous == 0 ? null : ((total - previous) * 100 / previous).round();

  factory CollectionPeriod.fromJson(Map<String, dynamic> json) =>
      CollectionPeriod(
        total: jsonInt(json['Total']) ?? 0,
        previous: jsonInt(json['Previous']) ?? 0,
        cash: jsonInt(json['Cash']) ?? 0,
        mobile: jsonInt(json['Mobile']) ?? 0,
        bank: jsonInt(json['Bank']) ?? 0,
      );
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
  final int present;
  final int headcount;

  int get absent => headcount - present;

  factory TeamToday.fromJson(Map<String, dynamic> json) => TeamToday(
    calls: jsonInt(json['Calls']) ?? 0,
    visits: jsonInt(json['Visits']) ?? 0,
    newLeads: jsonInt(json['NewLeads']) ?? 0,
    present: jsonInt(json['Present']) ?? 0,
    headcount: jsonInt(json['Headcount']) ?? 0,
  );
}

class TopSeller {
  const TopSeller({
    required this.memberId,
    required this.name,
    required this.amount,
  });

  final int memberId;
  final LocalizedName name;
  final int amount;

  factory TopSeller.fromJson(Map<String, dynamic> json) => TopSeller(
    memberId: jsonInt(json['MemberId']) ?? 0,
    name: LocalizedName.fromJson(json),
    amount: jsonInt(json['Amount']) ?? 0,
  );
}

/// A team under one team lead, named after them.
class DepartmentScore {
  const DepartmentScore({
    required this.leadId,
    required this.name,
    required this.percent,
    this.count = 0,
  });

  final int leadId;
  final LocalizedName name;
  final int percent;
  final int count;

  factory DepartmentScore.fromJson(Map<String, dynamic> json) =>
      DepartmentScore(
        leadId: jsonInt(json['LeadId']) ?? 0,
        name: LocalizedName.fromJson(json),
        percent: jsonInt(json['Percent']) ?? 0,
        count: jsonInt(json['Count']) ?? 0,
      );
}

class OverdueCustomer {
  const OverdueCustomer({
    required this.companyId,
    required this.name,
    required this.days,
    required this.amount,
    required this.ownerName,
  });

  final int companyId;
  final String name;
  final int days;
  final int amount;
  final LocalizedName ownerName;

  factory OverdueCustomer.fromJson(Map<String, dynamic> json) =>
      OverdueCustomer(
        companyId: jsonInt(json['CompanyId']) ?? 0,
        name: json['Name'] as String? ?? '',
        days: jsonInt(json['Days']) ?? 0,
        amount: jsonInt(json['Amount']) ?? 0,
        ownerName: LocalizedName(
          json['OwnerName'] as String? ?? '',
          json['OwnerNameBn'] as String? ?? '',
        ),
      );
}
