import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/instalment.dart';

enum PaymentMethod {
  cash('Cash'),
  bkash('bKash'),
  nagad('Nagad'),
  bank('Bank'),
  cheque('Cheque');

  const PaymentMethod(this.wire);

  final String wire;

  static PaymentMethod fromWire(String? value) => values.firstWhere(
    (m) => m.wire == value,
    orElse: () => PaymentMethod.cash,
  );

  bool get isMobile => this == bkash || this == nagad;
  bool get needsBank => this == bank || this == cheque;
}

/// `R-0232`
String receiptNumber(int id) => 'R-${id.toString().padLeft(4, '0')}';

/// An instalment still open, as the collection screen offers it.
class DueItem {
  const DueItem({
    required this.orderId,
    required this.orderNumber,
    required this.instalment,
    this.invoiceId,
    this.invoiceNumber,
  });

  final int orderId;
  final String orderNumber;
  final int? invoiceId;
  final String? invoiceNumber;
  final Instalment instalment;

  int get due => instalment.due;

  /// Identifies the instalment across orders.
  String get key => '$orderId/${instalment.seq}';

  factory DueItem.fromJson(Map<String, dynamic> json) => DueItem(
    orderId: jsonInt(json['OrderId']) ?? 0,
    orderNumber: json['OrderNumber'] as String? ?? '',
    invoiceId: jsonInt(json['InvoiceId']),
    invoiceNumber: json['InvoiceNumber'] as String?,
    instalment: Instalment.fromJson(json),
  );
}

/// A customer and what they still owe, instalment by instalment.
class CustomerDues {
  const CustomerDues({
    required this.companyId,
    required this.companyName,
    required this.contactName,
    required this.items,
    this.contactPhone,
  });

  final int companyId;
  final String companyName;
  final String contactName;
  final String? contactPhone;

  /// Oldest first.
  final List<DueItem> items;

  int get due => items.fold(0, (sum, item) => sum + item.due);

  factory CustomerDues.fromJson(Map<String, dynamic> json) => CustomerDues(
    companyId: jsonInt(json['CompanyId']) ?? 0,
    companyName: json['CompanyName'] as String? ?? '',
    contactName: json['ContactName'] as String? ?? '',
    contactPhone: json['ContactPhone'] as String?,
    items: jsonList(json['Items'], DueItem.fromJson),
  );
}

class Allocation {
  const Allocation({
    required this.orderId,
    required this.orderNumber,
    required this.seq,
    required this.kind,
    required this.amount,
    this.invoiceId,
    this.invoiceNumber,
  });

  final int orderId;
  final String orderNumber;
  final int? invoiceId;
  final String? invoiceNumber;
  final int seq;
  final InstalmentKind kind;
  final int amount;

  factory Allocation.fromJson(Map<String, dynamic> json) => Allocation(
    orderId: jsonInt(json['OrderId']) ?? 0,
    orderNumber: json['OrderNumber'] as String? ?? '',
    invoiceId: jsonInt(json['InvoiceId']),
    invoiceNumber: json['InvoiceNumber'] as String?,
    seq: jsonInt(json['Seq']) ?? 1,
    kind: InstalmentKind.fromWire(json['Kind'] as String?),
    amount: jsonInt(json['Amount']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'OrderId': orderId,
    'Seq': seq,
    'Amount': amount,
  };
}

/// Spreads [amount] over [items] oldest due date first, filling each
/// instalment before the next. What is left over stays unallocated.
List<Allocation> allocateOldestFirst(List<DueItem> items, int amount) {
  final ordered = [...items]
    ..sort((a, b) {
      final byDate = a.instalment.dueDate.compareTo(b.instalment.dueDate);
      return byDate != 0 ? byDate : a.instalment.seq - b.instalment.seq;
    });
  final allocations = <Allocation>[];
  var left = amount;
  for (final item in ordered) {
    if (left <= 0) break;
    if (item.due <= 0) continue;
    final take = left < item.due ? left : item.due;
    allocations.add(
      Allocation(
        orderId: item.orderId,
        orderNumber: item.orderNumber,
        invoiceId: item.invoiceId,
        invoiceNumber: item.invoiceNumber,
        seq: item.instalment.seq,
        kind: item.instalment.kind,
        amount: take,
      ),
    );
    left -= take;
  }
  return allocations;
}

class Collection {
  const Collection({
    required this.id,
    required this.number,
    required this.companyId,
    required this.companyName,
    required this.amount,
    required this.method,
    required this.collectedAt,
    required this.allocations,
    required this.receivedByName,
    this.receivedByNameBn = '',
    this.reference,
    this.senderNumber,
    this.bankName,
    this.chequeNumber,
    this.chequeDate,
    this.note,
    this.hasPhoto = false,
    this.balanceDue = 0,
    this.smsSent = false,
  });

