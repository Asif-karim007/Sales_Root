import 'package:salesroot/core/utils/json_fields.dart';

/// A bilingual field the server sends as `<key>` and `<key>Bn`.
LocalizedName localizedField(Map<String, dynamic> json, String key) =>
    LocalizedName(
      json[key] as String? ?? '',
      json['${key}Bn'] as String? ?? '',
    );

/// A list of `{<key>, <key>Bn}` objects.
List<LocalizedName> localizedList(dynamic value, String key) =>
    jsonList(value, (item) => localizedField(item, key));

/// Folds the two-code-point forms of য়, ড় and ঢ় into their single code
/// points, so text typed on different keyboards compares equal.
String normalizeBangla(String text) => text
    .replaceAll('\u09AF\u09BC', '\u09DF')
    .replaceAll('\u09A1\u09BC', '\u09DC')
    .replaceAll('\u09A2\u09BC', '\u09DD');
