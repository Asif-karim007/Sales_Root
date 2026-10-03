import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/settings/models/csv_import.dart';
import 'package:salesroot/features/settings/providers/import_providers.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

String importFieldLabel(AppLocalizations l10n, ImportField field) =>
    switch (field) {
      ImportField.name => l10n.settingsImportFieldName,
      ImportField.mobile => l10n.settingsImportFieldMobile,
      ImportField.company => l10n.settingsImportFieldCompany,
      ImportField.email => l10n.settingsImportFieldEmail,
      ImportField.designation => l10n.settingsImportFieldDesignation,
      ImportField.stage => l10n.settingsImportFieldStage,
      ImportField.value => l10n.settingsImportFieldValue,
      ImportField.source => l10n.settingsImportFieldSource,
      ImportField.note => l10n.settingsImportFieldNote,
      ImportField.skip => l10n.settingsImportFieldSkip,
    };

/// The picked file, its column mapping, a preview and the duplicate check.
class ImportMapping extends ConsumerWidget {
  const ImportMapping({
    super.key,
    required this.table,
    required this.state,
    required this.onPick,
  });

  final CsvTable table;
  final CsvImportState state;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final failure = state.failure;
    return ListView(
      padding: screenPadding,
      children: [
        FileTile(
          title: table.fileName,
          subtitle: l10n.settingsImportFileSize(
            fmt.number(table.rows.length),
            fmt.number(table.headers.length),
          ),
          onTap: onPick,
        ),
        if (failure != null) ...[
          const SizedBox(height: 12),
          _Failure(failure: failure),
        ],
        const SizedBox(height: 18),
        SrRowGroup(
          title: l10n.settingsImportMap,
          rows: [
            for (var i = 0; i < table.headers.length; i++)
              _ColumnRow(table: table, column: i, field: state.mapping[i]),
          ],
        ),
        const SizedBox(height: 12),
        ..._notes(context),
        if (table.rows.isNotEmpty) ...[
          const SizedBox(height: 18),
          _Preview(table: table, state: state),
        ],
      ],
    );
  }

  List<Widget> _notes(BuildContext context) {
    final l10n = context.l10n;
    final missing = state.missing;
    return [
      if (table.rows.isEmpty)
        SrNote(tone: SrNoteTone.err, message: l10n.settingsImportNoRows)
      else if (missing.isNotEmpty)
        SrNote(
          tone: SrNoteTone.err,
          icon: Icons.link_off_rounded,
          message: l10n.settingsImportMissing(
            missing.map((f) => importFieldLabel(l10n, f)).join(', '),
          ),
        ),
      if (table.rows.isNotEmpty && missing.isEmpty) ...[
        state.duplicates.when(
          data: (rows) => rows.isEmpty
              ? SrNote(
                  icon: Icons.check_circle_outline_rounded,
                  message: l10n.settingsImportNoDuplicates,
                )
              : SrNote(
                  tone: SrNoteTone.gold,
                  icon: Icons.content_copy_rounded,
                  message: l10n.settingsImportDuplicateRows(
                    context.fmt.number(rows.length),
                  ),
                ),
          loading: () => SrNote(
            tone: SrNoteTone.neutral,
            icon: Icons.hourglass_top_rounded,
            message: l10n.settingsImportChecking,
          ),
          error: (_, _) => SrNote(
            tone: SrNoteTone.neutral,
            icon: Icons.info_outline_rounded,
            message: l10n.settingsImportCheckFailed,
          ),
        ),
      ],
    ];
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    if (failure.isQuota) {
      return SrCard(
        child: SrPlanLocked(
          message: failure.message,
          onAction: () =>
              context.push('${Routes.planChoose}?reason=quota&kind=records'),
        ),
      );
    }
    return SrErrorState(error: failure, compact: true);
  }
}

class _ColumnRow extends ConsumerWidget {
  const _ColumnRow({
    required this.table,
    required this.column,
    required this.field,
  });

  final CsvTable table;
  final int column;
  final ImportField field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final sample = table.sample(column);
    final header = table.headers[column];
    return SrListRow(
      title: header.isEmpty ? l10n.settingsImportUnnamed : header,
      subtitle: sample.isEmpty ? null : l10n.settingsImportSample(sample),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_forward_rounded, size: 16, color: c.ink3),
          const SizedBox(width: 8),
          SrTag(
            importFieldLabel(l10n, field),
            tone: field == ImportField.skip ? SrTone.neutral : SrTone.accent,
          ),
        ],
      ),
      onTap: () => _choose(context, ref),
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final picked = await showSrSheet<ImportField>(
      context: context,
      builder: (_) => SrOptionSheet<ImportField>(
        title: l10n.settingsImportMapTo(table.headers[column]),
        options: ImportField.values,
        labelOf: (f) => importFieldLabel(l10n, f),
        subtitleOf: (f) => ImportField.required.contains(f)
            ? l10n.settingsFieldRequired
            : null,
        isSelected: (f) => f == field,
      ),
    );
    if (picked == null || !context.mounted) return;
    await ref.read(csvImportProvider.notifier).map(column, picked);
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.table, required this.state});

  static const _rows = 3;

  final CsvTable table;
  final CsvImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final duplicates = state.duplicates.value ?? const <int>{};
    String? cell(int row, ImportField field) {
      final column = state.mapping.indexOf(field);
      if (column < 0) return null;
      final value = table.rows[row][column].trim();
      return value.isEmpty ? null : value;
    }

    final count = table.rows.length < _rows ? table.rows.length : _rows;
    return SrRowGroup(
      title: l10n.settingsImportPreview,
      rows: [
        for (var i = 0; i < count; i++)
          SrListRow(
            title: cell(i, ImportField.name) ?? l10n.settingsImportNoName,
            subtitle: [
              ?cell(i, ImportField.mobile),
              ?cell(i, ImportField.company),
              ?cell(i, ImportField.stage),
            ].join(' · '),
            leading: Text(
              context.fmt.number(i + 1),
              style: AppText.meta(c.ink3),
            ),
            trailing: duplicates.contains(i)
                ? SrTag(l10n.settingsImportDuplicate, tone: SrTone.gold)
                : null,
          ),
      ],
    );
  }
}

/// The prototype's dashed upload tile.
class FileTile extends StatelessWidget {
  const FileTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      tone: SrCardTone.dashed,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          Icon(Icons.upload_file_rounded, size: 30, color: c.accent),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.rowTitle(c.ink),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppText.meta(c.ink2),
          ),
        ],
      ),
    );
  }
}
