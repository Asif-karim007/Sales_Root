import 'package:collection/collection.dart';

import 'package:salesroot/core/utils/json_fields.dart';

/// Who a quotation goes to: a company with its main contact, or a lead.
class SalesCustomer {
  const SalesCustomer({
    required this.name,
    this.companyId,
    this.contactId,
    this.contactName,
    this.contactPhone,
    this.leadId,
    this.area,
  });

  final String? companyId;
  final String name;
  final String? contactId;
  final String? contactName;
  final String? contactPhone;

  /// The open lead with this customer, when there is one.
  final String? leadId;
  final String? area;

  /// A row of `GET companies`.
  factory SalesCustomer.fromCompany(Map<String, dynamic> json) => SalesCustomer(
    companyId: jsonId(json['id']),
    name: json['name'] as String? ?? '',
    contactPhone: json['phone'] as String?,
    area: json['area'] as String?,
  );

  /// `GET companies/{id}`: the company, its first contact and open lead.
  factory SalesCustomer.fromCompanyDetail(Map<String, dynamic> json) {
    final company = jsonMap(json['company']);
    final contact = jsonList(json['people'], (row) => row).firstOrNull;
    final lead = jsonList(
      json['leads'],
      (row) => row,
    ).firstWhereOrNull((row) => (row['status'] ?? 'open') == 'open');
    return SalesCustomer(
      companyId: jsonId(company['id']),
      name: company['name'] as String? ?? '',
      contactId: jsonId(contact?['id']),
      contactName: contact?['name'] as String?,
      contactPhone: contact?['phone'] as String? ?? company['phone'] as String?,
      leadId: jsonId(lead?['id']),
      area: company['area'] as String?,
    );
  }

  /// The `lead` of `GET leads/{id}`.
  factory SalesCustomer.fromLead(Map<String, dynamic> json) => SalesCustomer(
    companyId: jsonId(json['companyId']),
    name: json['companyName'] as String? ?? json['name'] as String? ?? '',
    contactId: jsonId(json['contactId']),
    contactName: json['contactName'] as String? ?? json['name'] as String?,
    contactPhone: json['phone'] as String?,
    leadId: jsonId(json['id']),
  );
}

/// The business printed at the top of quotations, bills and receipts.
class SellerProfile {
  const SellerProfile({
    required this.name,
    required this.address,
    required this.phone,
  });

  final String name;
  final String address;
  final String phone;

  /// `GET workspaces/current`.
  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile(
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );
}