  final int id;
  final String number;
  final int companyId;
  final String companyName;
  final int amount;
  final PaymentMethod method;
  final String? reference;
  final String? senderNumber;
  final String? bankName;
  final String? chequeNumber;
  final DateTime? chequeDate;
  final DateTime collectedAt;
  final String? note;
  final bool hasPhoto;
  final List<Allocation> allocations;
  final String receivedByName;
  final String receivedByNameBn;

  String receivedByIn({required bool bangla}) =>
      LocalizedName(receivedByName, receivedByNameBn).of(bangla);

  /// What the customer still owes after this collection.
  final int balanceDue;
  final bool smsSent;

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: jsonInt(json['Id']) ?? 0,
    number: json['Number'] as String? ?? '',
    companyId: jsonInt(json['CompanyId']) ?? 0,
    companyName: json['CompanyName'] as String? ?? '',
    amount: jsonInt(json['Amount']) ?? 0,
    method: PaymentMethod.fromWire(json['Method'] as String?),
    reference: json['Reference'] as String?,
    senderNumber: json['SenderNumber'] as String?,
    bankName: json['BankName'] as String?,
    chequeNumber: json['ChequeNumber'] as String?,
    chequeDate: jsonDate(json['ChequeDate']),
    collectedAt: jsonDate(json['CollectedAt']) ?? DateTime(2000),
    note: json['Note'] as String?,
    hasPhoto: jsonBool(json['HasPhoto']),
    allocations: jsonList(json['Allocations'], Allocation.fromJson),
    receivedByName: json['ReceivedByName'] as String? ?? '',
    receivedByNameBn: json['ReceivedByNameBn'] as String? ?? '',
    balanceDue: jsonInt(json['BalanceDue']) ?? 0,
    smsSent: jsonBool(json['SmsSent']),
  );
}

class CollectionInput {
  const CollectionInput({
    required this.companyId,
    required this.amount,
    required this.method,
    required this.collectedAt,
    required this.allocations,
    this.reference,
    this.senderNumber,
    this.bankName,
    this.chequeNumber,
    this.chequeDate,
    this.note,
    this.photoPath,
  });

  final int? companyId;
  final int amount;
  final PaymentMethod method;
  final DateTime collectedAt;
  final List<Allocation> allocations;
  final String? reference;
  final String? senderNumber;
  final String? bankName;
  final String? chequeNumber;
  final DateTime? chequeDate;
  final String? note;
  final String? photoPath;

  static String? _text(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toJson() => {
    'CompanyId': companyId,
    'Amount': amount,
    'Method': method.wire,
    'CollectedAt': jsonUtc(collectedAt),
    'Allocations': [for (final a in allocations) a.toJson()],
    'Reference': _text(reference),
    'SenderNumber': _text(senderNumber),
    'BankName': _text(bankName),
    'ChequeNumber': _text(chequeNumber),
    'ChequeDate': jsonUtc(chequeDate),
    'Note': _text(note),
    'Photo': photoPath,
  }..removeWhere((_, value) => value == null);
}
