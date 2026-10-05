import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/models/checkout.dart';

enum InvoiceStatus {
  paid('paid'),
  due('due'),
  failed('failed'),
  refunded('refunded');

  const InvoiceStatus(this.wire);

  final String wire;

  static InvoiceStatus fromWire(String? value) => switch (value) {
    'paid' => paid,
    'failed' || 'cancelled' => failed,
    'refunded' => refunded,
    _ => due,
  };
}

/// A SalesRoot bill for the workspace, from `GET billing/history`.
class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.item,
    required this.status,
    required this.quote,
    this.issuedAt,
    this.gateway,
  });

  final String id;
  final String number;

  /// What the bill is for, e.g. "SalesRoot Business · 25 users · yearly".
  final String item;
  final InvoiceStatus status;
  final Quote quote;
  final DateTime? issuedAt;
  final String? gateway;

  int get total => quote.total;

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: jsonId(json['id']) ?? '',
    number: json['number'] as String? ?? '',
    item: json['description'] as String? ?? '',
    status: InvoiceStatus.fromWire(json['status'] as String?),
    quote: Quote.fromJson(json),
    issuedAt: jsonDate(json['createdAt'] ?? json['issuedAt']),
    gateway: json['gateway'] as String?,
  );
}
