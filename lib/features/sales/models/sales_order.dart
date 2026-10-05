import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

/// Where an order stands. The server keeps confirmed, in progress, delivered
/// and cancelled; an order with a bill shows as invoiced.
enum OrderStatus {
  confirmed('confirmed'),
  inProgress('in_progress'),
  delivered('delivered'),
  invoiced('invoiced'),
  cancelled('cancelled');

  const OrderStatus(this.wire);

  final String wire;

  static OrderStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => OrderStatus.confirmed,
  );

  /// The steps an order goes through, in order.
  static const steps = [confirmed, inProgress, delivered, invoiced];

  bool get toDeliver =>
      this == OrderStatus.confirmed || this == OrderStatus.inProgress;
}

class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.number,
    required this.companyName,
    required this.contactName,
    required this.lines,
    required this.totals,
    required this.status,
    required this.createdAt,
    required this.note,
    this.companyId,
    this.quotationId,
    this.deliveryDate,
    this.invoices = const [],
  });

  final String id;
  final String number;
  final String? quotationId;
  final String? companyId;
  final String companyName;
  final String contactName;
  final List<SalesLine> lines;
  final SalesTotals totals;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? deliveryDate;
  final String note;

  /// The bills made from it; only the detail carries them.
  final List<InvoiceSummary> invoices;

  /// The first bill with money still due, to collect against.
  InvoiceSummary? get openInvoice {
    for (final invoice in invoices) {
      if (invoice.due > 0) return invoice;
    }
    return null;
  }

  /// A row of `GET orders`, or `GET orders/{id}` with its [lines] and
  /// [invoices].
  factory SalesOrder.fromJson(
    Map<String, dynamic> json, {
    List<SalesLine> lines = const [],
    List<InvoiceSummary> invoices = const [],
  }) {
    final status = OrderStatus.fromWire(json['status'] as String?);
    final billed =
        (jsonDouble(json['invoicedAmt']) ?? 0) > 0 || invoices.isNotEmpty;
    return SalesOrder(
      id: jsonId(json['id']) ?? '',
      number: json['number'] as String? ?? '',
      quotationId: jsonId(json['quoteId']),
      companyId: jsonId(json['companyId']),
      companyName: json['companyName'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      lines: lines,
      totals: documentTotals(json, lines),
      status: billed && status != OrderStatus.cancelled
          ? OrderStatus.invoiced
          : status,
      createdAt: jsonDate(json['createdAt']) ?? DateTime(2000),
      deliveryDate: jsonDate(json['deliveryDate']),
      note: json['note'] as String? ?? '',
      invoices: invoices,
    );
  }

  /// `{order, lines, invoices}`.
  factory SalesOrder.fromDetail(Map<String, dynamic> json) =>
      SalesOrder.fromJson(
        jsonMap(json['order']),
        lines: jsonList(json['lines'], SalesLine.fromJson),
        invoices: jsonList(json['invoices'], InvoiceSummary.fromJson),
      );
}

/// A bill as an order lists it.
class InvoiceSummary {
  const InvoiceSummary({
    required this.id,
    required this.number,
    required this.total,
    required this.paid,
    required this.issuedAt,
    required this.status,
  });

  final String id;
  final String number;
  final double total;
  final double paid;
  final DateTime issuedAt;
  final InvoiceStatus status;

  double get due => status == InvoiceStatus.cancelled ? 0 : total - paid;

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) => InvoiceSummary(
    id: jsonId(json['id']) ?? '',
    number: json['number'] as String? ?? '',
    total: jsonDouble(json['total']) ?? 0,
    paid: jsonDouble(json['paidAmt']) ?? 0,
    issuedAt: jsonDate(json['issueDate']) ?? DateTime(2000),
    status: InvoiceStatus.fromWire(json['status'] as String?),
  );
}

/// `PATCH orders/{id}` marking it delivered: an `OrderUpdate`.
class DeliveryInput {
  const DeliveryInput({required this.deliveredOn, required this.note});

