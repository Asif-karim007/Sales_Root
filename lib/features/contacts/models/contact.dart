import 'package:salesroot/core/utils/json_fields.dart';

/// Who created or owns a record.
class PersonRef {
  const PersonRef({required this.id, required this.name});

  final int id;
  final String name;

  factory PersonRef.fromJson(Map<String, dynamic> json) => PersonRef(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
  );
}

/// A concern person: someone the team talks to, at a company or on their own.
class Contact {
  const Contact({
    required this.id,
    required this.name,
    this.designation,
    this.companyId,
    this.companyName,
    this.companyIsClient = false,
    this.isPrimary = false,
    this.mobiles = const [],
    this.emails = const [],
    this.address,
    this.dateOfBirth,
    this.note,
    this.tags = const [],
    this.source,
    this.createdOn,
    this.createdBy,
    this.canEdit = false,
    this.canDelete = false,
  });

  final int id;
  final String name;
  final String? designation;
  final int? companyId;
  final String? companyName;
  final bool companyIsClient;
  final bool isPrimary;
  final List<String> mobiles;
  final List<String> emails;
  final String? address;
  final DateTime? dateOfBirth;
  final String? note;
  final List<String> tags;
  final String? source;
  final DateTime? createdOn;
  final PersonRef? createdBy;
  final bool canEdit;
  final bool canDelete;

  String? get phone => mobiles.isEmpty ? null : mobiles.first;
  String? get email => emails.isEmpty ? null : emails.first;
  bool get isIndependent => companyId == null;

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    designation: json['Designation'] as String?,
    companyId: jsonInt(json['ProspectId']),
    companyName: json['ProspectName'] as String?,
    companyIsClient: jsonBool(json['ProspectIsClient']),
    isPrimary: jsonBool(json['IsPrimary']),
    mobiles: jsonStrings(json['Mobiles']),
    emails: jsonStrings(json['Emails']),
    address: json['Address'] as String?,
    dateOfBirth: jsonDate(json['DateOfBirth']),
    note: json['Note'] as String?,
    tags: jsonStrings(json['Tags']),
    source: json['Source'] as String?,
    createdOn: jsonDate(json['CreatedOn']),
    createdBy: jsonObject(json['CreatedBy'], PersonRef.fromJson),
    canEdit: jsonBool(json['CanEdit']),
    canDelete: jsonBool(json['CanDelete']),
  );
}

/// The create/edit body for a contact. Edits are built from the fetched
/// contact so fields the form does not show survive.
class ContactInput {
  const ContactInput({
    required this.name,
    this.designation,
    this.companyId,
    this.mobiles = const [],
    this.emails = const [],
    this.address,
    this.dateOfBirth,
    this.note,
    this.tags = const [],
    this.source,
  });

  final String name;
  final String? designation;
  final int? companyId;
  final List<String> mobiles;
  final List<String> emails;
  final String? address;
  final DateTime? dateOfBirth;
  final String? note;
  final List<String> tags;
  final String? source;

  factory ContactInput.fromContact(Contact contact) => ContactInput(
    name: contact.name,
    designation: contact.designation,
    companyId: contact.companyId,
    mobiles: contact.mobiles,
    emails: contact.emails,
    address: contact.address,
    dateOfBirth: contact.dateOfBirth,
    note: contact.note,
    tags: contact.tags,
    source: contact.source,
  );

  Map<String, dynamic> toJson() => {
    'Name': name.trim(),
    'Designation': _blank(designation),
    'ProspectId': companyId,
    'Mobiles': mobiles,
    'Emails': emails,
    'Address': _blank(address),
    'DateOfBirth': jsonUtc(dateOfBirth),
    'Note': _blank(note),
    'Tags': tags,
    'Source': _blank(source),
  }..removeWhere((_, value) => value == null);
}

String? _blank(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// The contact list's group chips.
enum ContactGroup {
  all('All'),
  primary('Primary'),
  independent('Independent'),
  recent('Recent');

  const ContactGroup(this.wire);

  final String wire;
}

class ContactQuery {
  const ContactQuery({
    this.search = '',
    this.group = ContactGroup.all,
    this.letter,
    this.page = 1,
  });

  final String search;
  final ContactGroup group;

  /// First letter of the name, `#` for anything that is not A–Z.
  final String? letter;
  final int page;

  ContactQuery atPage(int page) =>
      ContactQuery(search: search, group: group, letter: letter, page: page);

  Map<String, dynamic> toQuery() => {
    'Search': search.trim().isEmpty ? null : search.trim(),
    'Group': group.wire,
    'Letter': letter,
    'Page': page,
    'PageSize': 20,
  }..removeWhere((_, value) => value == null);
}
