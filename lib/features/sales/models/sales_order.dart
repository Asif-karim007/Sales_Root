import 'dart:convert';
import 'dart:typed_data';

import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

enum OrderStatus {
  confirmed('Confirmed'),
  inProgress('InProgress'),
  delivered('Delivered'),
  invoiced('Invoiced');

  const OrderStatus(this.wire);

  final String wire;

  static OrderStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => OrderStatus.confirmed,
  );

  bool get toDeliver =>
      this == OrderStatus.confirmed || this == OrderStatus.inProgress;
}

/// `SO-092`
String orderNumber(int id) => 'SO-${id.toString().padLeft(3, '0')}';

/// `INV-2026-0912`
String invoiceNumber(int year, int id) =>
    'INV-$year-${id.toString().padLeft(4, '0')}';

class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.number,
    required this.companyId,
    required this.companyName,
    required this.contactName,
    required this.lines,
    required this.discountBps,
    required this.vatBps,
    required this.status,
    required this.instalments,
    required this.createdAt,
    this.quotationId,
    this.quotationNumber,
    this.contactPhone,
    this.invoiceId,
    this.invoiceNumber,
    this.delivery,
    this.canEdit = false,
  });

  final int id;
  final String number;
  final int? quotationId;
  final String? quotationNumber;
  final int companyId;
  final String companyName;
  final String contactName;
  final String? contactPhone;
  final List<SalesLine> lines;
  final int discountBps;
  final int vatBps;
  final OrderStatus status;
  final List<Instalment> instalments;
  final DateTime createdAt;
  final int? invoiceId;
  final String? invoiceNumber;
  final Delivery? delivery;
  final bool canEdit;

  SalesTotals get totals =>
      computeTotals(lines, discountBps: discountBps, vatBps: vatBps);

  int get paid => instalments.fold(0, (sum, i) => sum + i.paid);
  int get due => totals.total - paid;

  factory SalesOrder.fromJson(Map<String, dynamic> json) => SalesOrder(
    id: jsonInt(json['Id']) ?? 0,
    number: json['Number'] as String? ?? '',
    quotationId: jsonInt(json['QuotationId']),
    quotationNumber: json['QuotationNumber'] as String?,
    companyId: jsonInt(json['CompanyId']) ?? 0,
    companyName: json['CompanyName'] as String? ?? '',
    contactName: json['ContactName'] as String? ?? '',
    contactPhone: json['ContactPhone'] as String?,
    lines: jsonList(json['Lines'], SalesLine.fromJson),
    discountBps: jsonInt(json['DiscountBps']) ?? 0,
    vatBps: jsonInt(json['VatBps']) ?? standardVatBps,
    status: OrderStatus.fromWire(json['Status'] as String?),
    instalments: jsonList(json['Instalments'], Instalment.fromJson),
    createdAt: jsonDate(json['CreatedAt']) ?? DateTime(2000),
    invoiceId: jsonInt(json['InvoiceId']),
    invoiceNumber: json['InvoiceNumber'] as String?,
    delivery: jsonObject(json['Delivery'], Delivery.fromJson),
    canEdit: jsonBool(json['CanEdit']),
  );
}

class Delivery {
  const Delivery({
    required this.deliveredAt,
    required this.receivedBy,
    required this.note,
    required this.deliveredProductIds,
    required this.photoCount,
    required this.signed,
  });

  final DateTime deliveredAt;
  final String receivedBy;
  final String note;
  final List<int> deliveredProductIds;
  final int photoCount;
  final bool signed;

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
    deliveredAt: jsonDate(json['DeliveredAt']) ?? DateTime(2000),
    receivedBy: json['ReceivedBy'] as String? ?? '',
    note: json['Note'] as String? ?? '',
    deliveredProductIds: jsonInts(json['DeliveredProductIds']),
    photoCount: jsonInt(json['PhotoCount']) ?? 0,
    signed: jsonBool(json['Signed']),
  );
}

class DeliveryInput {
  const DeliveryInput({
    required this.deliveredAt,
    required this.receivedBy,
    required this.note,
    required this.deliveredProductIds,
    required this.photos,
    required this.createBill,
    this.signaturePng,
  });

