import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/settings/models/csv_import.dart';
import 'package:salesroot/features/settings/providers/import_providers.dart';
import 'package:salesroot/features/settings/view/widget/import_mapping.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #91: pick a CSV, map its columns to customer fields, check duplicates
/// and import.
class CsvImportScreen extends ConsumerWidget {
  const CsvImportScreen({super.key});

  static const _maxBytes = 5 * 1024 * 1024;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(csvImportProvider);
    final table = state.table;
    final result = state.result;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsImportTitle,
        actions: const [LanguageAction()],
      ),
      footer: table != null && result == null
          ? SrButton(
              label: l10n.settingsImportStart(
                context.fmt.number(table.rows.length),
              ),
              icon: Icons.upload_rounded,
              expand: true,
              loading: state.starting,
              onPressed: state.canStart
                  ? () => ref.read(csvImportProvider.notifier).start()
                  : null,
            )
          : null,
      body: switch ((table, result)) {
        (_, final ImportResult result) => _Done(result: result),
        (final CsvTable table, null) => ImportMapping(
          table: table,
          state: state,
          onPick: () => pick(context, ref),
        ),
        (null, null) => _PickPrompt(
          unreadable: state.unreadable,
          onPick: () => pick(context, ref),
        ),
      },
    );
  }

  static Future<void> pick(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (file == null) return;
    final size = await file.length() ?? 0;
    if (size > _maxBytes) {
      if (context.mounted) showSrError(context, l10n.settingsImportTooLarge);
      return;
    }
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    await ref.read(csvImportProvider.notifier).load(file.name, bytes);
  }
}

class _PickPrompt extends StatelessWidget {
  const _PickPrompt({required this.unreadable, required this.onPick});

  final bool unreadable;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: screenPadding,
      children: [
        FileTile(
          title: l10n.settingsImportChoose,
          subtitle: l10n.settingsImportChooseHint,
          onTap: onPick,
        ),
        const SizedBox(height: 12),
        if (unreadable) ...[
          SrNote(
            tone: SrNoteTone.err,
            icon: Icons.error_outline_rounded,
            message: l10n.settingsImportUnreadable,
          ),
          const SizedBox(height: 12),
        ],
        SrNote(
          icon: Icons.info_outline_rounded,
          title: l10n.settingsImportFormatTitle,
          message: l10n.settingsImportFormatBody,
        ),
      ],
    );
  }
}

class _Done extends ConsumerWidget {
  const _Done({required this.result});

  final ImportResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    return ListView(
      padding: screenPadding,
      children: [
        SrCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const RowIcon(Icons.check_rounded, tone: SrAvatarTone.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.settingsImportDone,
                  style: AppText.sectionTitle(c.ink),
                ),
              ),
              Text(
                l10n.settingsImportRows(fmt.number(result.total)),
                style: AppText.rowTitle(c.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SrStatGrid(
          tiles: [
            SrKpiTile(
              label: l10n.settingsImportImported,
              value: fmt.number(result.imported),
            ),
            SrKpiTile(
              label: l10n.settingsImportDuplicates,
              value: fmt.number(result.duplicates),
            ),
            SrKpiTile(
              label: l10n.settingsImportFailed,
              value: fmt.number(result.failed),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (result.duplicates > 0)
          SrNote(
            tone: SrNoteTone.gold,
            icon: Icons.content_copy_rounded,
            message: l10n.settingsImportDuplicatesFlagged(
              fmt.number(result.duplicates),
            ),
          ),
        if (result.failed > 0) ...[
          const SizedBox(height: 8),
          SrNote(
            tone: SrNoteTone.err,
            icon: Icons.error_outline_rounded,
            message: l10n.settingsImportFailedHint(fmt.number(result.failed)),
          ),
        ],
        const SizedBox(height: 16),
        SrButton(
          label: l10n.settingsImportOpenCustomers,
          expand: true,
          onPressed: () => context.go(Routes.companies),
        ),
        const SizedBox(height: 8),
        SrButton(
          label: l10n.settingsImportAnother,
          variant: SrButtonVariant.secondary,
          expand: true,
          onPressed: () => ref.read(csvImportProvider.notifier).reset(),
        ),
      ],
    );
  }
}
