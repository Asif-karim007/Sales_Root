import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// A concern person: someone the team talks to, at a company or on their own.
class Contact {
  const Contact({
    required this.id,
    required this.name,
    this.designation,
    this.companyId,
    this.companyName,
    this.mobiles = const [],
    this.emails = const [],
    this.address,
    this.dateOfBirth,
    this.note,
    this.tags = const [],
    this.createdOn,
    this.ownerName,
  });

  final String id;
  final String name;
  final String? designation;
  final String? companyId;
  final String? companyName;
  final List<String> mobiles;
  final List<String> emails;
  final String? address;
  final DateTime? dateOfBirth;
  final String? note;
  final List<String> tags;
  final DateTime? createdOn;
  final String? ownerName;

  String? get phone => mobiles.isEmpty ? null : mobiles.first;
  String? get email => emails.isEmpty ? null : emails.first;
  bool get isIndependent => companyId == null;

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: jsonId(json['id']) ?? '',
    name: json['name'] as String? ?? '',
    designation: _text(json['designation']),
    companyId: jsonId(json['companyId']),
    companyName: _text(json['companyName']),
    mobiles: [?_text(json['phone']), ?_text(json['phone2'])],
    emails: [?_text(json['email'])],
    address: _text(json['address']),
    dateOfBirth: jsonDate(json['birthday']),
    note: _text(json['notes']),
    tags: jsonStrings(json['tags']),
    createdOn: jsonDate(json['createdAt']),
    ownerName: _text(json['ownerName']),
  );
}

String? _text(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value : null;

/// The create/edit body for a contact. An edit sends cleared text fields as
/// empty strings, since the server leaves a missing or null field unchanged.
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
  });

  final String name;
  final String? designation;
  final String? companyId;
  final List<String> mobiles;
  final List<String> emails;
  final String? address;
  final DateTime? dateOfBirth;
  final String? note;
  final List<String> tags;

  Map<String, dynamic> toJson({bool edit = false}) {
    String? text(String? value) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isNotEmpty ? trimmed : (edit ? '' : null);
    }

    final birthday = dateOfBirth;
    return {
      'name': name.trim(),
      'phone': text(mobiles.firstOrNull),
      'phone2': text(mobiles.skip(1).firstOrNull),
      'email': text(emails.firstOrNull),
      'designation': text(designation),
      'companyId': companyId,
      'address': text(address),
      'birthday': birthday == null
          ? null
          : AppDateUtils.toApiDateOnly(birthday),
      'notes': text(note),
      'tags': tags,
    }..removeWhere((_, value) => value == null);
  }
}

class ContactQuery {
  const ContactQuery({this.search = '', this.page = 1, this.size = pageSize});

  final String search;
  final int page;
  final int size;

  Map<String, dynamic> toQuery() => {
    'q': search.trim().isEmpty ? null : search.trim(),
    ...pageQuery(page, size: size),
  }..removeWhere((_, value) => value == null);
}
