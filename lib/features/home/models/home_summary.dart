import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/home/models/money_summary.dart';
import 'package:salesroot/features/home/models/team_summary.dart';

/// Everything the home screens show, scoped by the server to the caller's
/// role: their own work for members, their team for team leads, the whole
/// workspace (with money) for owners and managers.
class HomeSummary {
  const HomeSummary({
    required this.isNew,
    this.onboarding = const OnboardingSteps(),
    this.callsToday = 0,
    this.callsYesterday = 0,
    this.followUpsDue = 0,
    this.followUpsOverdue = 0,
    this.visitsToday = 0,
    this.openLeads = 0,
    this.agenda = const [],
    this.openDealsValue = 0,
    this.targetPercent = 0,
    this.pipeline = const [],
    this.quotations = const [],
    this.meetingRate = 0,
    this.teamMeetingRate = 0,
    this.team,
    this.money,
  });

  /// No leads yet: the new-user home with the first-steps checklist.
  final bool isNew;
  final OnboardingSteps onboarding;
  final int callsToday;
  final int callsYesterday;
  final int followUpsDue;
  final int followUpsOverdue;
  final int visitsToday;
  final int openLeads;
  final List<AgendaItem> agenda;
  final int openDealsValue;
  final int targetPercent;
  final List<StageCount> pipeline;
  final List<AwaitingQuotation> quotations;

  /// Calls that became a meeting this week, in percent.
  final int meetingRate;
  final int teamMeetingRate;
  final TeamSummary? team;
  final MoneySummary? money;

  factory HomeSummary.fromJson(Map<String, dynamic> json) => HomeSummary(
    isNew: jsonBool(json['IsNewWorkspace']),
    onboarding:
        jsonObject(json['Onboarding'], OnboardingSteps.fromJson) ??
        const OnboardingSteps(),
    callsToday: jsonInt(json['CallsToday']) ?? 0,
    callsYesterday: jsonInt(json['CallsYesterday']) ?? 0,
    followUpsDue: jsonInt(json['FollowUpsDue']) ?? 0,
    followUpsOverdue: jsonInt(json['FollowUpsOverdue']) ?? 0,
    visitsToday: jsonInt(json['VisitsToday']) ?? 0,
    openLeads: jsonInt(json['OpenLeads']) ?? 0,
    agenda: jsonList(json['Agenda'], AgendaItem.fromJson),
    openDealsValue: jsonInt(json['OpenDealsValue']) ?? 0,
    targetPercent: jsonInt(json['TargetPercent']) ?? 0,
    pipeline: jsonList(json['Pipeline'], StageCount.fromJson),
    quotations: jsonList(
      json['QuotationsAwaiting'],
      AwaitingQuotation.fromJson,
    ),
    meetingRate: jsonInt(json['MeetingRate']) ?? 0,
    teamMeetingRate: jsonInt(json['TeamMeetingRate']) ?? 0,
    team: jsonObject(json['Team'], TeamSummary.fromJson),
    money: jsonObject(json['Money'], MoneySummary.fromJson),
  );
}

/// The new-user checklist; opening the account is always done.
class OnboardingSteps {
  const OnboardingSteps({
    this.leadAdded = false,
    this.callLogged = false,
    this.followUpSet = false,
    this.cardScanned = false,
  });

  final bool leadAdded;
  final bool callLogged;
  final bool followUpSet;
  final bool cardScanned;

  int get done =>
      1 +
      [leadAdded, callLogged, followUpSet, cardScanned].where((d) => d).length;

  static const int total = 5;

  factory OnboardingSteps.fromJson(Map<String, dynamic> json) =>
      OnboardingSteps(
        leadAdded: jsonBool(json['LeadAdded']),
        callLogged: jsonBool(json['CallLogged']),
        followUpSet: jsonBool(json['FollowUpSet']),
        cardScanned: jsonBool(json['CardScanned']),
      );
}

enum AgendaKind {
  call('Call'),
  visit('Visit'),
  followUp('FollowUp'),
  whatsApp('WhatsApp'),
  meeting('Meeting'),
  task('Task');

  const AgendaKind(this.wire);

  final String wire;

  static AgendaKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => AgendaKind.task,
  );
}

/// One row of today's plan. Rows tied to a lead open the lead; the rest open
/// their task.
class AgendaItem {
  const AgendaItem({
    required this.taskId,
    required this.kind,
    required this.title,
    this.leadId,
    this.dueAt,
    this.note,
    this.area,
    this.stage,
    this.stageId,
    this.isOverdue = false,
    this.isNew = false,
    this.daysSilent = 0,
  });

  final int taskId;
  final AgendaKind kind;
  final String title;
  final int? leadId;
  final DateTime? dueAt;
  final String? note;
  final LocalizedName? area;
  final LocalizedName? stage;
  final int? stageId;
  final bool isOverdue;
  final bool isNew;

  /// Days since anyone last spoke to the lead.
  final int daysSilent;

  factory AgendaItem.fromJson(Map<String, dynamic> json) => AgendaItem(
    taskId: jsonInt(json['TaskId']) ?? 0,
    kind: AgendaKind.fromWire(json['Kind'] as String?),
    title: json['Title'] as String? ?? '',
    leadId: jsonInt(json['LeadId']),
    dueAt: jsonDate(json['DueAt']),
    note: json['Note'] as String?,
    area: jsonObject(json['Area'], LocalizedName.fromJson),
    stage: jsonObject(json['Stage'], LocalizedName.fromJson),
    stageId: jsonInt(json['StageId']),
    isOverdue: jsonBool(json['IsOverdue']),
    isNew: jsonBool(json['IsNew']),
    daysSilent: jsonInt(json['DaysSilent']) ?? 0,
  );
}

class StageCount {
  const StageCount({
    required this.stageId,
    required this.name,
    required this.count,
    required this.value,
  });

  final int stageId;
  final LocalizedName name;
  final int count;
  final int value;

  factory StageCount.fromJson(Map<String, dynamic> json) => StageCount(
    stageId: jsonInt(json['StageId']) ?? 0,
    name: LocalizedName.fromJson(json),
    count: jsonInt(json['Count']) ?? 0,
    value: jsonInt(json['Value']) ?? 0,
  );
}

class AwaitingQuotation {
  const AwaitingQuotation({
    required this.id,
    required this.leadId,
    required this.companyName,
    required this.amount,
    required this.sentDaysAgo,
    required this.viewed,
  });

  final int id;
  final int leadId;
  final String companyName;
  final int amount;
  final int sentDaysAgo;
  final bool viewed;

  /// Seen but unanswered for two days or more: time to chase.
  bool get needsFollowUp => viewed && sentDaysAgo >= 2;

  factory AwaitingQuotation.fromJson(Map<String, dynamic> json) =>
      AwaitingQuotation(
        id: jsonInt(json['Id']) ?? 0,
        leadId: jsonInt(json['LeadId']) ?? 0,
        companyName: json['CompanyName'] as String? ?? '',
        amount: jsonInt(json['Amount']) ?? 0,
        sentDaysAgo: jsonInt(json['SentDaysAgo']) ?? 0,
        viewed: jsonBool(json['Viewed']),
      );
}
