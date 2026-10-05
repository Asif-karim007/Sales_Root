import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/home/models/money_summary.dart';
import 'package:salesroot/features/home/models/team_summary.dart';

/// Everything the home screens show. `GET home` gives the counts and today's
/// plan; each role's home adds the reports it needs, scoped by the server to
/// the caller: their own work for members, their team for team leads, the
/// whole workspace for owners.
class HomeSummary {
  const HomeSummary({
    required this.isNew,
    this.followUpsDue = 0,
    this.followUpsOverdue = 0,
    this.visitsToday = 0,
    this.openLeads = 0,
    this.sleepingLeads = 0,
    this.agenda = const [],
    this.week,
    this.pipeline = const [],
    this.target,
    this.quotations = const [],
    this.team,
    this.money,
  });

  /// Nothing in the workspace yet: the new-user home.
  final bool isNew;
  final int followUpsDue;
  final int followUpsOverdue;
  final int visitsToday;
  final int openLeads;

  /// Open leads nobody has followed up on for a week or more.
  final int sleepingLeads;
  final List<AgendaItem> agenda;
  final MyWeek? week;

  /// The stages up to the won one, with their leads and value.
  final List<StageCount> pipeline;
  final SalesTarget? target;
  final List<AwaitingQuotation> quotations;
  final TeamSummary? team;
  final MoneySummary? money;

  OnboardingSteps get onboarding =>
      OnboardingSteps(followUpSet: followUpsDue > 0 || agenda.isNotEmpty);

  double get openDealsValue => pipeline
      .where((s) => !s.isWon)
      .fold<double>(0, (sum, stage) => sum + stage.value);

  int? get targetPercent => target?.percent;

  /// `GET home`. The workspace is new while it has no open or won leads, no
  /// new ones waiting and nothing to collect.
  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    final kpis = jsonMap(json['kpis']);
    final now = jsonDate(json['serverTime']);
    final agenda = jsonList(
      json['today'],
      (row) => AgendaItem.fromJson(row, now: now),
    );
    int count(String key) => jsonInt(kpis[key]) ?? 0;
    final isNew =
        [
          'openLeads',
          'newLeadsQueue',
          'newLeadsWeek',
          'wonMonth',
        ].every((key) => count(key) == 0) &&
        (jsonDouble(kpis['toCollect']) ?? 0) == 0;
    return HomeSummary(
      isNew: isNew,
      followUpsDue: count('followupsDue'),
      followUpsOverdue: agenda.where((a) => a.isOverdue).length,
      visitsToday: agenda
          .where((a) => a.kind == AgendaKind.visit && !a.isOverdue)
          .length,
      openLeads: count('openLeads'),
      sleepingLeads: count('sleeping'),
      agenda: agenda,
    );
  }

  HomeSummary copyWith({
    MyWeek? week,
    List<StageCount>? pipeline,
    SalesTarget? target,
    List<AwaitingQuotation>? quotations,
    TeamSummary? team,
    MoneySummary? money,
  }) => HomeSummary(
    isNew: isNew,
    followUpsDue: followUpsDue,
    followUpsOverdue: followUpsOverdue,
    visitsToday: visitsToday,
    openLeads: openLeads,
    sleepingLeads: sleepingLeads,
    agenda: agenda,
    week: week ?? this.week,
    pipeline: pipeline ?? this.pipeline,
    target: target ?? this.target,
    quotations: quotations ?? this.quotations,
    team: team ?? this.team,
    money: money ?? this.money,
  );
}

/// The new-user checklist. Opening the account is always done; with no leads
/// yet, a follow-up is the only other job that can be.
class OnboardingSteps {
  const OnboardingSteps({this.followUpSet = false});

  final bool followUpSet;

  int get done => followUpSet ? 2 : 1;

  static const int total = 5;
}

enum AgendaKind {
  call('call'),
  visit('visit'),
  followUp('followup'),
  whatsApp('whatsapp'),
  meeting('meeting'),
  collect('collect'),
  task('task');

  const AgendaKind(this.wire);

  final String wire;

  static AgendaKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value?.replaceAll('_', ''),
    orElse: () => AgendaKind.task,
  );
}

/// One row of today's plan: a task, or a lead whose follow-up is due. Rows
/// tied to a lead open the lead; the rest open their task.
class AgendaItem {
  const AgendaItem({
    required this.id,
    required this.kind,
    required this.title,
    this.leadId,
    this.dueAt,
    this.who,
    this.isOverdue = false,
  });

  final String id;
  final AgendaKind kind;
  final String title;
  final String? leadId;
  final DateTime? dueAt;

  /// The person or company the work is with.
  final String? who;

  /// Due on a day before the server's today.
  final bool isOverdue;

