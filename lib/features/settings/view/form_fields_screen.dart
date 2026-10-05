import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/providers/settings_providers.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #90: the fields the workspace's industry pack adds to the lead and
/// customer forms.
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
    final fields = ref.watch(formFieldsProvider(_form));
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsFormFields,
        actions: const [LanguageAction()],
        bottom: SrSegmented(
          segments: [
            SrSegment(l10n.settingsFieldsLead),
            SrSegment(l10n.settingsFieldsCompany),
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
            SrRowGroup(rows: [for (final field in list) _FieldRow(field)]),
            const SizedBox(height: 12),
            SrNote(
              icon: Icons.info_outline_rounded,
              message: l10n.settingsFieldsNote,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow(this.field);

  final FormFieldConfig field;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrListRow(
      title: field.label.of(context.fmt.isBangla),
      subtitle: [
        _typeLabel(l10n, field.type),
        if (field.options.isNotEmpty) field.options.join(', '),
      ].join(' · '),
      leading: RowIcon(_typeIcon(field.type)),
    );
  }

  static String _typeLabel(AppLocalizations l10n, FieldType type) =>
      switch (type) {
        FieldType.text => l10n.settingsFieldText,
        FieldType.phone => l10n.settingsFieldPhone,
        FieldType.email => l10n.settingsFieldEmail,
        FieldType.choice => l10n.settingsFieldChoice,
        FieldType.money => l10n.settingsFieldMoney,
        FieldType.number => l10n.settingsFieldNumber,
        FieldType.yesNo => l10n.settingsFieldYesNo,
        FieldType.date => l10n.settingsFieldDate,
      };

  static IconData _typeIcon(FieldType type) => switch (type) {
    FieldType.text => Icons.short_text_rounded,
    FieldType.phone => Icons.call_outlined,
    FieldType.email => Icons.alternate_email_rounded,
    FieldType.choice => Icons.checklist_rounded,
    FieldType.money => Icons.payments_outlined,
    FieldType.number => Icons.pin_outlined,
    FieldType.yesNo => Icons.toggle_on_outlined,
    FieldType.date => Icons.event_outlined,
  };
}