  final DateTime deliveredAt;
  final String receivedBy;
  final String note;
  final List<int> deliveredProductIds;

  /// Local paths of the photos taken.
  final List<String> photos;
  final Uint8List? signaturePng;
  final bool createBill;

  Map<String, dynamic> toJson() {
    final signature = signaturePng;
    return {
      'DeliveredAt': jsonUtc(deliveredAt),
      'ReceivedBy': receivedBy.trim(),
      'Note': note.trim().isEmpty ? null : note.trim(),
      'DeliveredProductIds': deliveredProductIds,
      'Photos': photos,
      'Signature': signature == null ? null : base64Encode(signature),
      'CreateBill': createBill,
    }..removeWhere((_, value) => value == null);
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.orderId,
    required this.orderNumber,
    required this.companyId,
    required this.companyName,
    required this.contactName,
    required this.lines,
    required this.discountBps,
    required this.vatBps,
    required this.issuedAt,
    required this.instalments,
    this.contactPhone,
    this.ageDays = 0,
  });

  final int id;
  final String number;
  final int orderId;
  final String orderNumber;
  final int companyId;
  final String companyName;
  final String contactName;
  final String? contactPhone;
  final List<SalesLine> lines;
  final int discountBps;
  final int vatBps;
  final DateTime issuedAt;

  /// The order's payment schedule, with what has been collected on each.
  final List<Instalment> instalments;

  /// Days since the bill was issued, by the server's clock.
  final int ageDays;

  SalesTotals get totals =>
      computeTotals(lines, discountBps: discountBps, vatBps: vatBps);

  int get paid => instalments.fold(0, (sum, i) => sum + i.paid);
  int get due => totals.total - paid;

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: jsonInt(json['Id']) ?? 0,
    number: json['Number'] as String? ?? '',
    orderId: jsonInt(json['OrderId']) ?? 0,
    orderNumber: json['OrderNumber'] as String? ?? '',
    companyId: jsonInt(json['CompanyId']) ?? 0,
    companyName: json['CompanyName'] as String? ?? '',
    contactName: json['ContactName'] as String? ?? '',
    contactPhone: json['ContactPhone'] as String?,
    lines: jsonList(json['Lines'], SalesLine.fromJson),
    discountBps: jsonInt(json['DiscountBps']) ?? 0,
    vatBps: jsonInt(json['VatBps']) ?? standardVatBps,
    issuedAt: jsonDate(json['IssuedAt']) ?? DateTime(2000),
    instalments: jsonList(json['Instalments'], Instalment.fromJson),
    ageDays: jsonInt(json['AgeDays']) ?? 0,
  );
}

class OrderQuery {
  const OrderQuery({this.toDeliver = false, this.page = 1});

  final bool toDeliver;
  final int page;

  Map<String, dynamic> toQuery() =>
      {'ToDeliver': toDeliver ? true : null, 'Page': page, 'PageSize': 20}
        ..removeWhere((_, value) => value == null);
}

/// The figures on the sales home.
class SalesOverview {
  const SalesOverview({
    required this.salesThisMonth,
    required this.salesLastMonth,
    required this.openQuotations,
    required this.openQuotationValue,
    required this.ordersToDeliver,
    required this.receivable,
  });

  final int salesThisMonth;
  final int salesLastMonth;
  final int openQuotations;
  final int openQuotationValue;
  final int ordersToDeliver;
  final int receivable;

  /// Change on last month in percent; null when last month had no sales.
  double? get growth => salesLastMonth == 0
      ? null
      : (salesThisMonth - salesLastMonth) * 100 / salesLastMonth;

  factory SalesOverview.fromJson(Map<String, dynamic> json) => SalesOverview(
    salesThisMonth: jsonInt(json['SalesThisMonth']) ?? 0,
    salesLastMonth: jsonInt(json['SalesLastMonth']) ?? 0,
    openQuotations: jsonInt(json['OpenQuotations']) ?? 0,
    openQuotationValue: jsonInt(json['OpenQuotationValue']) ?? 0,
    ordersToDeliver: jsonInt(json['OrdersToDeliver']) ?? 0,
    receivable: jsonInt(json['Receivable']) ?? 0,
  );
}
