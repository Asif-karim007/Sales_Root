import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/contacts/models/contact.dart';

class CompanyAddress {
  const CompanyAddress({this.type = 'Present', this.address, this.zipCode});

  final String type;
  final String? address;
  final String? zipCode;

  factory CompanyAddress.fromJson(Map<String, dynamic> json) => CompanyAddress(
    type: json['Type'] as String? ?? 'Present',
    address: json['Address'] as String?,
    zipCode: json['ZipCode'] as String?,
  );

  Map<String, dynamic> toJson() =>
      {'Type': type, 'Address': address, 'ZipCode': zipCode}
        ..removeWhere((_, value) => value == null);
}

/// The primary contact as the company list shows it.
class ContactSummary {
  const ContactSummary({
    required this.id,
    required this.name,
    this.designation,
    this.mobile,
  });

  final int id;
  final String name;
  final String? designation;
  final String? mobile;

  factory ContactSummary.fromJson(Map<String, dynamic> json) => ContactSummary(
    id: jsonInt(json['Id']) ?? 0,
    name: json['Name'] as String? ?? '',
    designation: json['Designation'] as String?,
    mobile: json['Mobile'] as String?,
  );
}

/// A company the team sells to, a SaleBee "prospect"; a customer once it has
/// bought ([isClient]).
class Company {
  const Company({
    required this.id,
    required this.name,
    this.code,
    this.isClient = false,
    this.clientSince,
    this.industryType,
    this.industryTypeBn,
    this.zoneName,
    this.zoneNameBn,
    this.contactNumber,
    this.email,
    this.websiteProspect,
    this.latitude,
    this.longitude,
    this.addresses = const [],
    this.note,
    this.tags = const [],
    this.createdOn,
    this.assignedTo,
    this.primaryContact,
    this.contactCount = 0,
    this.leadCount = 0,
    this.openLeadCount = 0,
    this.totalSales = 0,
    this.outstanding = 0,
    this.creditLimit,
    this.creditDays,
    this.canEdit = false,
    this.canDelete = false,
  });

  final int id;
  final String name;
  final String? code;
  final bool isClient;
  final DateTime? clientSince;
  final String? industryType;
  final String? industryTypeBn;
  final String? zoneName;
  final String? zoneNameBn;
  final String? contactNumber;
  final String? email;
  final String? websiteProspect;
  final double? latitude;
  final double? longitude;
  final List<CompanyAddress> addresses;
  final String? note;
  final List<String> tags;
  final DateTime? createdOn;
  final PersonRef? assignedTo;
  final ContactSummary? primaryContact;
  final int contactCount;
  final int leadCount;
  final int openLeadCount;
  final int totalSales;
  final int outstanding;
  final int? creditLimit;
  final int? creditDays;
  final bool canEdit;
  final bool canDelete;

  String? area(bool bangla) =>
      bangla && (zoneNameBn?.isNotEmpty ?? false) ? zoneNameBn : zoneName;

  String? industry(bool bangla) =>
      bangla && (industryTypeBn?.isNotEmpty ?? false)
      ? industryTypeBn
      : industryType;

