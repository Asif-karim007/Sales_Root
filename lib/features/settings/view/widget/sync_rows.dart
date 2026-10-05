import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';
import 'package:salesroot/features/settings/providers/sync_providers.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A conflicting value as the user reads it: money in ৳, a date by day.
String conflictValue(
  BuildContext context,
  ConflictValueKind kind,
  String value,
) {
  final fmt = context.fmt;
  return switch (kind) {
    ConflictValueKind.money => fmt.money(num.tryParse(value) ?? 0),
    ConflictValueKind.date => switch (DateTime.tryParse(value)) {
      final DateTime date => fmt.date(date.toLocal()),
      null => value,
    },
    ConflictValueKind.text => value,
  };
}

/// A synced field by name; fields without a label show their server key.
String conflictFieldLabel(AppLocalizations l10n, String field) =>
    switch (field) {
      'title' => l10n.settingsSyncFieldTitle,
      'name' => l10n.settingsSyncFieldName,
      'amount' => l10n.settingsSyncFieldAmount,
      'phone' => l10n.settingsSyncFieldPhone,
      'note' || 'notes' => l10n.settingsSyncFieldNote,
      'dueAt' => l10n.settingsSyncFieldDue,
      _ => field,
    };

String entityLabel(AppLocalizations l10n, SyncEntity entity) =>
    switch (entity) {
      SyncEntity.lead => l10n.settingsEntityLead,
      SyncEntity.contact => l10n.settingsEntityContact,
      SyncEntity.company => l10n.settingsEntityCompany,
      SyncEntity.task => l10n.settingsEntityTask,
      SyncEntity.activity => l10n.settingsEntityActivity,
      SyncEntity.visit => l10n.settingsEntityVisit,
      SyncEntity.expense => l10n.settingsEntityExpense,
      SyncEntity.other => l10n.settingsEntityOther,
    };

class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({
    super.key,
    required this.snapshot,
    required this.offline,
    required this.network,
    required this.syncing,
    required this.onSync,
  });

  final SyncSnapshot snapshot;
  final bool offline;
  final String? network;
  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final pending = snapshot.pendingCount;
    final lastSync = snapshot.lastSyncAt;
    final (icon, tone, title, tag, tagTone) = offline
        ? (
            Icons.cloud_off_rounded,
            SrAvatarTone.danger,
            l10n.settingsSyncOffline,
            l10n.settingsSyncTagOffline,
            SrTone.err,
          )
        : pending > 0
        ? (
            Icons.cloud_upload_outlined,
            SrAvatarTone.gold,
            l10n.settingsSyncWaiting(fmt.number(pending)),
            l10n.settingsSyncTagPending,
            SrTone.warn,
          )
        : (
            Icons.cloud_done_outlined,
            SrAvatarTone.accent,
            l10n.settingsSyncAllDone,
            l10n.settingsSyncTagOk,
            SrTone.ok,
          );
    final details = [
      if (lastSync != null) l10n.settingsSyncLast(fmt.relative(lastSync)),
      if (snapshot.received > 0)
        l10n.settingsSyncReceived(fmt.number(snapshot.received)),
      ?network,
    ].join(' · ');
    return SrCard(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrListRow(
            title: title,
            subtitle: details.isEmpty ? null : details,
            leading: SrAvatar(icon: icon, tone: tone, size: 44),
            trailing: SrTag(tag, tone: tagTone),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SrButton(
              label: l10n.settingsSyncNow,
              icon: Icons.sync_rounded,
              size: SrButtonSize.sm,
              variant: SrButtonVariant.secondary,
              expand: true,
              loading: syncing,
              onPressed: syncing ? null : onSync,
            ),
          ),
        ],
      ),
    );
  }
}

class ConflictList extends StatelessWidget {
  const ConflictList({super.key, required this.conflicts});

  final List<SyncConflict> conflicts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrRowGroup(
      title: conflicts.length == 1
          ? l10n.settingsSyncOneConflict
          : l10n.settingsSyncConflictCount(
              context.fmt.number(conflicts.length),
            ),
      rows: [
        for (final conflict in conflicts)
          SrListRow(
            title: conflict.title,
            subtitle: [
              entityLabel(l10n, conflict.entity),
              conflict.fields
                  .map((f) => conflictFieldLabel(l10n, f.field))
                  .join(', '),
            ].join(' · '),
            leading: const RowIcon(
              Icons.call_split_rounded,
              tone: SrAvatarTone.danger,
            ),
            trailing: SrTag(l10n.settingsSyncView, tone: SrTone.err),
            chevron: true,
            onTap: () => context.push(Routes.syncConflictFor(conflict.id)),
          ),
      ],
    );
  }
}

class OutboxList extends ConsumerWidget {
  const OutboxList({super.key, required this.items, required this.onRetry});

  final List<OutboxItem> items;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrRowGroup(
      title: l10n.settingsSyncOutbox,
      rows: [
        for (final item in items)
          SrListRow(
            title: item.title,
            subtitle: [
              entityLabel(l10n, item.entity),
              _operation(l10n, item.operation),
              if (item.createdAt case final at?) fmt.dayTime(at),
            ].join(' · '),
            leading: RowIcon(
              item.failed
                  ? Icons.error_outline_rounded
                  : Icons.schedule_rounded,
              tone: item.failed ? SrAvatarTone.danger : SrAvatarTone.neutral,
            ),
            trailing: item.failed
                ? SrTag(l10n.settingsSyncFailed, tone: SrTone.err)
                : null,
            onTap: item.failed ? () => _failed(context, ref, item) : null,
          ),
      ],
    );
  }

  static String _operation(AppLocalizations l10n, OutboxOperation op) =>
      switch (op) {
        OutboxOperation.create => l10n.settingsSyncOpCreate,
        OutboxOperation.update => l10n.settingsSyncOpUpdate,
        OutboxOperation.delete => l10n.settingsSyncOpDelete,
      };

  Future<void> _failed(
    BuildContext context,
    WidgetRef ref,
    OutboxItem item,
  ) async {
    final l10n = context.l10n;
    final action = await showSrSheet<bool>(
      context: context,
      builder: (sheet) => SrConfirmSheet(
        title: l10n.settingsSyncFailedTitle,
        message: item.error?.of(context.fmt.isBangla) ?? '',
        icon: Icons.error_outline_rounded,
        tone: SrTone.err,
        primaryLabel: l10n.commonRetry,
        onPrimary: () => Navigator.of(sheet).pop(true),
        dangerLabel: l10n.settingsSyncDiscard,
        onDanger: () => Navigator.of(sheet).pop(false),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action) {
      onRetry();
      return;
    }
    await ref.read(syncProvider.notifier).discard(item.id);
  }
}

class ResolvedList extends StatelessWidget {
  const ResolvedList({super.key, required this.history});

  final List<ResolvedField> history;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return SrRowGroup(
      title: l10n.settingsSyncResolved,
      rows: [
        for (final r in history)
          SrListRow(
            title: '${r.title} · ${conflictFieldLabel(l10n, r.field)}',
            subtitle: l10n.settingsSyncResolvedLine(
              conflictValue(context, r.kind, r.kept),
              conflictValue(context, r.kind, r.discarded),
            ),
            leading: Icon(Icons.check_circle_outline_rounded, color: c.accent),
          ),
      ],
    );
  }
}
