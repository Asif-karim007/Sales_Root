import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/level_labels.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

String fieldTypeLabel(AppLocalizations l10n, FieldType type) => switch (type) {
  FieldType.text => l10n.settingsFieldText,
  FieldType.phone => l10n.settingsFieldPhone,
  FieldType.email => l10n.settingsFieldEmail,
  FieldType.multiChoice => l10n.settingsFieldMultiChoice,
  FieldType.money => l10n.settingsFieldMoney,
  FieldType.number => l10n.settingsFieldNumber,
  FieldType.yesNo => l10n.settingsFieldYesNo,
  FieldType.date => l10n.settingsFieldDate,
};

IconData fieldTypeIcon(FieldType type) => switch (type) {
  FieldType.text => Icons.short_text_rounded,
  FieldType.phone => Icons.call_outlined,
  FieldType.email => Icons.alternate_email_rounded,
  FieldType.multiChoice => Icons.checklist_rounded,
  FieldType.money => Icons.payments_outlined,
  FieldType.number => Icons.pin_outlined,
  FieldType.yesNo => Icons.toggle_on_outlined,
  FieldType.date => Icons.event_outlined,
};

Future<void> showFieldSheet(BuildContext context, FormFieldConfig field) =>
    showSrSheet<void>(
      context: context,
      builder: (_) => _FieldSheet(field: field),
    );

class _FieldSheet extends ConsumerStatefulWidget {
  const _FieldSheet({required this.field});

  final FormFieldConfig field;

  @override
  ConsumerState<_FieldSheet> createState() => _FieldSheetState();
}

class _FieldSheetState extends ConsumerState<_FieldSheet> {
  late bool _required = widget.field.required;
  late final Set<ExperienceLevel> _levels = {...widget.field.levels};
  String? _error;
  bool _busy = false;

  void _setRequired(bool on) => setState(() {
    _required = on;
    if (on) _levels.addAll(ExperienceLevel.values);
  });

  void _setLevel(ExperienceLevel level, bool on) => setState(() {
    on ? _levels.add(level) : _levels.remove(level);
    if (!on) _required = false;
  });

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final field = widget.field;
    try {
      await ref
          .read(formFieldsProvider(field.form).notifier)
          .save(field.id, FormFieldInput(required: _required, levels: _levels));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.fieldError('Levels') ?? failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final field = widget.field;
    final error = _error;
    return SrSheet(
      title: field.label.of(context.fmt.isBangla),
      subtitle: fieldTypeLabel(l10n, field.type),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ToggleRow(
              title: l10n.settingsFieldRequiredToggle,
              subtitle: l10n.settingsFieldRequiredHint,
              value: _required,
              onChanged: _setRequired,
            ),
            const SizedBox(height: 8),
            SrFieldLabel(l10n.settingsFieldShownIn),
            for (final level in ExperienceLevel.values)
              ToggleRow(
                title: level.label(l10n),
                subtitle: level.description(l10n),
                value: _levels.contains(level),
                onChanged: (on) => _setLevel(level, on),
              ),
            if (error != null) ...[
              const SizedBox(height: 8),
              SrNote(message: error, tone: SrNoteTone.err),
            ],
            const SizedBox(height: 16),
            SrButton(
              label: l10n.commonSave,
              expand: true,
              loading: _busy,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
