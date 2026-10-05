import 'package:salesroot/core/utils/json_fields.dart';

/// The forms the industry pack adds fields to: `leadFields` and
/// `companyFields`.
enum FormKind {
  lead('leadFields'),
  company('companyFields');

  const FormKind(this.packKey);

  final String packKey;
}

enum FieldType {
  text('text'),
  phone('phone'),
  email('email'),
  choice('select'),
  money('money'),
  number('number'),
  yesNo('boolean'),
  date('date');

  const FieldType(this.wire);

  final String wire;

  static FieldType fromWire(String? value) =>
      values.firstWhere((t) => t.wire == value, orElse: () => FieldType.text);
}

/// A field the workspace's industry pack adds to the lead or company form.
class FormFieldConfig {
  const FormFieldConfig({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
  });

  final String key;
  final LocalizedName label;
  final FieldType type;

  /// The values a choice field offers.
  final List<String> options;

  factory FormFieldConfig.fromJson(Map<String, dynamic> json) =>
      FormFieldConfig(
        key: json['key'] as String? ?? '',
        label: LocalizedName.of(json),
        type: FieldType.fromWire(json['type'] as String?),
        options: jsonStrings(json['options']),
      );
}
