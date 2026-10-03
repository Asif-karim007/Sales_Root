import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/product.dart';

/// A company a quotation can go to, with its main contact and price list.
class SalesCustomer {
  const SalesCustomer({
    required this.companyId,
    required this.name,
    required this.contactName,
    required this.priceList,
    this.contactId,
    this.contactPhone,
    this.leadId,
    this.area,
  });

  final int companyId;
  final String name;
  final int? contactId;
  final String contactName;
  final String? contactPhone;
  final PriceList priceList;

  /// The open lead with this customer, when there is one.
  final int? leadId;
  final String? area;

  factory SalesCustomer.fromJson(Map<String, dynamic> json) => SalesCustomer(
    companyId: jsonInt(json['CompanyId']) ?? 0,
    name: json['Name'] as String? ?? '',
    contactId: jsonInt(json['ContactId']),
    contactName: json['ContactName'] as String? ?? '',
    contactPhone: json['ContactPhone'] as String?,
    priceList: PriceList.fromWire(json['PriceList'] as String?),
    leadId: jsonInt(json['LeadId']),
    area: json['Area'] as String?,
  );
}

/// The business printed at the top of quotations, bills and receipts.
class SellerProfile {
  const SellerProfile({
    required this.name,
    required this.address,
    required this.phone,
    this.taxInvoices = false,
  });

  final String name;
  final String address;
  final String phone;

  /// Prints "Tax invoice" with the VAT registration instead of "Bill".
  final bool taxInvoices;

  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile(
    name: json['Name'] as String? ?? '',
    address: json['Address'] as String? ?? '',
    phone: json['Phone'] as String? ?? '',
    taxInvoices: jsonBool(json['TaxInvoices']),
  );
}
