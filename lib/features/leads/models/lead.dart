import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';

enum LeadTemperature {
  hot('hot'),
  warm('warm'),
  cold('cold');

  const LeadTemperature(this.wire);

  final String wire;

  static LeadTemperature? fromWire(String? value) {
    for (final temperature in values) {
      if (temperature.wire == value) return temperature;
    }
    return null;
  }
}

enum LeadStatus {
  open('open'),
  won('won'),
  lost('lost'),
  hold('hold');

  const LeadStatus(this.wire);

  final String wire;

  static LeadStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => LeadStatus.open,
  );
}

class LeadPersonRef {
  const LeadPersonRef({this.id, required this.name});

  final String? id;
  final LocalizedName name;
}

/// The company a lead is linked to.
class LeadCompany {
  const LeadCompany({required this.id, required this.name});

  final String id;
  final String name;
}

/// The contact person a lead is linked to.
class LeadContact {
  const LeadContact({required this.id, required this.name});

  final String id;
  final String name;
}

class LeadStageRef {
  const LeadStageRef({
    required this.id,
    required this.name,
    this.isWon = false,
    this.isLost = false,
  });

  final String id;
  final LocalizedName name;
  final bool isWon;
  final bool isLost;

  factory LeadStageRef.of(LeadStage stage) => LeadStageRef(
    id: stage.id,
    name: stage.name,
    isWon: stage.isWon,
    isLost: stage.isLost,
  );
}

/// An open task on the lead, from the detail response.
class LeadTask {
  const LeadTask({required this.id, this.title, this.kind, this.dueAt});

  final String id;
  final String? title;
  final LeadActivityKind? kind;
  final DateTime? dueAt;

  factory LeadTask.fromJson(Map<String, dynamic> json) => LeadTask(
    id: jsonId(json['id']) ?? '',
    title: json['title'] as String?,
    kind: LeadActivityKind.fromWire(json['type'] as String?),
    dueAt: jsonDate(json['dueAt']),
  );
}

/// One lead. List rows carry the lead alone; the detail response adds the
/// timeline, the open tasks and the latest quotation.
class Lead {
  const Lead({
    required this.id,
    this.leadName = '',
    this.title,
    this.phone,
    this.createdOn,
    this.company,
    this.contact,
    this.stage,
    this.status = LeadStatus.open,
    this.assignedTo,
    this.estimatedAmount,
    this.estimatedClosingDate,
    this.winProbability = 0,
    this.temperature,
    this.source,
    this.tags = const [],
    this.custom = const {},
    this.lostReason,
    this.lostNote,
    this.nextFollowUp,
    this.nextTask,
    this.lastQuoted,
    this.timeline = const [],
  });

  final String id;
  final String leadName;

  /// What the lead wants, such as "50 cartons soap".
  final String? title;
  final String? phone;
  final DateTime? createdOn;
  final LeadCompany? company;
  final LeadContact? contact;
  final LeadStageRef? stage;
  final LeadStatus status;
  final LeadPersonRef? assignedTo;
  final double? estimatedAmount;
  final DateTime? estimatedClosingDate;
  final int winProbability;
  final LeadTemperature? temperature;

  /// The source key, such as `manual` or `card`.
  final String? source;
  final List<String> tags;

  /// Values of the workspace's custom lead fields, by field key.
  final Map<String, dynamic> custom;

  /// The lost-reason key, while the lead is lost.
  final String? lostReason;
  final String? lostNote;
  final DateTime? nextFollowUp;

  /// The first open task, known on the detail only.
  final LeadTask? nextTask;

  /// The total of the latest quotation.
  final double? lastQuoted;
  final List<LeadActivity> timeline;

  bool get isWon => status == LeadStatus.won;
  bool get isLost => status == LeadStatus.lost;
  bool get isOpen => !isWon && !isLost;
  bool get hasNextTask => nextTaskAt != null || nextTask?.title != null;

  DateTime? get nextTaskAt => nextTask?.dueAt ?? nextFollowUp;

  bool get isOverdue {
    final at = nextTaskAt;
    return isOpen && at != null && at.isBefore(DateTime.now());
  }

