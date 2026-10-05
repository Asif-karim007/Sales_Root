import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.nameBn,
    required this.unit,
    required this.price,
    this.vatBps = 0,
    this.stock,
  });

  final String id;

  /// The SKU; empty when the product has none.
  final String code;
  final String name;
  final String nameBn;

  /// The selling unit as the server sends it: piece, ctn, trip…
  final String unit;
  final double price;
  final int vatBps;

  /// Units in stock; null when stock is not kept for it.
  final double? stock;

  String nameIn({required bool bangla}) =>
      LocalizedName(name, nameBn).of(bangla);

  factory Product.fromJson(Map<String, dynamic> json) {
    final tracked = jsonBool(json['trackStock']);
    return Product(
      id: jsonId(json['id']) ?? '',
      code: json['sku'] as String? ?? '',
      name: json['nameEn'] as String? ?? '',
      nameBn: json['nameBn'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      price: jsonDouble(json['price']) ?? 0,
      vatBps: bpsFromPercent(jsonDouble(json['taxPct']) ?? 0),
      stock: tracked ? jsonDouble(json['stockQty']) ?? 0 : null,
    );
  }
}

/// The body of `POST products` and `PATCH products/{id}`.
class ProductInput {
  const ProductInput({
    required this.name,
    required this.nameBn,
    required this.code,
    required this.unit,
    required this.price,
    required this.vatBps,
  });

  final String name;
  final String nameBn;
  final String code;
  final String unit;
  final double price;
  final int vatBps;

  static String? _text(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toJson() => {
    'nameEn': name.trim(),
    'nameBn': _text(nameBn),
    'sku': _text(code),
    'unit': _text(unit),
    'price': price,
    'taxPct': percentFromBps(vatBps),
  }..removeWhere((_, value) => value == null);
}

class ProductQuery {
  const ProductQuery({this.search = ''});

  final String search;

  Map<String, dynamic> toQuery() =>
      {'q': search.trim().isEmpty ? null : search.trim()}
        ..removeWhere((_, value) => value == null);
}
