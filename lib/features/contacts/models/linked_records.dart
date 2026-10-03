import 'package:salesroot/core/utils/json_fields.dart';

enum LeadStatus {
  open('Open'),
  won('Won'),
  lost('Lost');

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
    this.ownerName,
    this.updatedOn,
  });

  final int id;
  final String title;
  final LocalizedName stage;
  final LeadStatus status;
  final int value;
  final String? ownerName;
  final DateTime? updatedOn;

  factory LinkedLead.fromJson(Map<String, dynamic> json) => LinkedLead(
    id: jsonInt(json['Id']) ?? 0,
    title: json['Title'] as String? ?? '',
    stage:
        jsonObject(json['Stage'], LocalizedName.fromJson) ??
        const LocalizedName('', ''),
    status: LeadStatus.fromWire(json['Status'] as String?),
    value: jsonInt(json['Value']) ?? 0,
    ownerName: json['OwnerName'] as String?,
    updatedOn: jsonDate(json['UpdatedOn']),
  );
}

enum ActivityType {
  call('Call'),
  whatsApp('WhatsApp'),
  sms('Sms'),
  email('Email'),
  visit('Visit'),
  note('Note');

  const ActivityType(this.wire);

  final String wire;

  static ActivityType fromWire(String? value) => values.firstWhere(
    (type) => type.wire == value,
    orElse: () => ActivityType.note,
  );
}

/// One touch with a contact: a call, message, visit or note.
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

  final int id;
  final ActivityType type;
  final DateTime on;
  final String? note;
  final String? byName;
  final int? leadId;
  final int? durationMinutes;

  factory ContactActivity.fromJson(Map<String, dynamic> json) =>
      ContactActivity(
        id: jsonInt(json['Id']) ?? 0,
        type: ActivityType.fromWire(json['Type'] as String?),
        on: jsonDate(json['On']) ?? DateTime(2000),
        note: json['Note'] as String?,
        byName: json['ByName'] as String?,
        leadId: jsonInt(json['LeadId']),
        durationMinutes: jsonInt(json['DurationMinutes']),
      );
}

/// An existing record a new one would duplicate, from the 409 check.
class DuplicateMatch {
  const DuplicateMatch({
    required this.id,
    required this.name,
    this.subtitle,
    this.phone,
    this.isCompany = false,
  });

  final int id;
  final String name;
  final String? subtitle;
  final String? phone;
  final bool isCompany;

  factory DuplicateMatch.fromJson(Map<String, dynamic> json) => DuplicateMatch(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    subtitle: json['Subtitle'] as String?,
    phone: json['Phone'] as String?,
    isCompany: json['Kind'] == 'Company',
  );
}

/// What a save came back with: the saved record, or the records it clashes
/// with when the server answered 409.
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
