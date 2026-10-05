import 'package:salesroot/core/utils/json_fields.dart';

enum LeadStatus {
  open('open'),
  won('won'),
  lost('lost');

  const LeadStatus(this.wire);

  final String wire;

  static LeadStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => LeadStatus.open,
  );
}

/// A lead as a contact or company shows it.
class LinkedLead {
  const LinkedLead({
    required this.id,
    required this.title,
    required this.stage,
    required this.status,
    required this.value,
  });

  final String id;
  final String title;
  final LocalizedName stage;
  final LeadStatus status;
  final double value;

  factory LinkedLead.fromJson(Map<String, dynamic> json) => LinkedLead(
    id: jsonId(json['id']) ?? '',
    title: json['title'] as String? ?? '',
    stage: LocalizedName.pair(json, 'stageName'),
    status: LeadStatus.fromWire(json['status'] as String?),
    value: jsonDouble(json['amount']) ?? 0,
  );
}

enum ActivityType {
  call('call'),
  whatsApp('whatsapp'),
  sms('sms'),
  email('email'),
  visit('visit'),
  note('note');

  const ActivityType(this.wire);

  final String wire;

  static ActivityType fromWire(String? value) => values.firstWhere(
    (type) => type.wire == value,
    orElse: () => ActivityType.note,
  );
}

/// One touch with a contact or company: a call, message, visit or note.
class ContactActivity {
  const ContactActivity({
    required this.id,
    required this.type,
    required this.on,
    this.note,
    this.byName,
    this.leadId,
    this.durationMinutes,
  });

  final String id;
  final ActivityType type;
  final DateTime on;
  final String? note;
  final String? byName;
  final String? leadId;
  final int? durationMinutes;

  factory ContactActivity.fromJson(Map<String, dynamic> json) {
    final seconds = jsonInt(json['durationSec']);
    final body = json['body'] as String?;
    return ContactActivity(
      id: jsonId(json['id']) ?? '',
      type: ActivityType.fromWire(json['type'] as String?),
      on: jsonDate(json['occurredAt']) ?? DateTime(2000),
      note: body == null || body.trim().isEmpty ? null : body,
      byName: json['byName'] as String?,
      leadId: jsonId(json['leadId']),
      durationMinutes: seconds == null || seconds <= 0
          ? null
          : (seconds / 60).ceil(),
    );
  }
}

/// An existing record a new one would duplicate.
class DuplicateMatch {
  const DuplicateMatch({
    required this.id,
    required this.name,
    this.subtitle,
    this.phone,
    this.isCompany = false,
  });

  final String id;
  final String name;
  final String? subtitle;
  final String? phone;
  final bool isCompany;
}

/// What a save came back with: the saved record, or the records it clashes
/// with when the server refused it as a duplicate.
sealed class SaveOutcome<T> {
  const SaveOutcome();
}

class Saved<T> extends SaveOutcome<T> {
  const Saved(this.value);

  final T value;
}

class Duplicates<T> extends SaveOutcome<T> {
  const Duplicates(this.matches);

  final List<DuplicateMatch> matches;
}
