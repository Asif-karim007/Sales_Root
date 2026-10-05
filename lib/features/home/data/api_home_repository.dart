import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/home/data/home_api.dart';
import 'package:salesroot/features/home/data/home_repository.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/home_variant.dart';
import 'package:salesroot/features/home/models/money_summary.dart';
import 'package:salesroot/features/home/models/team_summary.dart';

class ApiHomeRepository implements HomeRepository {
  ApiHomeRepository(this._api);

  final HomeApi _api;

  static const _thisMonth = {'preset': 'this_month'};
  static const _byMonth = {'preset': 'last_90', 'group': 'month'};

  @override
  Future<HomeSummary> summary(HomeVariant layout) async {
    final home = jsonMap(await apiRequest('Home', _api.home));
    final summary = HomeSummary.fromJson(home);
    if (summary.isNew) return summary;
    final now = jsonDate(home['serverTime']);
    return switch (layout) {
      HomeVariant.newUser => summary,
      HomeVariant.easy => _easy(summary),
      HomeVariant.standard => _standard(summary, now),
      HomeVariant.teamLead => _teamLead(summary, now),
      HomeVariant.manager => _manager(summary, now),
      HomeVariant.owner => _owner(summary, now),
    };
  }

  Future<HomeSummary> _easy(HomeSummary summary) async {
    final week = await _optional(
      'My week',
      () => _api.myReport({'preset': 'last_7'}),
    );
    return summary.copyWith(week: jsonObject(week, MyWeek.fromJson));
  }

  Future<HomeSummary> _standard(HomeSummary summary, DateTime? now) async {
    final [pipeline, target, quotes] = await Future.wait([
      _optional('Pipeline', _api.pipeline),
      _optional('Sales target', () => _api.targetReport(_thisMonth)),
      _optional(
        'Quotations awaiting',
        () => _api.quotes({'status': 'sent', 'limit': 3}),
      ),
    ]);
    return summary.copyWith(
      pipeline: StageCount.listFromJson(pipeline),
      target: jsonObject(target, SalesTarget.fromJson),
      quotations: jsonList(
        jsonMap(quotes)['items'],
        (row) => AwaitingQuotation.fromJson(row, now: now),
      ),
    );
  }

  Future<HomeSummary> _teamLead(HomeSummary summary, DateTime? now) async {
    final [activity, attendance, target, day] = await Future.wait([
      _optional(
        'Team activity',
        () => _api.activityReport({'preset': 'today'}),
      ),
      _optional('Attendance', _api.attendance),
      _optional('Team target', () => _api.targetReport(_thisMonth)),
      _optional('Day summary', () => _api.dailySummary(_day(now))),
    ]);
    final report = jsonMap(activity);
    final totals = jsonMap(report['summary']);
    final calls = {
      for (final row in jsonList(
        jsonMap(report['breakdowns'])['byPerson'],
        (row) => row,
      ))
        jsonId(row['id']): jsonInt(row['calls']) ?? 0,
    };
    return summary.copyWith(
      team: TeamSummary(
        activityToday:
            (jsonInt(totals['calls']) ?? 0) + (jsonInt(totals['visits']) ?? 0),
        noFollowUp: summary.sleepingLeads,
        targetPercent: jsonObject(target, SalesTarget.fromJson)?.percent,
        members: jsonList(
          attendance,
          (row) => MemberToday.fromJson(
            row,
            calls: calls[jsonId(row['membershipId'])] ?? 0,
          ),
        ),
        approvalsCount: _dayNumbers(day).pendingApprovals,
      ),
    );
  }

