import 'package:salesroot/core/utils/json_fields.dart';

/// What a timeline entry or logged activity is. The first six can be logged
/// by hand; the rest are written by the server.
enum LeadActivityKind {
  call('call'),
  visit('visit'),
  note('note'),
  whatsapp('whatsapp'),
  sms('sms'),
  email('email'),
  task('task'),
  stageChange('stage'),
  won('won'),
  lost('lost'),
  system('system');

  const LeadActivityKind(this.wire);

  final String wire;

  static const List<LeadActivityKind> loggable = [
    call,
    visit,
    note,
    whatsapp,
    sms,
    email,
  ];

  /// Kinds that take a duration.
  bool get timed => this == call || this == visit;

  /// The `?type=` value of the log-activity route.
  String get query => name.toLowerCase();

  static LeadActivityKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wire == value?.toLowerCase()) return kind;
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
  answered('talked'),
  noAnswer('no_answer'),
  busy('busy'),
  switchedOff('switched_off'),
  callback('callback'),
  wrongNumber('wrong_number');

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
    this.durationSeconds,
    this.outcome,
    this.lostReason,
    this.amount,
    this.stageName,
  });

  final String id;
  final LeadActivityKind kind;
  final DateTime? occurredOn;
  final String? description;
  final int? durationSeconds;
  final CallOutcome? outcome;

  /// The lost-reason key of a Lost entry.
  final String? lostReason;

  /// What a Won entry was won for.
  final double? amount;

  /// The stage a stage change moved to.
  final LocalizedName? stageName;

  int? get durationMinutes {
    final seconds = durationSeconds;
    return seconds == null || seconds == 0 ? null : (seconds / 60).ceil();
  }

  factory LeadActivity.fromJson(Map<String, dynamic> json) {
    final kind =
        LeadActivityKind.fromWire(json['type'] as String?) ??
        LeadActivityKind.system;
    final body = json['body'] as String?;
    final meta = jsonMap(json['meta']);
    final outcome = json['outcome'] as String?;
    return LeadActivity(
      id: jsonId(json['id']) ?? '',
      kind: kind,
      occurredOn: jsonDate(json['occurredAt']),
      description: kind == LeadActivityKind.stageChange ? null : body,
      durationSeconds: jsonInt(json['durationSec']),
      outcome: CallOutcome.fromWire(outcome),
      lostReason: kind == LeadActivityKind.lost ? outcome : null,
      amount: jsonDouble(meta['Amount'] ?? meta['amount']),
      stageName: kind == LeadActivityKind.stageChange
          ? _stageName(body ?? '')
          : null,
    );
  }

  /// The server writes the stage as "Visited / ভিজিট হয়েছে".
  static LocalizedName _stageName(String body) {
    final split = body.indexOf(' / ');
    if (split < 0) return LocalizedName(body, '');
    return LocalizedName(
      body.substring(0, split).trim(),
      body.substring(split + 3).trim(),
    );
  }
}
