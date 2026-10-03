import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum FormKind {
  lead('Lead'),
  contact('Contact');

  const FormKind(this.wire);

  final String wire;
}

enum FieldType {
  text('Text'),
  phone('Phone'),
  email('Email'),
  multiChoice('MultiChoice'),
  money('Money'),
  number('Number'),
  yesNo('YesNo'),
  date('Date');

  const FieldType(this.wire);

  final String wire;

  static FieldType fromWire(String? value) =>
      values.firstWhere((t) => t.wire == value, orElse: () => FieldType.text);
}

/// One field on the lead or contact form, and the levels that show it.
class FormFieldConfig {
  const FormFieldConfig({
    required this.id,
    required this.form,
    required this.label,
    required this.type,
    required this.required,
    required this.isSystem,
    required this.levels,
    this.template,
  });

  final int id;
  final FormKind form;
  final LocalizedName label;
  final FieldType type;
  final bool required;

  /// Built-in fields that are always shown and always required.
  final bool isSystem;
  final Set<ExperienceLevel> levels;

  /// The industry template that added the field, e.g. `Solar`.
  final String? template;

  factory FormFieldConfig.fromJson(Map<String, dynamic> json) =>
      FormFieldConfig(
        id: jsonInt(json['Id']) ?? 0,
        form: json['Form'] == FormKind.contact.wire
            ? FormKind.contact
            : FormKind.lead,
        label: LocalizedName.fromJson(json),
        type: FieldType.fromWire(json['Type'] as String?),
        required: jsonBool(json['Required']),
        isSystem: jsonBool(json['IsSystem']),
        levels: {
          for (final wire in jsonStrings(json['Levels']))
            ?ExperienceLevel.fromWire(wire),
        },
        template: json['Template'] as String?,
      );
}

class FormFieldInput {
  const FormFieldInput({required this.required, required this.levels});

  final bool required;
  final Set<ExperienceLevel> levels;

  Map<String, dynamic> toJson() => {
    'Required': required,
    'Levels': [
      for (final level in ExperienceLevel.values)
        if (levels.contains(level)) level.wire,
    ],
  };
}