  final DateTime deliveredOn;
  final String note;

  Map<String, dynamic> toJson() => {
    'status': OrderStatus.delivered.wire,
    'deliveryDate': AppDateUtils.toApiDateOnly(deliveredOn),
    'note': note.trim().isEmpty ? null : note.trim(),
  }..removeWhere((_, value) => value == null);
}

enum InvoiceStatus {
  issued('issued'),
  partial('partial'),
  paid('paid'),
  cancelled('cancelled');

  const InvoiceStatus(this.wire);

  final String wire;

  static InvoiceStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => InvoiceStatus.issued,
  );
}

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.companyName,
    required this.contactName,
    required this.lines,
    required this.totals,
    required this.paid,
    required this.issuedAt,
    required this.status,
    this.orderId,
    this.orderNumber,
    this.companyId,
    this.dueDate,
    this.instalments = const [],
  });

  final String id;
  final String number;
  final String? orderId;
  final String? orderNumber;
  final String? companyId;
  final String companyName;
  final String contactName;
  final List<SalesLine> lines;
  final SalesTotals totals;
  final double paid;
  final DateTime issuedAt;
  final DateTime? dueDate;
  final InvoiceStatus status;

  /// What it is to be paid in, with what has been collected on each; only
  /// the detail carries them.
  final List<Instalment> instalments;

  double get due => status == InvoiceStatus.cancelled ? 0 : totals.total - paid;

  /// A row of `GET invoices`, or `GET invoices/{id}` with its [lines] and
  /// [instalments].
  factory Invoice.fromJson(
    Map<String, dynamic> json, {
    List<SalesLine> lines = const [],
    List<Instalment> instalments = const [],
  }) => Invoice(
    id: jsonId(json['id']) ?? '',
    number: json['number'] as String? ?? '',
    orderId: jsonId(json['orderId']),
    orderNumber: json['orderNumber'] as String?,
    companyId: jsonId(json['companyId']),
    companyName: json['companyName'] as String? ?? '',
    contactName: json['contactName'] as String? ?? '',
    lines: lines,
    totals: documentTotals(json, lines),
    paid: jsonDouble(json['paidAmt']) ?? 0,
    issuedAt: jsonDate(json['issueDate']) ?? DateTime(2000),
    dueDate: jsonDate(json['dueDate']),
    status: InvoiceStatus.fromWire(json['status'] as String?),
    instalments: instalments,
  );

  /// `{invoice, lines, receivables, payments}`.
  factory Invoice.fromDetail(Map<String, dynamic> json, {DateTime? today}) =>
      Invoice.fromJson(
        jsonMap(json['invoice']),
        lines: jsonList(json['lines'], SalesLine.fromJson),
        instalments: jsonList(
          json['receivables'],
          (row) => Instalment.fromJson(row, today: today),
        ),
      );
}

class OrderQuery {
  const OrderQuery({this.toDeliver = false, this.page = 1});

  /// Only orders confirmed and not yet delivered.
  final bool toDeliver;
  final int page;

  Map<String, dynamic> toQuery() => {
    if (toDeliver) 'status': OrderStatus.confirmed.wire,
    ...pageQuery(page),
  };
}

/// The figures on the sales home.
class SalesOverview {
  const SalesOverview({
    required this.salesThisMonth,
    required this.salesLastMonth,
    required this.openQuotations,
    required this.ordersToDeliver,
    required this.receivable,
  });

  /// Order value booked this month and last.
  final double salesThisMonth;
  final double salesLastMonth;

  /// Quotations sent and waiting on the customer.
  final int openQuotations;
  final int ordersToDeliver;
  final double receivable;

  /// Change on last month in percent; null when last month had no sales.
  double? get growth => salesLastMonth == 0
      ? null
      : (salesThisMonth - salesLastMonth) * 100 / salesLastMonth;
}