  factory AgendaItem.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final dueAt = jsonDate(json['dueAt']);
    return AgendaItem(
      id: jsonId(json['id']) ?? '',
      kind: json['kind'] == 'followup'
          ? AgendaKind.followUp
          : AgendaKind.fromWire(json['type'] as String?),
      title: json['title'] as String? ?? '',
      leadId: jsonId(json['leadId']),
      dueAt: dueAt,
      who: json['who'] as String?,
      isOverdue:
          now != null &&
          dueAt != null &&
          AppDateUtils.dateOnly(dueAt).isBefore(AppDateUtils.dateOnly(now)),
    );
  }
}

/// The user's last seven days, from `GET reports/me?preset=last_7`.
class MyWeek {
  const MyWeek({
    required this.callsToday,
    required this.callsYesterday,
    required this.calls,
    required this.teamCalls,
  });

  final int callsToday;
  final int callsYesterday;
  final int calls;

  /// The team's average calls per person over the same days.
  final double teamCalls;

  /// The trend's last bucket is today.
  factory MyWeek.fromJson(Map<String, dynamic> json) {
    final trend = json['trend'] is List ? json['trend'] as List : const [];
    int callsAt(int fromEnd) {
      final index = trend.length - 1 - fromEnd;
      if (index < 0) return 0;
      return jsonInt(jsonMap(trend[index])['calls']) ?? 0;
    }

    return MyWeek(
      callsToday: callsAt(0),
      callsYesterday: callsAt(1),
      calls: jsonInt(jsonMap(json['summary'])['calls']) ?? 0,
      teamCalls: jsonDouble(jsonMap(json['teamAverage'])['calls']) ?? 0,
    );
  }
}

/// One stage of `GET reports/pipeline`.
class StageCount {
  const StageCount({
    required this.stageId,
    required this.name,
    required this.count,
    required this.value,
    this.weighted = 0,
    this.isWon = false,
  });

  final String stageId;
  final LocalizedName name;
  final int count;
  final double value;

  /// [value] weighted by the stage's win probability.
  final double weighted;
  final bool isWon;

  factory StageCount.fromJson(Map<String, dynamic> json) => StageCount(
    stageId: jsonId(json['stageId']) ?? '',
    name: LocalizedName.pair(json),
    count: jsonInt(json['leads']) ?? 0,
    value: jsonDouble(json['amount']) ?? 0,
    weighted: jsonDouble(json['weighted']) ?? 0,
    isWon: jsonBool(json['isWon']),
  );

  /// The stages up to and including the first won one, leaving out lost and
  /// after-sale stages.
  static List<StageCount> listFromJson(dynamic value) {
    final rows = value is List ? value : const [];
    final stages = <StageCount>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic> || jsonBool(row['isLost'])) continue;
      final stage = StageCount.fromJson(row);
      stages.add(stage);
      if (stage.isWon) break;
    }
    return stages;
  }
}

/// Sales against target over a period, from `GET reports/targets`.
class SalesTarget {
  const SalesTarget({
    required this.actual,
    required this.target,
    this.people = const [],
  });

  final double actual;
  final double target;
  final List<PersonTarget> people;

  /// Null while no target is set.
  int? get percent => target <= 0 ? null : (actual * 100 / target).round();

  factory SalesTarget.fromJson(Map<String, dynamic> json) {
    final summary = jsonMap(json['summary']);
    return SalesTarget(
      actual: jsonDouble(summary['sales_actual']) ?? 0,
      target: jsonDouble(summary['sales_target']) ?? 0,
      people: jsonList(
        jsonMap(json['breakdowns'])['byPerson'],
        PersonTarget.fromJson,
      ),
    );
  }
}

class PersonTarget {
  const PersonTarget({
    required this.memberId,
    required this.actual,
    required this.target,
  });

  final String memberId;
  final double actual;
  final double target;

  factory PersonTarget.fromJson(Map<String, dynamic> json) => PersonTarget(
    memberId: jsonId(json['id']) ?? '',
    actual: jsonDouble(json['salesActual']) ?? 0,
    target: jsonDouble(json['salesTarget']) ?? 0,
  );
}

/// A sent quotation still waiting for the customer's answer.
class AwaitingQuotation {
  const AwaitingQuotation({
    required this.id,
    required this.companyName,
    required this.amount,
    required this.sentDaysAgo,
    this.leadId,
  });

  final String id;
  final String? leadId;
  final String companyName;
  final double amount;
  final int sentDaysAgo;

  /// Unanswered for two days or more: time to chase.
  bool get needsFollowUp => sentDaysAgo >= 2;

  /// One of `GET quotes?status=sent`; [now] is the server's time.
  factory AwaitingQuotation.fromJson(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final sentAt = jsonDate(json['sentAt']);
    final days = now == null || sentAt == null
        ? 0
        : AppDateUtils.dateOnly(
            now,
          ).difference(AppDateUtils.dateOnly(sentAt)).inDays;
    return AwaitingQuotation(
      id: jsonId(json['id']) ?? '',
      leadId: jsonId(json['leadId']),
      companyName:
          (json['companyName'] ?? json['leadName'] ?? json['number'])
              as String? ??
          '',
      amount: jsonDouble(json['total']) ?? 0,
      sentDaysAgo: days < 0 ? 0 : days,
    );
  }
}
