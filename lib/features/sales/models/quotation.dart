import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

enum QuotationStatus {
  draft('draft'),
  pendingApproval('pending_approval'),
  approved('approved'),
  sent('sent'),
  viewed('viewed'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired');

  const QuotationStatus(this.wire);

  final String wire;

  static QuotationStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => QuotationStatus.draft,
  );

  /// Sent or viewed: waiting on the customer.
  bool get isAwaiting =>
      this == QuotationStatus.sent || this == QuotationStatus.viewed;

  /// Not yet sent: a draft, or one waiting on or cleared by a manager.
  bool get isUnsent =>
      this == QuotationStatus.draft ||
      this == QuotationStatus.pendingApproval ||
      this == QuotationStatus.approved;
}

enum SendChannel { whatsApp, sms, email, share }

class Quotation {
  const Quotation({
    required this.id,
    required this.number,
    required this.companyName,
    required this.contactName,
    required this.lines,
    required this.discountBps,
    required this.totals,
    required this.terms,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.ownerName,
    this.companyId,
    this.leadId,
    this.contactId,
    this.contactPhone,
    this.validUntil,
    this.sentAt,
    this.orderId,
    this.orderNumber,
  });

  final String id;
  final String number;
  final String? leadId;
  final String? companyId;
  final String companyName;
  final String? contactId;
  final String contactName;
  final String? contactPhone;
  final List<SalesLine> lines;
  final int discountBps;
  final SalesTotals totals;
  final DateTime? validUntil;

  /// Payment and delivery terms as printed.
  final String terms;
  final String note;
  final QuotationStatus status;
  final DateTime createdAt;
  final DateTime? sentAt;

  /// The order made from it, once accepted.
  final String? orderId;
  final String? orderNumber;
  final String ownerName;

  Quotation withOrder(String id, String number) => Quotation(
    id: this.id,
    number: this.number,
    leadId: leadId,
    companyId: companyId,
    companyName: companyName,
    contactId: contactId,
    contactName: contactName,
    contactPhone: contactPhone,
    lines: lines,
    discountBps: discountBps,
    totals: totals,
    validUntil: validUntil,
    terms: terms,
    note: note,
    status: status,
    createdAt: createdAt,
    sentAt: sentAt,
    orderId: id,
    orderNumber: number,
    ownerName: ownerName,
  );

  /// A row of `GET quotes`, or `GET quotes/{id}` with its [lines].
  factory Quotation.fromJson(
    Map<String, dynamic> json, {
    List<SalesLine> lines = const [],
  }) => Quotation(
    id: jsonId(json['id']) ?? '',
    number: json['number'] as String? ?? '',
    leadId: jsonId(json['leadId']),
    companyId: jsonId(json['companyId']),
    companyName:
        json['companyName'] as String? ?? json['leadName'] as String? ?? '',
    contactId: jsonId(json['contactId']),
    contactName: json['contactName'] as String? ?? '',
    contactPhone: json['contactPhone'] as String?,
    lines: lines,
    discountBps: bpsFromPercent(jsonDouble(json['discountPct']) ?? 0),
    totals: documentTotals(json, lines),
    validUntil: jsonDate(json['validUntil']),
    terms: json['terms'] as String? ?? '',
    note: json['note'] as String? ?? '',
    status: QuotationStatus.fromWire(json['status'] as String?),
    createdAt: jsonDate(json['createdAt']) ?? DateTime(2000),
    sentAt: jsonDate(json['sentAt']),
    ownerName: json['ownerName'] as String? ?? '',
  );

  /// `{quote, lines}`, as the detail, create, edit and duplicate answer.
  factory Quotation.fromDetail(Map<String, dynamic> json) => Quotation.fromJson(
    jsonMap(json['quote']),
    lines: jsonList(json['lines'], SalesLine.fromJson),
  );
}

/// A document's totals as the server worked them out; the gross comes from
/// the [lines] when they are loaded.
SalesTotals documentTotals(Map<String, dynamic> json, List<SalesLine> lines) {
  final subtotal = jsonDouble(json['subtotal']) ?? 0;
  return SalesTotals(
    gross: lines.isEmpty
        ? subtotal
        : lines.fold(0, (sum, line) => sum + line.gross),
    subtotal: subtotal,
    discount: jsonDouble(json['discountAmt']) ?? 0,
    vat: jsonDouble(json['taxAmt']) ?? 0,
  );
}

/// The body of a create or an edit: a `QuoteCreate`.
class QuotationInput {
  const QuotationInput({
    required this.lines,
    required this.discountBps,
    required this.validUntil,
    required this.terms,
    required this.note,
    this.companyId,
    this.leadId,
    this.contactId,
    this.requestApproval = false,
  });

  final String? companyId;
  final String? leadId;
  final String? contactId;
  final List<SalesLine> lines;
  final int discountBps;
  final DateTime validUntil;
  final String terms;
  final String note;

  /// Sends a discount above the user's limit to a manager.
  final bool requestApproval;

  static String? _text(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'leadId': leadId,
    'contactId': contactId,
    'lines': [
      for (final line in lines)
        if (line.qty > 0) line.toJson(),
    ],
    'discountPct': percentFromBps(discountBps),
    'validUntil': AppDateUtils.toApiDateOnly(validUntil),
    'terms': _text(terms),
    'note': _text(note),
    if (requestApproval) 'requestApproval': true,
  }..removeWhere((_, value) => value == null);
}

class QuotationQuery {
  const QuotationQuery({this.status, this.page = 1, this.size = pageSize});

  final QuotationStatus? status;
  final int page;
  final int size;

  QuotationQuery atPage(int page) =>
      QuotationQuery(status: status, page: page, size: size);

  Map<String, dynamic> toQuery() => {
    'status': ?status?.wire,
    ...pageQuery(page, size: size),
  };
}
