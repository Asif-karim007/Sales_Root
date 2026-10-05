import 'dart:convert';

import 'package:salesroot/core/format/app_date_utils.dart';

/// Tolerant readers for response fields: a wrong or missing type becomes null
/// or an empty list instead of a parse error.
T? jsonObject<T>(dynamic value, T Function(Map<String, dynamic>) build) =>
    value is Map<String, dynamic> ? build(value) : null;

List<T> jsonList<T>(dynamic value, T Function(Map<String, dynamic>) build) =>
    value is List
    ? [
        for (final item in value)
          if (item is Map<String, dynamic>) build(item),
      ]
    : const [];

List<int> jsonInts(dynamic value) => value is List
    ? [
        for (final item in value)
          if (item is num) item.toInt(),
      ]
    : const [];

List<String> jsonStrings(dynamic value) => value is List
    ? [
        for (final item in value)
          if (item is String) item,
      ]
    : const [];

/// An id as the server sends it: a UUID string, or a number from older rows.
String? jsonId(dynamic value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is num) return '${value.toInt()}';
  return null;
}

List<String> jsonIds(dynamic value) =>
    value is List ? [for (final item in value) ?jsonId(item)] : const [];

/// An object field, also when the server sends it as an encoded JSON string.
Map<String, dynamic> jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is! String || value.isEmpty) return const {};
  try {
    final decoded = jsonDecode(value);
    return decoded is Map<String, dynamic> ? decoded : const {};
  } on FormatException {
    return const {};
  }
}

int? jsonInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? jsonDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool jsonBool(dynamic value) => value == true;

DateTime? jsonDate(dynamic value) =>
    value is String ? AppDateUtils.fromApiUtcOrNull(value) : null;

String? jsonUtc(DateTime? value) =>
    value == null ? null : AppDateUtils.toApiUtc(value);

/// A system-defined label the server sends in both languages.
class LocalizedName {
  const LocalizedName(this.en, this.bn);

  final String en;
  final String bn;

  String of(bool bangla) => bangla && bn.isNotEmpty ? bn : en;

  factory LocalizedName.fromJson(Map<String, dynamic> json) => LocalizedName(
    json['Name'] as String? ?? '',
    json['NameBn'] as String? ?? '',
  );

  /// The `<key>En` / `<key>Bn` pair, e.g. `nameEn` and `nameBn`.
  factory LocalizedName.pair(
    Map<String, dynamic> json, [
    String key = 'name',
  ]) => LocalizedName(
    json['${key}En'] as String? ?? json[key] as String? ?? '',
    json['${key}Bn'] as String? ?? '',
  );

  /// A `{en, bn}` object, as error messages and labels come.
  factory LocalizedName.of(dynamic value) => value is Map
      ? LocalizedName('${value['en'] ?? ''}', '${value['bn'] ?? ''}')
      : LocalizedName(value is String ? value : '', '');
}
