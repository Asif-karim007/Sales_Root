import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/field_sheet.dart';
import 'package:salesroot/features/settings/view/widget/level_labels.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #90: which levels show each lead and contact field, and which are
/// required.
class FormFieldsScreen extends ConsumerStatefulWidget {
  const FormFieldsScreen({super.key});

  @override
  ConsumerState<FormFieldsScreen> createState() => _FormFieldsScreenState();
}

class _FormFieldsScreenState extends ConsumerState<FormFieldsScreen> {
  FormKind _form = FormKind.lead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canEdit = ref.watch(
      moduleAccessProvider(AppModule.formFields).select((a) => a.canEdit),
    );
    final fields = ref.watch(formFieldsProvider(_form));
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsFormFields,
        subtitle: canEdit ? null : l10n.settingsViewOnly,
        actions: const [LanguageAction()],
        bottom: SrSegmented(
          segments: [
            SrSegment(l10n.settingsFieldsLead),
            SrSegment(l10n.settingsFieldsContact),
          ],
          index: _form.index,
          onChanged: (i) => setState(() => _form = FormKind.values[i]),
        ),
      ),
      body: SrAsyncView(
        value: fields,
        onRetry: () => ref.invalidate(formFieldsProvider(_form)),
        isEmpty: (list) => list.isEmpty,
        data: (context, list) => ListView(
          padding: screenPadding,
          children: [
            SrRowGroup(
              rows: [
                for (final field in list)
                  _FieldRow(field: field, canEdit: canEdit),
              ],
            ),
            const SizedBox(height: 12),
            SrNote(
              icon: Icons.info_outline_rounded,
              message: canEdit
                  ? l10n.settingsFieldsNote
                  : l10n.settingsFieldsNoteViewOnly,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends ConsumerWidget {
  const _FieldRow({required this.field, required this.canEdit});

  final FormFieldConfig field;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final editable = canEdit && !field.isSystem;
    final template = field.template;
    return SrListRow(
      title: field.label.of(context.fmt.isBangla),
      subtitle: [
        fieldTypeLabel(l10n, field.type),
        if (field.required) l10n.settingsFieldRequired,
        if (template != null) l10n.settingsFieldTemplate(template),
      ].join(' · '),
      leading: RowIcon(fieldTypeIcon(field.type)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final level in ExperienceLevel.values) ...[
            if (level != ExperienceLevel.easy) const SizedBox(width: 4),
            _LevelChip(
              level: level,
              on: field.levels.contains(level),
              onTap: editable ? () => _toggle(context, ref, level) : null,
            ),
          ],
        ],
      ),
      onTap: editable ? () => showFieldSheet(context, field) : null,
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    ExperienceLevel level,
  ) async {
    final levels = {...field.levels};
    if (!levels.remove(level)) levels.add(level);
    try {
      await ref
          .read(formFieldsProvider(field.form).notifier)
          .save(
            field.id,
            FormFieldInput(required: field.required, levels: levels),
          );
    } on ApiFailure catch (failure) {
      if (!context.mounted) return;
      showSrError(context, failure.message);
    }
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level, required this.on, this.onTap});

  final ExperienceLevel level;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: level.label(l10n),
      toggled: on,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SrTag(
            level.letter(l10n),
            tone: on ? SrTone.accent : SrTone.neutral,
          ),
        ),
      ),
    );
  }
}
