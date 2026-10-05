import 'dart:convert';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/instalment.dart';

enum PaymentMethod {
  cash('cash'),
  bkash('bkash'),
  nagad('nagad'),
  bank('bank'),
  cheque('cheque');

  const PaymentMethod(this.wire);

  final String wire;

  static PaymentMethod fromWire(String? value) => values.firstWhere(
    (m) => m.wire == value,
    orElse: () => PaymentMethod.cash,
  );

  bool get isMobile => this == bkash || this == nagad;

  /// Needs a reference: the TrxID or the cheque number.
  bool get needsReference => isMobile || this == cheque;
}

enum ChequeStatus {
  pending('pending'),
  cleared('cleared'),
  bounced('bounced');

  const ChequeStatus(this.wire);

  final String wire;

  static ChequeStatus? fromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// A customer and what they still owe, receivable by receivable.
class CustomerDues {
  const CustomerDues({
    required this.companyId,
    required this.companyName,
    required this.items,
  });

  final String companyId;
  final String companyName;

  /// Oldest first.
  final List<Instalment> items;

  double get due => items.fold(0, (sum, item) => sum + item.due);
}

class Allocation {
  const Allocation({
    required this.receivableId,
    required this.label,
    required this.amount,
  });

  final String receivableId;

  /// The receivable's name: `1st instalment`, or an old bill number.
  final String label;
  final double amount;

  factory Allocation.fromJson(Map<String, dynamic> json) => Allocation(
    receivableId: jsonId(json['receivableId']) ?? '',
    label: json['label'] as String? ?? '',
    amount: jsonDouble(json['amount']) ?? 0,
  );

  /// An `AllocationInput`.
  Map<String, dynamic> toJson() => {
    'receivableId': receivableId,
    'amount': amount,
  };
}

/// Spreads [amount] over [items] oldest due date first, filling each before
/// the next. What is left over stays unallocated.
List<Allocation> allocateOldestFirst(List<Instalment> items, double amount) {
  final ordered = [...items]
    ..sort((a, b) {
      final byDate = a.dueDate.compareTo(b.dueDate);
      return byDate != 0 ? byDate : (a.seq ?? 0) - (b.seq ?? 0);
    });
  final allocations = <Allocation>[];
  var left = amount;
  for (final item in ordered) {
    if (left <= 0) break;
    if (item.due <= 0) continue;
    final take = left < item.due ? left : item.due;
    allocations.add(
      Allocation(receivableId: item.id, label: item.label, amount: take),
    );
    left -= take;
  }
  return allocations;
}

/// The allocations of a payment, which the server sends as an encoded list.
List<Allocation> _allocations(dynamic value) {
  var list = value;
  if (value is String && value.isNotEmpty) {
    try {
      list = jsonDecode(value);
    } on FormatException {
      list = null;
    }
  }
  return jsonList(list, Allocation.fromJson);
}

class Collection {
  const Collection({
    required this.id,
    required this.number,
    required this.companyName,
    required this.amount,
    required this.method,
    required this.collectedAt,
    required this.allocations,
    required this.receivedByName,
    this.companyId,
    this.reference,
    this.chequeDate,
    this.chequeStatus,
    this.note,
    this.advance = 0,
    this.cancelled = false,
    this.balanceDue,
  });

  final String id;

  /// The receipt number.
  final String number;
  final String? companyId;
  final String companyName;
  final double amount;
  final PaymentMethod method;

  /// The TrxID, cheque number or bank reference.
  final String? reference;
  final DateTime? chequeDate;
  final ChequeStatus? chequeStatus;
  final DateTime collectedAt;
  final String? note;
  final List<Allocation> allocations;
  final String receivedByName;

  /// What was kept as an advance because it did not fit any due.
  final double advance;
  final bool cancelled;

  /// What the customer still owes; only the receipt screen loads it.
  final double? balanceDue;

  Collection withBalance(double balance) => Collection(
    id: id,
    number: number,
    companyId: companyId,
    companyName: companyName,
    amount: amount,
    method: method,
    reference: reference,
    chequeDate: chequeDate,
    chequeStatus: chequeStatus,
    collectedAt: collectedAt,
    note: note,
    allocations: allocations,
    receivedByName: receivedByName,
    advance: advance,
    cancelled: cancelled,
    balanceDue: balance,
  );

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: jsonId(json['id']) ?? '',
    number: json['receiptNo'] as String? ?? '',
    companyId: jsonId(json['companyId']),
    companyName:
        json['companyName'] as String? ?? json['contactName'] as String? ?? '',
    amount: jsonDouble(json['amount']) ?? 0,
    method: PaymentMethod.fromWire(json['method'] as String?),
    reference: json['reference'] as String?,
    chequeDate: jsonDate(json['chequeDate']),
    chequeStatus: ChequeStatus.fromWire(json['chequeStatus'] as String?),
    collectedAt: jsonDate(json['receivedAt']) ?? DateTime(2000),
    note: json['note'] as String?,
    allocations: _allocations(json['allocations']),
    receivedByName: json['receivedByName'] as String? ?? '',
    advance: jsonDouble(json['advanceAmt']) ?? 0,
    cancelled: json['status'] == 'cancelled',
  );
}

/// A `PaymentCreate`.
class CollectionInput {
  const CollectionInput({
    required this.companyId,
    required this.amount,
    required this.method,
    required this.collectedAt,
    required this.allocations,
    this.reference,
    this.chequeDate,
    this.note,
  });

  final String? companyId;
  final double amount;
  final PaymentMethod method;
  final DateTime collectedAt;
  final List<Allocation> allocations;
  final String? reference;
  final DateTime? chequeDate;
  final String? note;

  static String? _text(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toJson() {
    final cheque = chequeDate;
    return {
      'companyId': companyId,
      'amount': amount,
      'method': method.wire,
      'receivedAt': jsonUtc(collectedAt),
      'allocations': [for (final a in allocations) a.toJson()],
      'keepExtraAsAdvance': true,
      'reference': _text(reference),
      'chequeDate': cheque == null ? null : AppDateUtils.toApiDateOnly(cheque),
      'note': _text(note),
    }..removeWhere((_, value) => value == null);
  }
}
