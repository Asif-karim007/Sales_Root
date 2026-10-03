import 'package:salesroot/core/utils/json_fields.dart';

/// A person or place sent as `<Key>` + `<Key>Bn`; null when [name] is absent.
LocalizedName? jsonLocalized(dynamic name, dynamic nameBn) =>
    name is String ? LocalizedName(name, nameBn is String ? nameBn : '') : null;

/// Like [jsonLocalized], falling back to an empty name.
LocalizedName jsonLocalizedOrEmpty(dynamic name, dynamic nameBn) =>
    jsonLocalized(name, nameBn) ?? const LocalizedName('', '');

/// The trimmed text, or null when blank, so write bodies omit the key.
String? trimmedOrNull(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}
