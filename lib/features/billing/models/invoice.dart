import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

enum InvoiceStatus {
  paid('Paid'),
  failed('Failed'),
  refunded('Refunded');

  const InvoiceStatus(this.wire);

  final String wire;

  static InvoiceStatus fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => paid);
}

enum InvoiceKind {
  plan('Plan'),
  addOn('AddOn'),
  pack('Pack');

  const InvoiceKind(this.wire);

  final String wire;

  static InvoiceKind fromWire(String? value) =>
      values.firstWhere((k) => k.wire == value, orElse: () => plan);
}

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.kind,
    required this.item,
    required this.issuedAt,
    required this.status,
    required this.quote,
    this.periodStart,
    this.seats = 0,
    this.method,
    this.retriedAt,
  });

  final int id;
  final String number;
  final InvoiceKind kind;

  /// The plan or add-on the bill is for.
  final LocalizedName item;
  final DateTime issuedAt;
  final InvoiceStatus status;
  final Quote quote;

  /// The billed month, for plan renewals.
  final DateTime? periodStart;
  final int seats;
  final PaymentMethod? method;

  /// Set when the first charge failed and a later one went through.
  final DateTime? retriedAt;

  int get total => quote.total;

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: jsonInt(json['Id']) ?? 0,
    number: json['Number'] as String? ?? '',
    kind: InvoiceKind.fromWire(json['Kind'] as String?),
    item: LocalizedName(
      json['ItemName'] as String? ?? '',
      json['ItemNameBn'] as String? ?? '',
    ),
    issuedAt: jsonDate(json['IssuedAt']) ?? DateTime(2000),
    status: InvoiceStatus.fromWire(json['Status'] as String?),
    quote: Quote.fromJson(json),
    periodStart: jsonDate(json['PeriodStart']),
    seats: jsonInt(json['Seats']) ?? 0,
    method: jsonObject<PaymentMethod?>(
      json['PaymentMethod'],
      PaymentMethod.fromJson,
    ),
    retriedAt: jsonDate(json['RetriedAt']),
  );
}
