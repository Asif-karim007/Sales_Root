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
    this.deliveredOn,
  });

  final String id;
  final String number;
  final double amount;
  final DateTime on;

  /// The server's status, such as `sent`, `delivered` or `partial`.
  final String? status;

  /// Collected so far; invoices only.
  final double paid;
  final DateTime? dueOn;
  final DateTime? deliveredOn;

  double get due => amount - paid;
  bool get isCancelled => status == 'cancelled';

  factory SalesDocRef.fromQuote(Map<String, dynamic> json) => SalesDocRef(
    id: jsonId(json['id']) ?? '',
    number: json['number'] as String? ?? '',
    amount: jsonDouble(json['total']) ?? 0,
    on:
        jsonDate(json['sentAt']) ??
        jsonDate(json['createdAt']) ??
        DateTime(2000),
    status: json['status'] as String?,
  );

  factory SalesDocRef.fromOrder(Map<String, dynamic> json) => SalesDocRef(
    id: jsonId(json['id']) ?? '',
    number: json['number'] as String? ?? '',
    amount: jsonDouble(json['total']) ?? 0,
    on: jsonDate(json['createdAt']) ?? DateTime(2000),
    status: json['status'] as String?,
    deliveredOn: json['status'] == 'delivered'
        ? jsonDate(json['deliveryDate'])
        : null,
  );

  factory SalesDocRef.fromInvoice(Map<String, dynamic> json) => SalesDocRef(
    id: jsonId(json['id']) ?? '',
    number: json['number'] as String? ?? '',
    amount: jsonDouble(json['total']) ?? 0,
    on:
        jsonDate(json['issueDate']) ??
        jsonDate(json['createdAt']) ??
        DateTime(2000),
    status: json['status'] as String?,
    paid: jsonDouble(json['paidAmt']) ?? 0,
    dueOn: jsonDate(json['dueDate']),
  );
}

/// A collection from the customer.
class CustomerPayment {
  const CustomerPayment({
    required this.id,
    required this.amount,
    required this.on,
    this.receiptNo,
    this.method,
    this.status,
  });

  final String id;
  final double amount;
  final DateTime on;
  final String? receiptNo;

  /// The server's method key, such as `cash` or `bkash`.
  final String? method;
  final String? status;

  bool get isCancelled => status == 'cancelled';

  factory CustomerPayment.fromJson(Map<String, dynamic> json) =>
      CustomerPayment(
        id: jsonId(json['id']) ?? '',
        amount: jsonDouble(json['amount']) ?? 0,
        on: jsonDate(json['receivedAt']) ?? DateTime(2000),
        receiptNo: json['receiptNo'] as String?,
        method: json['method'] as String?,
        status: json['status'] as String?,
      );
}

enum CustomerEventKind {
  collection,
  invoice,
  quotation,
  order,
  delivery,
  call,
  whatsApp,
  visit,
  note,
  document,
}

/// The Customer 360 timeline chips.
enum CustomerEventGroup { all, money, talk, visits, documents }

extension CustomerEventKindGroup on CustomerEventKind {
  CustomerEventGroup get group => switch (this) {
    CustomerEventKind.collection ||
    CustomerEventKind.invoice => CustomerEventGroup.money,
    CustomerEventKind.call ||
    CustomerEventKind.whatsApp ||
    CustomerEventKind.note => CustomerEventGroup.talk,
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
    this.durationMinutes,
  });

  final CustomerEventKind kind;
  final DateTime on;
  final String? number;
  final double? amount;
  final String? method;
  final String? note;
  final String? byName;
  final String? refId;
  final int? durationMinutes;

  factory CustomerEvent.fromActivity(ContactActivity activity) => CustomerEvent(
    kind: switch (activity.type) {
      ActivityType.call => CustomerEventKind.call,
      ActivityType.whatsApp => CustomerEventKind.whatsApp,
      ActivityType.visit => CustomerEventKind.visit,
      ActivityType.sms ||
      ActivityType.email ||
      ActivityType.note => CustomerEventKind.note,
    },
    on: activity.on,
    note: activity.note,
    byName: activity.byName,
    durationMinutes: activity.durationMinutes,
  );
}

