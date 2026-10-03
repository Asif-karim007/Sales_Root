import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

enum QuotationStatus {
  draft('Draft'),
  sent('Sent'),
  viewed('Viewed'),
  accepted('Accepted'),
  rejected('Rejected'),
  expired('Expired');

  const QuotationStatus(this.wire);

  final String wire;

  static QuotationStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => QuotationStatus.draft,
  );

  /// Sent or viewed: waiting on the customer.
  bool get isAwaiting =>
      this == QuotationStatus.sent || this == QuotationStatus.viewed;

  bool get isOpen => this == QuotationStatus.draft || isAwaiting;
}

enum SendChannel {
  whatsApp('WhatsApp'),
  sms('Sms'),
  email('Email'),
  share('Share');

  const SendChannel(this.wire);

  final String wire;

  static SendChannel? fromWire(String? value) {
    for (final channel in values) {
      if (channel.wire == value) return channel;
    }
    return null;
  }
}

/// `Q-0042`
String quotationNumber(int id) => 'Q-${id.toString().padLeft(4, '0')}';

class Quotation {
  const Quotation({
    required this.id,
    required this.number,
    required this.version,
    required this.companyId,
    required this.companyName,
    required this.contactName,
    required this.priceList,
    required this.lines,
    required this.discountBps,
    required this.vatBps,
    required this.validUntil,
    required this.paymentTerms,
    required this.deliveryDays,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.ownerName,
    this.leadId,
    this.contactId,
    this.contactPhone,
    this.sentVia,
    this.sentAt,
    this.viewCount = 0,
    this.lastViewedAt,
    this.orderId,
    this.orderNumber,
    this.canEdit = false,
    this.canDelete = false,
  });

  final int id;
  final String number;
  final int version;
  final int? leadId;
  final int companyId;
  final String companyName;
  final int? contactId;
  final String contactName;
  final String? contactPhone;
  final PriceList priceList;
  final List<SalesLine> lines;
  final int discountBps;
  final int vatBps;
  final DateTime validUntil;
  final PaymentTerms paymentTerms;
  final int deliveryDays;
  final String note;
  final QuotationStatus status;
  final SendChannel? sentVia;
  final DateTime createdAt;
  final DateTime? sentAt;
  final int viewCount;
  final DateTime? lastViewedAt;
  final int? orderId;
  final String? orderNumber;
  final String ownerName;
  final bool canEdit;
  final bool canDelete;

  SalesTotals get totals =>
      computeTotals(lines, discountBps: discountBps, vatBps: vatBps);

  factory Quotation.fromJson(Map<String, dynamic> json) => Quotation(
    id: jsonInt(json['Id']) ?? 0,
    number: json['Number'] as String? ?? '',
    version: jsonInt(json['Version']) ?? 1,
    leadId: jsonInt(json['LeadId']),
    companyId: jsonInt(json['CompanyId']) ?? 0,
    companyName: json['CompanyName'] as String? ?? '',
    contactId: jsonInt(json['ContactId']),
    contactName: json['ContactName'] as String? ?? '',
    contactPhone: json['ContactPhone'] as String?,
    priceList: PriceList.fromWire(json['PriceList'] as String?),
    lines: jsonList(json['Lines'], SalesLine.fromJson),
    discountBps: jsonInt(json['DiscountBps']) ?? 0,
    vatBps: jsonInt(json['VatBps']) ?? standardVatBps,
    validUntil: jsonDate(json['ValidUntil']) ?? DateTime(2000),
    paymentTerms: PaymentTerms.fromWire(json['PaymentTerms'] as String?),
    deliveryDays: jsonInt(json['DeliveryDays']) ?? 14,
    note: json['Note'] as String? ?? '',
    status: QuotationStatus.fromWire(json['Status'] as String?),
    sentVia: SendChannel.fromWire(json['SentVia'] as String?),
    createdAt: jsonDate(json['CreatedAt']) ?? DateTime(2000),
    sentAt: jsonDate(json['SentAt']),
    viewCount: jsonInt(json['ViewCount']) ?? 0,
    lastViewedAt: jsonDate(json['LastViewedAt']),
    orderId: jsonInt(json['OrderId']),
    orderNumber: json['OrderNumber'] as String?,
    ownerName: json['OwnerName'] as String? ?? '',
    canEdit: jsonBool(json['CanEdit']),
    canDelete: jsonBool(json['CanDelete']),
  );
}

/// The body of a create or a new version.
class QuotationInput {
  const QuotationInput({
    required this.companyId,
    required this.priceList,
    required this.lines,
    required this.discountBps,
    required this.vatBps,
    required this.validUntil,
    required this.paymentTerms,
    required this.deliveryDays,
    required this.note,
    this.leadId,
    this.contactId,
    this.revisionOf,
    this.sendVia,
  });

  final int? companyId;
  final int? leadId;
  final int? contactId;
  final PriceList priceList;
  final List<SalesLine> lines;
  final int discountBps;
  final int vatBps;
  final DateTime validUntil;
  final PaymentTerms paymentTerms;
  final int deliveryDays;
  final String note;

  /// The quotation this replaces as a new version.
  final int? revisionOf;

  /// Null saves a draft.
  final SendChannel? sendVia;

  Map<String, dynamic> toJson() => {
    'CompanyId': companyId,
    'LeadId': leadId,
    'ContactId': contactId,
    'PriceList': priceList.wire,
    'Lines': [
      for (final line in lines)
        if (line.qty > 0) line.toJson(),
    ],
    'DiscountBps': discountBps,
    'VatBps': vatBps,
    'ValidUntil': jsonUtc(validUntil),
    'PaymentTerms': paymentTerms.wire,
    'DeliveryDays': deliveryDays,
    'Note': note.trim().isEmpty ? null : note.trim(),
    'RevisionOf': revisionOf,
    'SendVia': sendVia?.wire,
  }..removeWhere((_, value) => value == null);
}

class QuotationQuery {
  const QuotationQuery({this.status, this.search = '', this.page = 1});

  final QuotationStatus? status;
  final String search;
  final int page;

  QuotationQuery atPage(int page) =>
      QuotationQuery(status: status, search: search, page: page);

  Map<String, dynamic> toQuery() => {
    'Status': status?.wire,
    'Search': search.trim().isEmpty ? null : search.trim(),
    'Page': page,
    'PageSize': 20,
  }..removeWhere((_, value) => value == null);
}
