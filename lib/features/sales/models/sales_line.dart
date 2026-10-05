import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

/// One line on a quotation, order or bill.
class SalesLine implements PricedLine {
  const SalesLine({
    required this.name,
    required this.unit,
    required this.qty,
    required this.unitPrice,
    this.productId,
    this.nameBn = '',
    this.discountBps = 0,
    this.vatBps = 0,
  });

  /// Null for a line typed in without a catalogue product.
  final String? productId;

  /// The line's description; the product's English name when added from the
  /// catalogue.
  final String name;
  final String nameBn;
  final String unit;
  @override
  final double qty;
  @override
  final double unitPrice;
  @override
  final int discountBps;
  @override
  final int vatBps;

  /// Identifies the line within its document.
  String get key => productId ?? name;

  String nameIn({required bool bangla}) =>
      LocalizedName(name, nameBn).of(bangla);

  factory SalesLine.of(Product product, {double qty = 1}) => SalesLine(
    productId: product.id,
    name: product.name,
    nameBn: product.nameBn,
    unit: product.unit,
    qty: qty,
    unitPrice: product.price,
    vatBps: product.vatBps,
  );

  SalesLine copyWith({double? qty, int? discountBps}) => SalesLine(
    productId: productId,
    name: name,
    nameBn: nameBn,
    unit: unit,
    qty: qty ?? this.qty,
    unitPrice: unitPrice,
    discountBps: discountBps ?? this.discountBps,
    vatBps: vatBps,
  );

  factory SalesLine.fromJson(Map<String, dynamic> json) => SalesLine(
    productId: jsonId(json['productId']),
    name: json['description'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    qty: jsonDouble(json['qty']) ?? 0,
    unitPrice: jsonDouble(json['unitPrice']) ?? 0,
    discountBps: bpsFromPercent(jsonDouble(json['discountPct']) ?? 0),
    vatBps: bpsFromPercent(jsonDouble(json['taxPct']) ?? 0),
  );

  /// A `LineInput`.
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'description': name,
    'qty': qty,
    'unit': unit.isEmpty ? null : unit,
    'unitPrice': unitPrice,
    'discountPct': percentFromBps(discountBps),
    'taxPct': percentFromBps(vatBps),
  }..removeWhere((_, value) => value == null);
}