/// Everything about one customer: money, deals, documents and touches.
class CustomerSummary {
  const CustomerSummary({
    required this.companyId,
    required this.companyName,
    required this.outstanding,
    required this.overdue,
    required this.leads,
    required this.quotations,
    required this.orders,
    required this.invoices,
    required this.payments,
    required this.activities,
    required this.documents,
  });

  final String companyId;
  final String companyName;
  final double outstanding;
  final double overdue;
  final List<LinkedLead> leads;
  final List<SalesDocRef> quotations;
  final List<SalesDocRef> orders;
  final List<SalesDocRef> invoices;
  final List<CustomerPayment> payments;
  final List<ContactActivity> activities;
  final List<CustomerDocument> documents;

  List<LinkedLead> get openDeals =>
      leads.where((lead) => lead.status == LeadStatus.open).toList();

  /// Lifetime value: everything invoiced and not cancelled.
  double get totalSales => invoices
      .where((invoice) => !invoice.isCancelled)
      .fold(0, (sum, invoice) => sum + invoice.amount);

  double get collected => payments
      .where((payment) => !payment.isCancelled)
      .fold(0, (sum, payment) => sum + payment.amount);

  double get openDealValue =>
      openDeals.fold(0, (sum, lead) => sum + lead.value);

  int get visitCount =>
      activities.where((a) => a.type == ActivityType.visit).length;

  /// Money, documents and touches together, newest first.
  List<CustomerEvent> get events => [
    for (final payment in payments)
      if (!payment.isCancelled)
        CustomerEvent(
          kind: CustomerEventKind.collection,
          on: payment.on,
          number: payment.receiptNo,
          amount: payment.amount,
          method: payment.method,
          refId: payment.id,
        ),
    for (final invoice in invoices)
      CustomerEvent(
        kind: CustomerEventKind.invoice,
        on: invoice.on,
        number: invoice.number,
        amount: invoice.amount,
        refId: invoice.id,
      ),
    for (final quote in quotations)
      CustomerEvent(
        kind: CustomerEventKind.quotation,
        on: quote.on,
        number: quote.number,
        amount: quote.amount,
        refId: quote.id,
      ),
    for (final order in orders) ...[
      CustomerEvent(
        kind: CustomerEventKind.order,
        on: order.on,
        number: order.number,
        amount: order.amount,
        refId: order.id,
      ),
      if (order.deliveredOn case final delivered?)
        CustomerEvent(
          kind: CustomerEventKind.delivery,
          on: delivered,
          number: order.number,
          refId: order.id,
        ),
    ],
    for (final activity in activities) CustomerEvent.fromActivity(activity),
    for (final document in documents)
      CustomerEvent(
        kind: CustomerEventKind.document,
        on: document.uploadedOn,
        number: document.fileName,
      ),
  ]..sort((a, b) => b.on.compareTo(a.on));
}

/// A file kept on the customer: an upload, or a photo from a visit.
class CustomerDocument {
  const CustomerDocument({
    required this.id,
    required this.key,
    required this.fileName,
    required this.uploadedOn,
    this.mime,
    this.sizeInBytes,
  });

  final String id;

  /// The storage key `GET files/{key}` serves the bytes under.
  final String key;
  final String fileName;
  final DateTime uploadedOn;
  final String? mime;
  final int? sizeInBytes;

  bool get isPhoto => mime?.startsWith('image/') ?? false;

  factory CustomerDocument.fromJson(Map<String, dynamic> json) =>
      CustomerDocument(
        id: jsonId(json['id']) ?? '',
        key: json['storageKey'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        uploadedOn: jsonDate(json['createdAt']) ?? DateTime(2000),
        mime: json['mime'] as String?,
        sizeInBytes: jsonInt(json['sizeBytes']),
      );
}

/// A file the user picked, ready to upload under [fileName].
class DocumentUpload {
  const DocumentUpload({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}