  String? get address {
    for (final entry in addresses) {
      final text = entry.address?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  bool get hasLocation => latitude != null && longitude != null;

  factory Company.fromJson(Map<String, dynamic> json) {
    final counts = json['Counts'];
    final countMap = counts is Map<String, dynamic>
        ? counts
        : const <String, dynamic>{};
    return Company(
      id: jsonInt(json['Id']) ?? 0,
      name: json['Name'] as String? ?? '',
      code: json['Code'] as String?,
      isClient: jsonBool(json['IsClient']),
      clientSince: jsonDate(json['ClientSince']),
      industryType: json['IndustryType'] as String?,
      industryTypeBn: json['IndustryTypeBn'] as String?,
      zoneName: json['ZoneName'] as String?,
      zoneNameBn: json['ZoneNameBn'] as String?,
      contactNumber: json['ContactNumber'] as String?,
      email: json['Email'] as String?,
      websiteProspect: json['WebsiteProspect'] as String?,
      latitude: jsonDouble(json['Latitude']),
      longitude: jsonDouble(json['Longitude']),
      addresses: jsonList(json['Addresses'], CompanyAddress.fromJson),
      note: json['Note'] as String?,
      tags: jsonStrings(json['Tags']),
      createdOn: jsonDate(json['CreatedOn']),
      assignedTo: jsonObject(json['AssignedTo'], PersonRef.fromJson),
      primaryContact: jsonObject(
        json['PrimaryContact'],
        ContactSummary.fromJson,
      ),
      contactCount: jsonInt(json['ContactCount']) ?? 0,
      leadCount: jsonInt(countMap['Leads']) ?? 0,
      openLeadCount: jsonInt(countMap['OpenLeads']) ?? 0,
      totalSales: jsonInt(json['TotalSales']) ?? 0,
      outstanding: jsonInt(json['Outstanding']) ?? 0,
      creditLimit: jsonInt(json['CreditLimit']),
      creditDays: jsonInt(json['CreditDays']),
      canEdit: jsonBool(json['CanEdit']),
      canDelete: jsonBool(json['CanDelete']),
    );
  }
}

/// The create/edit body for a company, built from the fetched company on
/// edit so fields the form does not show survive.
class CompanyInput {
  const CompanyInput({
    required this.name,
    this.industryType,
    this.zoneName,
    this.contactNumber,
    this.email,
    this.websiteProspect,
    this.address,
    this.latitude,
    this.longitude,
    this.note,
    this.tags = const [],
    this.creditLimit,
    this.creditDays,
  });

  final String name;
  final String? industryType;
  final String? zoneName;
  final String? contactNumber;
  final String? email;
  final String? websiteProspect;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? note;
  final List<String> tags;
  final int? creditLimit;
  final int? creditDays;

  factory CompanyInput.fromCompany(Company company) => CompanyInput(
    name: company.name,
    industryType: company.industryType,
    zoneName: company.zoneName,
    contactNumber: company.contactNumber,
    email: company.email,
    websiteProspect: company.websiteProspect,
    address: company.address,
    latitude: company.latitude,
    longitude: company.longitude,
    note: company.note,
    tags: company.tags,
    creditLimit: company.creditLimit,
    creditDays: company.creditDays,
  );

  Map<String, dynamic> toJson() {
    final address = _blank(this.address);
    return {
      'Name': name.trim(),
      'IndustryType': _blank(industryType),
      'ZoneName': _blank(zoneName),
      'ContactNumber': _blank(contactNumber),
      'Email': _blank(email),
      'WebsiteProspect': _blank(websiteProspect),
      'Addresses': address == null
          ? null
          : [CompanyAddress(address: address).toJson()],
      'Latitude': latitude,
      'Longitude': longitude,
      'Note': _blank(note),
      'Tags': tags,
      'CreditLimit': creditLimit,
      'CreditDays': creditDays,
    }..removeWhere((_, value) => value == null);
  }
}

String? _blank(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

class CompanyQuery {
  const CompanyQuery({
    this.search = '',
    this.customersOnly = false,
    this.industry,
    this.area,
    this.page = 1,
  });

  final String search;
  final bool customersOnly;
  final String? industry;
  final String? area;
  final int page;

  CompanyQuery atPage(int page) => CompanyQuery(
    search: search,
    customersOnly: customersOnly,
    industry: industry,
    area: area,
    page: page,
  );

  Map<String, dynamic> toQuery() => {
    'Search': search.trim().isEmpty ? null : search.trim(),
    'IsClient': customersOnly ? true : null,
    'IndustryType': industry,
    'ZoneName': area,
    'Page': page,
    'PageSize': 20,
  }..removeWhere((_, value) => value == null);
}

/// Choices for the company filters and form: industries and Dhaka areas.
class CompanyLookups {
  const CompanyLookups({required this.industries, required this.areas});

  final List<LocalizedName> industries;
  final List<LocalizedName> areas;

  factory CompanyLookups.fromJson(Map<String, dynamic> json) => CompanyLookups(
    industries: jsonList(json['Industries'], LocalizedName.fromJson),
    areas: jsonList(json['Zones'], LocalizedName.fromJson),
  );
}
