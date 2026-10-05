import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// A company the team sells to; a customer once it has bought ([isClient]).
class Company {
  const Company({
    required this.id,
    required this.name,
    this.isClient = false,
    this.type,
    this.area,
    this.district,
    this.contactNumber,
    this.email,
    this.website,
    this.address,
    this.latitude,
    this.longitude,
    this.note,
    this.tags = const [],
    this.custom = const {},
    this.createdOn,
    this.ownerName,
    this.contactCount = 0,
    this.openLeadCount = 0,
    this.outstanding = 0,
    this.overdue = 0,
    this.creditLimit,
    this.creditDays,
  });

  final String id;
  final String name;
  final bool isClient;

  /// The workspace's own kind of company, such as `retail` or `wholesale`.
  final String? type;
  final String? area;
  final String? district;
  final String? contactNumber;
  final String? email;
  final String? website;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? note;
  final List<String> tags;

  /// Values of the workspace's company fields, by field key.
  final Map<String, dynamic> custom;
  final DateTime? createdOn;
  final String? ownerName;
  final int contactCount;
  final int openLeadCount;
  final double outstanding;
  final double overdue;
  final double? creditLimit;
  final int? creditDays;

  bool get hasLocation => latitude != null && longitude != null;

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: jsonId(json['id']) ?? '',
    name: json['name'] as String? ?? '',
    isClient: jsonBool(json['isCustomer']),
    type: _text(json['type']),
    area: _text(json['area']),
    district: _text(json['district']),
    contactNumber: _text(json['phone']),
    email: _text(json['email']),
    website: _text(json['website']),
    address: _text(json['address']),
    latitude: jsonDouble(json['lat']),
    longitude: jsonDouble(json['lng']),
    note: _text(json['notes']),
    tags: jsonStrings(json['tags']),
    custom: jsonMap(json['custom']),
    createdOn: jsonDate(json['createdAt']),
    ownerName: _text(json['ownerName']),
    contactCount: jsonInt(json['contactCount']) ?? 0,
    openLeadCount: jsonInt(json['openLeads']) ?? 0,
    outstanding: jsonDouble(json['outstanding']) ?? 0,
    overdue: jsonDouble(json['overdue']) ?? 0,
    creditLimit: jsonDouble(json['creditLimit']),
    creditDays: jsonInt(json['creditDays']),
  );
}

String? _text(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value : null;

/// The create/edit body for a company. An edit sends cleared text fields as
/// empty strings, since the server leaves a missing or null field unchanged.
class CompanyInput {
  const CompanyInput({
    required this.name,
    this.area,
    this.contactNumber,
    this.email,
    this.website,
    this.address,
    this.note,
    this.creditLimit,
    this.creditDays,
    this.custom = const {},
  });

  final String name;
  final String? area;
  final String? contactNumber;
  final String? email;
  final String? website;
  final String? address;
  final String? note;
  final double? creditLimit;
  final int? creditDays;

  /// Company field values by key; the server merges them into the saved ones.
  final Map<String, String> custom;

  Map<String, dynamic> toJson({bool edit = false}) {
    String? text(String? value) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isNotEmpty ? trimmed : (edit ? '' : null);
    }

    final fields = {
      for (final MapEntry(:key, :value) in custom.entries) key: ?text(value),
    };
    return {
      'name': name.trim(),
      'phone': text(contactNumber),
      'email': text(email),
      'website': text(website),
      'address': text(address),
      'area': text(area),
      'creditLimit': creditLimit,
      'creditDays': creditDays,
      'notes': text(note),
      'custom': fields.isEmpty ? null : fields,
    }..removeWhere((_, value) => value == null);
  }
}

class CompanyQuery {
  const CompanyQuery({
    this.search = '',
    this.customersOnly = false,
    this.page = 1,
    this.size = pageSize,
  });

  final String search;
  final bool customersOnly;
  final int page;
  final int size;

  Map<String, dynamic> toQuery() => {
    'q': search.trim().isEmpty ? null : search.trim(),
    'customersOnly': customersOnly ? true : null,
    ...pageQuery(page, size: size),
  }..removeWhere((_, value) => value == null);
}

/// A field the workspace's industry pack adds to every company, such as
/// "Outlet type" or "Route / Beat".
class CompanyField {
  const CompanyField({
    required this.key,
    required this.label,
    this.options = const [],
  });

  final String key;
  final LocalizedName label;

  /// The choices of a `select` field; empty for free text.
  final List<String> options;

  factory CompanyField.fromJson(Map<String, dynamic> json) => CompanyField(
    key: json['key'] as String? ?? '',
    label: LocalizedName.of(json),
    options: json['type'] == 'select' ? jsonStrings(json['options']) : const [],
  );
}

/// What the workspace's industry pack calls companies and contacts, and the
/// fields it adds to companies, from `settings.pack`.
class ContactsPack {
  const ContactsPack({
    this.companyTerm,
    this.contactTerm,
    this.companyFields = const [],
  });

  final LocalizedName? companyTerm;
  final LocalizedName? contactTerm;
  final List<CompanyField> companyFields;

  factory ContactsPack.fromWorkspace(Map<String, dynamic> workspace) {
    final pack = jsonMap(jsonMap(workspace['settings'])['pack']);
    final terms = jsonMap(pack['terms']);
    return ContactsPack(
      companyTerm: _term(terms['company']),
      contactTerm: _term(terms['contact']),
      companyFields: [
        for (final field in jsonList(
          pack['companyFields'],
          CompanyField.fromJson,
        ))
          if (field.key.isNotEmpty) field,
      ],
    );
  }

  static LocalizedName? _term(dynamic value) {
    final names = jsonStrings(value);
    if (names.isEmpty) return null;
    return LocalizedName(names.first, names.skip(1).firstOrNull ?? '');
  }
}
