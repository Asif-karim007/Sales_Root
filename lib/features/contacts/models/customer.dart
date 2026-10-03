import 'dart:typed_data';

import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';

/// A quotation, order or invoice as the customer view lists it.
class SalesDocRef {
  const SalesDocRef({
    required this.id,
    required this.number,
    required this.amount,
    required this.on,
    this.status,
    this.paid = 0,
    this.dueOn,
    this.leadId,
  });

  final int id;
  final String number;
  final int amount;
  final DateTime on;
  final String? status;

  /// Collected so far; invoices only.
  final int paid;
  final DateTime? dueOn;
  final int? leadId;

  int get due => amount - paid;

  factory SalesDocRef.fromJson(Map<String, dynamic> json) => SalesDocRef(
    id: jsonInt(json['Id']) ?? 0,
    number: json['Number'] as String? ?? '',
    amount: jsonInt(json['Amount']) ?? 0,
    on: jsonDate(json['On']) ?? DateTime(2000),
    status: json['Status'] as String?,
    paid: jsonInt(json['Paid']) ?? 0,
    dueOn: jsonDate(json['DueOn']),
    leadId: jsonInt(json['LeadId']),
  );
}

enum CustomerEventKind {
  collection('Collection'),
  invoice('Invoice'),
  quotation('Quotation'),
  order('Order'),
  delivery('Delivery'),
  call('Call'),
  whatsApp('WhatsApp'),
  visit('Visit'),
  document('Document');

  const CustomerEventKind(this.wire);

  final String wire;

  static CustomerEventKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => CustomerEventKind.document,
  );
}

/// The Customer 360 timeline chips.
enum CustomerEventGroup { all, money, talk, visits, documents }

extension CustomerEventKindGroup on CustomerEventKind {
  CustomerEventGroup get group => switch (this) {
    CustomerEventKind.collection ||
    CustomerEventKind.invoice => CustomerEventGroup.money,
    CustomerEventKind.call ||
    CustomerEventKind.whatsApp => CustomerEventGroup.talk,
    CustomerEventKind.visit => CustomerEventGroup.visits,
    CustomerEventKind.quotation ||
    CustomerEventKind.order ||
    CustomerEventKind.delivery ||
    CustomerEventKind.document => CustomerEventGroup.documents,
  };
}

/// One entry on the customer timeline. [refId] is the quotation, order,
/// invoice or receipt it points at.
class CustomerEvent {
  const CustomerEvent({
    required this.kind,
    required this.on,
    this.number,
    this.amount,
    this.method,
    this.note,
    this.byName,
    this.refId,
    this.count,
    this.durationMinutes,
  });

  final CustomerEventKind kind;
  final DateTime on;
  final String? number;
  final int? amount;
  final String? method;
  final String? note;
  final String? byName;
  final int? refId;
  final int? count;
  final int? durationMinutes;

  factory CustomerEvent.fromJson(Map<String, dynamic> json) => CustomerEvent(
    kind: CustomerEventKind.fromWire(json['Kind'] as String?),
    on: jsonDate(json['On']) ?? DateTime(2000),
    number: json['Number'] as String?,
    amount: jsonInt(json['Amount']),
    method: json['Method'] as String?,
    note: json['Note'] as String?,
    byName: json['ByName'] as String?,
    refId: jsonInt(json['RefId']),
    count: jsonInt(json['Count']),
    durationMinutes: jsonInt(json['DurationMinutes']),
  );
}

/// Everything about one customer: money, deals, documents and touches.
class CustomerSummary {
  const CustomerSummary({
    required this.companyId,
    required this.companyName,
    required this.totalSales,
    required this.collected,
    required this.outstanding,
    required this.overdue,
    required this.openDealValue,
    required this.leads,
    required this.quotations,
    required this.orders,
    required this.invoices,
    required this.visitCount,
    required this.events,
  });

  final int companyId;
  final String companyName;

  /// Lifetime value: everything invoiced.
  final int totalSales;
  final int collected;
  final int outstanding;
  final int overdue;
  final int openDealValue;
  final List<LinkedLead> leads;
  final List<SalesDocRef> quotations;
  final List<SalesDocRef> orders;
  final List<SalesDocRef> invoices;
  final int visitCount;
  final List<CustomerEvent> events;

  List<LinkedLead> get openDeals =>
      leads.where((lead) => lead.status == LeadStatus.open).toList();

  factory CustomerSummary.fromJson(Map<String, dynamic> json) =>
      CustomerSummary(
        companyId: jsonInt(json['ProspectId']) ?? 0,
        companyName: json['ProspectName'] as String? ?? '',
        totalSales: jsonInt(json['TotalSales']) ?? 0,
        collected: jsonInt(json['Collected']) ?? 0,
        outstanding: jsonInt(json['Outstanding']) ?? 0,
        overdue: jsonInt(json['Overdue']) ?? 0,
        openDealValue: jsonInt(json['OpenDealValue']) ?? 0,
        leads: jsonList(json['Leads'], LinkedLead.fromJson),
        quotations: jsonList(json['Quotations'], SalesDocRef.fromJson),
        orders: jsonList(json['Orders'], SalesDocRef.fromJson),
        invoices: jsonList(json['Invoices'], SalesDocRef.fromJson),
        visitCount: jsonInt(json['VisitCount']) ?? 0,
        events: jsonList(json['Events'], CustomerEvent.fromJson),
      );
}

enum DocumentCategory {
  quotation('Quotation'),
  invoice('Invoice'),
  receipt('Receipt'),
  agreement('Agreement'),
  photo('Photo'),
  other('Other');

  const DocumentCategory(this.wire);

  final String wire;

  static DocumentCategory fromWire(String? value) => values.firstWhere(
    (category) => category.wire == value,
    orElse: () => DocumentCategory.other,
  );
}

class CustomerDocument {
  const CustomerDocument({
    required this.id,
    required this.title,
    required this.fileName,
    required this.category,
    required this.uploadedOn,
    this.sizeInKb,
    this.uploadedBy,
    this.source,
    this.amount,
    this.viewed = false,
    this.canDelete = false,
  });

  final int id;
  final String title;
  final String fileName;
  final DocumentCategory category;
  final DateTime uploadedOn;
  final int? sizeInKb;
  final String? uploadedBy;

  /// Where it came from: `Visit`, `Sms` or an upload.
  final String? source;
  final int? amount;
  final bool viewed;
  final bool canDelete;

  factory CustomerDocument.fromJson(Map<String, dynamic> json) =>
      CustomerDocument(
        id: jsonInt(json['Id']) ?? 0,
        title: json['Title'] as String? ?? '',
        fileName: json['FileName'] as String? ?? '',
        category: DocumentCategory.fromWire(json['Category'] as String?),
        uploadedOn: jsonDate(json['UploadedOn']) ?? DateTime(2000),
        sizeInKb: jsonInt(json['SizeInKb']),
        uploadedBy: json['UploadedBy'] as String?,
        source: json['Source'] as String?,
        amount: jsonInt(json['Amount']),
        viewed: jsonBool(json['Viewed']),
        canDelete: jsonBool(json['CanDelete']),
      );
}

/// A file the user picked, ready to upload.
class DocumentUpload {
  const DocumentUpload({
    required this.fileName,
    required this.bytes,
    required this.title,
    required this.category,
  });

  final String fileName;
  final Uint8List bytes;
  final String title;
  final DocumentCategory category;

  Map<String, dynamic> toJson() => {
    'FileName': fileName,
    'Title': title.trim(),
    'Category': category.wire,
    'SizeInKb': (bytes.length / 1024).ceil(),
  };
}