  /// Days from today to the expected close; negative once it has passed.
  int? get daysToClose {
    final closing = estimatedClosingDate;
    if (closing == null) return null;
    return AppDateUtils.dateOnly(
      closing,
    ).difference(AppDateUtils.dateOnly(DateTime.now())).inDays;
  }

  String? customText(String key) {
    final value = custom[key];
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  /// The same lead in [stage], as the list shows it while the move is saved.
  Lead movedTo(LeadStage stage) => Lead(
    id: id,
    leadName: leadName,
    title: title,
    phone: phone,
    createdOn: createdOn,
    company: company,
    contact: contact,
    stage: LeadStageRef.of(stage),
    status: stage.isWon
        ? LeadStatus.won
        : stage.isLost
        ? LeadStatus.lost
        : LeadStatus.open,
    assignedTo: assignedTo,
    estimatedAmount: estimatedAmount,
    estimatedClosingDate: estimatedClosingDate,
    winProbability: stage.winProbability,
    temperature: temperature,
    source: source,
    tags: tags,
    custom: custom,
    nextFollowUp: nextFollowUp,
    nextTask: nextTask,
    lastQuoted: lastQuoted,
    timeline: timeline,
  );

  /// A list row, or the detail response `{lead, timeline, tasks, quotes}`.
  factory Lead.fromJson(Map<String, dynamic> json) {
    final row = json['lead'] is Map<String, dynamic>
        ? json['lead'] as Map<String, dynamic>
        : json;
    final status = LeadStatus.fromWire(row['status'] as String?);
    final stageId = jsonId(row['stageId']);
    final companyId = jsonId(row['companyId']);
    final contactId = jsonId(row['contactId']);
    final ownerName = row['ownerName'] as String?;
    final tasks = jsonList(
      json['tasks'],
      (task) => task,
    ).where((task) => task['status'] == 'open').map(LeadTask.fromJson).toList();
    final quotes = jsonList(json['quotes'], (quote) => quote);
    return Lead(
      id: jsonId(row['id']) ?? '',
      leadName: row['name'] as String? ?? '',
      title: row['title'] as String?,
      phone: row['phone'] as String?,
      createdOn: jsonDate(row['createdAt']),
      company: companyId == null
          ? null
          : LeadCompany(
              id: companyId,
              name: row['companyName'] as String? ?? '',
            ),
      contact: contactId == null
          ? null
          : LeadContact(
              id: contactId,
              name: row['contactName'] as String? ?? '',
            ),
      stage: stageId == null
          ? null
          : LeadStageRef(
              id: stageId,
              name: LocalizedName.pair(row, 'stageName'),
              isWon: jsonBool(row['stageIsWon']),
              isLost: status == LeadStatus.lost,
            ),
      status: status,
      assignedTo: ownerName == null
          ? null
          : LeadPersonRef(
              id: jsonId(row['ownerMembershipId']),
              name: LocalizedName(ownerName, ownerName),
            ),
      estimatedAmount: jsonDouble(row['amount']),
      estimatedClosingDate: _date(row['expectedClose']),
      winProbability: jsonInt(row['stageProbability']) ?? 0,
      temperature: LeadTemperature.fromWire(row['temperature'] as String?),
      source: row['source'] as String?,
      tags: jsonStrings(row['tags']),
      custom: jsonMap(row['custom']),
      lostReason: status == LeadStatus.lost
          ? row['lostReason'] as String?
          : null,
      lostNote: status == LeadStatus.lost ? row['lostNote'] as String? : null,
      nextFollowUp: status == LeadStatus.open
          ? jsonDate(row['nextFollowUp'])
          : null,
      nextTask: tasks.isEmpty ? null : (tasks..sort(_byDue)).first,
      lastQuoted: quotes.isEmpty ? null : jsonDouble(quotes.first['total']),
      timeline: jsonList(json['timeline'], LeadActivity.fromJson),
    );
  }

  static int _byDue(LeadTask a, LeadTask b) {
    final at = a.dueAt;
    final bt = b.dueAt;
    if (at == null) return bt == null ? 0 : 1;
    if (bt == null) return -1;
    return at.compareTo(bt);
  }

  /// A calendar date the server sends without a zone, such as
  /// `2026-10-30T00:00:00`.
  static DateTime? _date(dynamic value) {
    if (value is! String) return null;
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }
}