  Future<HomeSummary> _manager(HomeSummary summary, DateTime? now) async {
    final [
      target,
      lastMonth,
      collection,
      dues,
      weeks,
      pipeline,
      day,
      people,
    ] = await Future.wait([
      _optional('Sales target', () => _api.targetReport(_thisMonth)),
      _optional(
        'Sales last month',
        () => _api.targetReport({'preset': 'last_month'}),
      ),
      _optional('Collection by month', () => _api.collectionReport(_byMonth)),
      _optional('Overdue dues', () => _api.dues({'bucket': 'overdue'})),
      _optional(
        'Sales by week',
        () => _api.salesReport({'preset': 'this_month', 'group': 'week'}),
      ),
      _optional('Pipeline', _api.pipeline),
      _optional('Day summary', () => _api.dailySummary(_day(now))),
      _optional('Targets', _api.targets),
    ]);
    final sales = jsonObject(target, SalesTarget.fromJson);
    final totals = jsonMap(jsonMap(collection)['summary']);
    final overdue = jsonList(jsonMap(dues)['items'], OverdueCustomer.fromJson);
    final open = StageCount.listFromJson(pipeline).where((s) => !s.isWon);
    return summary.copyWith(
      money: MoneySummary(
        month: CollectionPeriod.fromJson(jsonMap(collection)),
        receivable: jsonDouble(totals['outstanding']) ?? 0,
        overdue: jsonDouble(totals['overdue']) ?? 0,
        overdueCustomers:
            jsonInt(jsonMap(dues)['total']) ??
            overdue.where((d) => d.amount > 0).length,
        overdueCustomer: OverdueCustomer.worst(overdue),
        salesMonth: sales?.actual ?? 0,
        salesLastMonth: jsonObject(lastMonth, SalesTarget.fromJson)?.actual,
        salesTarget: sales?.target ?? 0,
        teamToday: TeamToday.from(_dayNumbers(day)),
        forecastWeeks: _wonToDate(jsonMap(weeks)),
        forecastPipeline: open.fold<double>(0, (sum, s) => sum + s.weighted),
        departments: DepartmentScore.of(
          _people(people),
          sales?.people ?? const [],
        ),
        staleLeads: summary.sleepingLeads,
      ),
    );
  }

  Future<HomeSummary> _owner(HomeSummary summary, DateTime? now) async {
    final [days, months, target, day, people] = await Future.wait([
      _optional(
        'Collection by day',
        () => _api.collectionReport({'preset': 'last_7', 'group': 'day'}),
      ),
      _optional('Collection by month', () => _api.collectionReport(_byMonth)),
      _optional('Sales target', () => _api.targetReport(_thisMonth)),
      _optional('Day summary', () => _api.dailySummary(_day(now))),
      _optional('Targets', _api.targets),
    ]);
    final sales = jsonObject(target, SalesTarget.fromJson);
    final totals = jsonMap(jsonMap(months)['summary']);
    return summary.copyWith(
      money: MoneySummary(
        today: CollectionPeriod.fromJson(jsonMap(days)),
        month: CollectionPeriod.fromJson(jsonMap(months)),
        receivable: jsonDouble(totals['outstanding']) ?? 0,
        overdue: jsonDouble(totals['overdue']) ?? 0,
        salesMonth: sales?.actual ?? 0,
        salesTarget: sales?.target ?? 0,
        teamToday: TeamToday.from(_dayNumbers(day)),
        topSellers: TopSeller.top(_people(people)),
      ),
    );
  }

  /// A report the role may not see is left out instead of failing the home.
  Future<dynamic> _optional(
    String label,
    Future<dynamic> Function() request,
  ) async {
    try {
      return await apiRequest(label, request);
    } on ApiFailure catch (failure) {
      if (failure.isForbidden || failure.isNotFound) return null;
      rethrow;
    }
  }

  /// The day the server calls today; its clock, not the device's.
  Map<String, dynamic> _day(DateTime? now) => {
    if (now != null) 'day': AppDateUtils.toApiDateOnly(now),
  };

  DayNumbers _dayNumbers(dynamic json) =>
      jsonObject(json, DayNumbers.fromJson) ?? const DayNumbers();

  List<TopSeller> _people(dynamic json) =>
      jsonList(jsonMap(json)['people'], TopSeller.fromJson);

  /// Won value to date at the end of each week of a weekly sales report.
  List<double> _wonToDate(Map<String, dynamic> report) {
    var total = 0.0;
    return [
      for (final week in jsonList(report['trend'], (row) => row))
        total += jsonDouble(week['wonAmount']) ?? 0,
    ];
  }
}
