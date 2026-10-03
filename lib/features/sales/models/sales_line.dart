import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

/// One product line on a quotation, order or bill.
class SalesLine implements PricedLine {
  const SalesLine({
    required this.productId,
    required this.code,
    required this.name,
    required this.nameBn,
    required this.unit,
    required this.qty,
    required this.unitPrice,
    this.discountBps = 0,
  });

  final int productId;
  final String code;
  final String name;
  final String nameBn;
  final String unit;
  @override
  final int qty;
  @override
  final int unitPrice;
  @override
  final int discountBps;

  String nameIn({required bool bangla}) =>
      LocalizedName(name, nameBn).of(bangla);

  factory SalesLine.of(Product product, PriceList list, {int qty = 1}) =>
      SalesLine(
        productId: product.id,
        code: product.code,
        name: product.name,
        nameBn: product.nameBn,
        unit: product.unit,
        qty: qty,
        unitPrice: product.priceIn(list),
      );

  SalesLine copyWith({int? qty, int? unitPrice, int? discountBps}) => SalesLine(
    productId: productId,
    code: code,
    name: name,
    nameBn: nameBn,
    unit: unit,
    qty: qty ?? this.qty,
    unitPrice: unitPrice ?? this.unitPrice,
    discountBps: discountBps ?? this.discountBps,
  );

  factory SalesLine.fromJson(Map<String, dynamic> json) => SalesLine(
    productId: jsonInt(json['ProductId']) ?? 0,
    code: json['Code'] as String? ?? '',
    name: json['Name'] as String? ?? '',
    nameBn: json['NameBn'] as String? ?? '',
    unit: json['Unit'] as String? ?? '',
    qty: jsonInt(json['Qty']) ?? 0,
    unitPrice: jsonInt(json['UnitPrice']) ?? 0,
    discountBps: jsonInt(json['DiscountBps']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'ProductId': productId,
    'Code': code,
    'Name': name,
    'NameBn': nameBn,
    'Unit': unit,
    'Qty': qty,
    'UnitPrice': unitPrice,
    'DiscountBps': discountBps,
  };
}
