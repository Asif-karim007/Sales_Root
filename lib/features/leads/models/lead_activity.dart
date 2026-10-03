import 'package:salesroot/core/utils/json_fields.dart';

/// What a timeline entry or logged activity is. The first seven can be
/// logged by hand; the rest are written by the server.
enum LeadActivityKind {
  call('Call'),
  meeting('Meeting'),
  visit('Visit'),
  note('Note'),
  whatsapp('WhatsApp'),
  sms('Sms'),
  email('Email'),
  quotation('Quotation'),
  stageChange('StageChange'),
  task('Task'),
  created('Created');

  const LeadActivityKind(this.wire);

  final String wire;

  static const List<LeadActivityKind> loggable = [
    call,
    meeting,
    visit,
    note,
    whatsapp,
    sms,
    email,
  ];

  /// Kinds that take a duration.
  bool get timed => this == call || this == meeting || this == visit;

  /// The `?type=` value of the log-activity route.
  String get query => name.toLowerCase();

  static LeadActivityKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire.toLowerCase() == value?.toLowerCase()) return kind;
    }
    return null;
  }

  static LeadActivityKind? fromQuery(String? value) {
    for (final kind in loggable) {
      if (kind.query == value?.toLowerCase()) return kind;
    }
    return null;
  }
}

enum CallOutcome {
  answered('Answered'),
  noAnswer('NoAnswer'),
  busy('Busy'),
  wrongNumber('WrongNumber');

  const CallOutcome(this.wire);

  final String wire;

  static CallOutcome? fromWire(String? value) {
    for (final outcome in values) {
      if (outcome.wire == value) return outcome;
    }
    return null;
  }
}

/// One timeline entry on a lead.
class LeadActivity {
  const LeadActivity({
    required this.id,
    required this.kind,
    this.occurredOn,
    this.description,
    this.durationMinutes,
    this.outcome,
    this.actorName,
    this.reference,
    this.amount,
    this.channel,
    this.viewed = false,
    this.stageName,
    this.photoCount = 0,
  });

  final int id;
  final LeadActivityKind kind;
  final DateTime? occurredOn;
  final String? description;
  final int? durationMinutes;
  final CallOutcome? outcome;
  final String? actorName;

  /// A quotation number or task title.
  final String? reference;
  final double? amount;

  /// How a quotation went out (WhatsApp, Email…).
  final String? channel;
  final bool viewed;

  /// The stage a stage change moved to.
  final LocalizedName? stageName;
  final int photoCount;

  factory LeadActivity.fromJson(Map<String, dynamic> json) => LeadActivity(
    id: jsonInt(json['Id']) ?? 0,
    kind:
        LeadActivityKind.fromWire(json['Kind'] as String?) ??
        LeadActivityKind.note,
    occurredOn: jsonDate(json['OccurredOn']),
    description: json['Description'] as String?,
    durationMinutes: jsonInt(json['DurationMinutes']),
    outcome: CallOutcome.fromWire(json['ActivityOutcome'] as String?),
    actorName: json['ActorName'] as String?,
    reference: json['Reference'] as String?,
    amount: jsonDouble(json['Amount']),
    channel: json['Channel'] as String?,
    viewed: jsonBool(json['Viewed']),
    stageName: jsonObject(json['Stage'], LocalizedName.fromJson),
    photoCount: jsonInt(json['PhotoCount']) ?? 0,
  );
}
