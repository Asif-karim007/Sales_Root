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
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #91: pick a CSV, map its columns to lead fields, check duplicates and
/// import.
class CsvImportScreen extends ConsumerWidget {
  const CsvImportScreen({super.key});

  static const _maxBytes = 5 * 1024 * 1024;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(csvImportProvider);
    final table = state.table;
    final job = state.job;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsImportTitle,
        actions: const [LanguageAction()],
      ),
      footer: table != null && job == null
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
      body: switch ((table, job)) {
        (_, final ImportJob job) => _Progress(job: job),
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

class _Progress extends ConsumerWidget {
  const _Progress({required this.job});

  final ImportJob job;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RowIcon(
                    job.done ? Icons.check_rounded : Icons.upload_rounded,
                    tone: SrAvatarTone.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      job.done
                          ? l10n.settingsImportDone
                          : l10n.settingsImportRunning,
                      style: AppText.sectionTitle(c.ink),
                    ),
                  ),
                  Text(
                    fmt.percent(job.progress * 100),
                    style: AppText.rowTitle(c.ink2),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SrProgressBar(value: job.progress),
              const SizedBox(height: 8),
              Text(
                l10n.settingsImportProcessed(
                  fmt.number(job.processed),
                  fmt.number(job.total),
                ),
                style: AppText.meta(c.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SrStatGrid(
          tiles: [
            SrKpiTile(
              label: l10n.settingsImportImported,
              value: fmt.number(job.imported),
            ),
            SrKpiTile(
              label: l10n.settingsImportDuplicates,
              value: fmt.number(job.duplicates),
            ),
            SrKpiTile(
              label: l10n.settingsImportFailed,
              value: fmt.number(job.failed),
            ),
          ],
        ),
        if (job.done) ...[
          const SizedBox(height: 12),
          if (job.duplicates > 0)
            SrNote(
              tone: SrNoteTone.gold,
              icon: Icons.content_copy_rounded,
              message: l10n.settingsImportDuplicatesFlagged(
                fmt.number(job.duplicates),
              ),
            ),
          if (job.failed > 0) ...[
            const SizedBox(height: 8),
            SrNote(
              tone: SrNoteTone.err,
              icon: Icons.error_outline_rounded,
              message: l10n.settingsImportFailedHint(fmt.number(job.failed)),
            ),
          ],
          const SizedBox(height: 16),
          SrButton(
            label: l10n.settingsImportOpenLeads,
            expand: true,
            onPressed: () => context.go(Routes.leads),
          ),
          const SizedBox(height: 8),
          SrButton(
            label: l10n.settingsImportAnother,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () => ref.read(csvImportProvider.notifier).reset(),
          ),
        ],
      ],
    );
  }
}
