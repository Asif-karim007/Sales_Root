import 'package:salesroot/core/utils/json_fields.dart';

/// A server-defined choice with a label in both languages: a source, tag,
/// interest, lost reason or owner.
class LeadOption {
  const LeadOption({required this.id, required this.name, this.subtitle});

  final int id;
  final LocalizedName name;
  final String? subtitle;

  factory LeadOption.fromJson(Map<String, dynamic> json) => LeadOption(
    id: jsonInt(json['Id']) ?? 0,
    name: LocalizedName.fromJson(json),
    subtitle: json['Subtitle'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name.en,
    'NameBn': name.bn,
  };
}

class LeadLookupCompany {
  const LeadLookupCompany({
    required this.id,
    required this.name,
    this.industry,
    this.area,
  });

  final int id;
  final String name;
  final String? industry;
  final LocalizedName? area;

  factory LeadLookupCompany.fromJson(Map<String, dynamic> json) =>
      LeadLookupCompany(
        id: jsonInt(json['Id']) ?? 0,
        name: json['Name'] as String? ?? '',
        industry: json['Industry'] as String?,
        area: jsonObject(json['Area'], LocalizedName.fromJson),
      );
}

class LeadLookupContact {
  const LeadLookupContact({
    required this.id,
    required this.companyId,
    required this.name,
    this.designation,
    this.mobile,
    this.email,
  });

  final int id;
  final int companyId;
  final String name;
  final String? designation;
  final String? mobile;
  final String? email;

  factory LeadLookupContact.fromJson(Map<String, dynamic> json) =>
      LeadLookupContact(
        id: jsonInt(json['Id']) ?? 0,
        companyId: jsonInt(json['CompanyId']) ?? 0,
        name: json['Name'] as String? ?? '',
        designation: json['Designation'] as String?,
        mobile: json['Mobile'] as String?,
        email: json['Email'] as String?,
      );
}

/// Every option list the lead screens need, fetched once.
class LeadLookups {
  const LeadLookups({
    this.currentEmployeeId,
    this.owners = const [],
    this.companies = const [],
    this.contacts = const [],
    this.sources = const [],
    this.tags = const [],
    this.interests = const [],
    this.lostReasons = const [],
  });

  final int? currentEmployeeId;
  final List<LeadOption> owners;
  final List<LeadLookupCompany> companies;
  final List<LeadLookupContact> contacts;
  final List<LeadOption> sources;
  final List<LeadOption> tags;
  final List<LeadOption> interests;
  final List<LeadOption> lostReasons;

  List<LeadLookupContact> contactsOf(int? companyId) =>
      contacts.where((c) => c.companyId == companyId).toList();

  LeadLookupCompany? company(int? id) {
    for (final company in companies) {
      if (company.id == id) return company;
    }
    return null;
  }

  LeadLookupContact? contact(int? id) {
    for (final contact in contacts) {
      if (contact.id == id) return contact;
    }
    return null;
  }

  LeadLookupCompany? companyNamed(String? name) {
    final key = name?.trim().toLowerCase() ?? '';
    if (key.isEmpty) return null;
    for (final company in companies) {
      if (company.name.toLowerCase() == key) return company;
    }
    return null;
  }

  /// The source whose English or Bangla label is [label].
  LeadOption? sourceNamed(String? label) {
    final key = label?.trim().toLowerCase() ?? '';
    if (key.isEmpty) return null;
    for (final source in sources) {
      if (source.name.en.toLowerCase() == key ||
          source.name.bn.toLowerCase() == key) {
        return source;
      }
    }
    return null;
  }

  factory LeadLookups.fromJson(Map<String, dynamic> json) => LeadLookups(
    currentEmployeeId: jsonInt(json['CurrentEmployeeId']),
    owners: jsonList(json['Owners'], LeadOption.fromJson),
    companies: jsonList(json['Companies'], LeadLookupCompany.fromJson),
    contacts: jsonList(json['Contacts'], LeadLookupContact.fromJson),
    sources: jsonList(json['Sources'], LeadOption.fromJson),
    tags: jsonList(json['Tags'], LeadOption.fromJson),
    interests: jsonList(json['Interests'], LeadOption.fromJson),
    lostReasons: jsonList(json['LostReasons'], LeadOption.fromJson),
  );
}
