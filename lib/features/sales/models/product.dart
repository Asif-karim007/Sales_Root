import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';

enum PriceList {
  list('List'),
  dealer('Dealer');

  const PriceList(this.wire);

  final String wire;

  static PriceList fromWire(String? value) =>
      value == dealer.wire ? dealer : list;
}

enum ProductCategory {
  solar('Solar'),
  inverters('Inverters'),
  batteries('Batteries'),
  accessories('Accessories'),
  lighting('Lighting'),
  pumps('Pumps'),
  services('Services');

  const ProductCategory(this.wire);

  final String wire;

  static ProductCategory fromWire(String? value) => values.firstWhere(
    (c) => c.wire == value,
    orElse: () => ProductCategory.accessories,
  );
}

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.nameBn,
    required this.category,
    required this.unit,
    required this.price,
    required this.dealerPrice,
    this.vatBps = standardVatBps,
    this.stock,
  });

  final int id;
  final String code;
  final String name;
  final String nameBn;
  final ProductCategory category;

  /// The selling unit as the server sends it: piece, metre, per kW, set…
  final String unit;
  final int price;
  final int dealerPrice;
  final int vatBps;

  /// Units in stock; null for services, which have none.
  final int? stock;

  String nameIn({required bool bangla}) =>
      LocalizedName(name, nameBn).of(bangla);

  bool get isService => category == ProductCategory.services;
  bool get sameInAllLists => price == dealerPrice;

  int priceIn(PriceList list) => switch (list) {
    PriceList.list => price,
    PriceList.dealer => dealerPrice,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: jsonInt(json['Id']) ?? 0,
    code: json['Code'] as String? ?? '',
    name: json['Name'] as String? ?? '',
    nameBn: json['NameBn'] as String? ?? '',
    category: ProductCategory.fromWire(json['Category'] as String?),
    unit: json['Unit'] as String? ?? '',
    price: jsonInt(json['Price']) ?? 0,
    dealerPrice: jsonInt(json['DealerPrice']) ?? jsonInt(json['Price']) ?? 0,
    vatBps: jsonInt(json['VatBps']) ?? standardVatBps,
    stock: jsonInt(json['Stock']),
  );
}

class ProductQuery {
  const ProductQuery({this.search = '', this.category, this.page = 1});

  final String search;
  final ProductCategory? category;
  final int page;

  ProductQuery atPage(int page) =>
      ProductQuery(search: search, category: category, page: page);

  Map<String, dynamic> toQuery() => {
    'Search': search.trim().isEmpty ? null : search.trim(),
    'Category': category?.wire,
    'Page': page,
    'PageSize': 20,
  }..removeWhere((_, value) => value == null);
}
