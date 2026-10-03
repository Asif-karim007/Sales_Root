import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';
import 'package:salesroot/features/settings/providers/sync_providers.dart';
import 'package:salesroot/features/settings/view/widget/settings_widgets.dart';
import 'package:salesroot/features/settings/view/widget/sync_rows.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #93: for each field changed on both sides, keep the phone's value or the
/// server's; the other one goes to the record's timeline.
class ConflictScreen extends ConsumerStatefulWidget {
  const ConflictScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<ConflictScreen> createState() => _ConflictScreenState();
}

class _ConflictScreenState extends ConsumerState<ConflictScreen> {
  bool _saving = false;

  Future<void> _resolve(Map<String, ConflictSide> choices) async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref.read(syncProvider.notifier).resolve(widget.id, choices);
      if (!mounted) return;
      showSrSuccess(context, l10n.settingsConflictResolved);
      Navigator.of(context).maybePop();
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSrError(
        context,
        failure.isOffline ? l10n.settingsConflictOffline : failure.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final conflict = ref.watch(syncConflictProvider(widget.id));
    final choices = ref.watch(conflictChoicesProvider(widget.id));
    final loaded = conflict.value;
    final multi = loaded != null && loaded.fields.length > 1;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.settingsConflictTitle,
        actions: const [LanguageAction()],
      ),
      footer: multi
          ? SrButton(
              label: l10n.settingsConflictSave,
              expand: true,
              loading: _saving,
              onPressed: !_saving && choices.length == loaded.fields.length
                  ? () => _resolve(choices)
                  : null,
            )
          : null,
      body: SrAsyncView(
        value: conflict,
        onRetry: () => ref.invalidate(syncConflictProvider(widget.id)),
        data: (context, conflict) => ListView(
          padding: screenPadding,
          children: [
            SrNote(
              tone: SrNoteTone.gold,
              icon: Icons.call_split_rounded,
              message: l10n.settingsConflictIntro,
            ),
            const SizedBox(height: 12),
            _RecordCard(conflict: conflict),
            for (final field in conflict.fields) ...[
              const SizedBox(height: 16),
              if (multi) ...[
                SrSectionHeader(title: field.label.of(context.fmt.isBangla)),
                const SizedBox(height: 8),
              ],
              _FieldChoice(
                field: field,
                chosen: choices[field.field],
                busy: _saving,
                onChoose: (side) => multi
                    ? ref
                          .read(conflictChoicesProvider(widget.id).notifier)
                          .choose(field.field, side)
                    : _resolve({field.field: side}),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              l10n.settingsConflictTimeline,
              textAlign: TextAlign.center,
              style: AppText.meta(SrColors.of(context).ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.conflict});

  final SyncConflict conflict;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final route = switch (conflict.entity) {
      SyncEntity.lead => Routes.leadFor(conflict.entityId),
      SyncEntity.contact => Routes.contactFor(conflict.entityId),
      _ => null,
    };
    return SrCard(
      padding: EdgeInsets.zero,
      child: SrListRow(
        title: conflict.title,
        subtitle: [
          entityLabel(l10n, conflict.entity),
          conflict.fields.map((f) => f.label.of(bangla)).join(', '),
        ].join(' · '),
        leading: SrAvatar(name: conflict.title),
        chevron: route != null,
        onTap: route == null ? null : () => context.push(route),
      ),
    );
  }
}

class _FieldChoice extends StatelessWidget {
  const _FieldChoice({
    required this.field,
    required this.chosen,
    required this.busy,
    required this.onChoose,
  });

  final ConflictField field;
  final ConflictSide? chosen;
  final bool busy;
  final ValueChanged<ConflictSide> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final local = field.local;
    final server = field.server;
    final large = field.kind != ConflictValueKind.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VersionCard(
          title: l10n.settingsConflictPhone,
          value: conflictValue(context, field.kind, local),
          meta: _meta(context, local.at, l10n.settingsConflictYou),
          large: large,
          selected: chosen == ConflictSide.local,
          primary: chosen == null || chosen == ConflictSide.local,
          busy: busy,
          onKeep: () => onChoose(ConflictSide.local),
        ),
        const SizedBox(height: 10),
        _VersionCard(
          title: l10n.settingsConflictServer,
          value: conflictValue(context, field.kind, server),
          meta: _meta(context, server.at, server.by),
          large: large,
          selected: chosen == ConflictSide.server,
          primary: chosen == ConflictSide.server,
          busy: busy,
          onKeep: () => onChoose(ConflictSide.server),
        ),
      ],
    );
  }

  static String _meta(BuildContext context, DateTime? at, String by) =>
      [if (at != null) context.fmt.dayTime(at), by].join(' · ');
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.title,
    required this.value,
    required this.meta,
    required this.large,
    required this.selected,
    required this.primary,
    required this.busy,
    required this.onKeep,
  });

  final String title;
  final String value;
  final String meta;
  final bool large;
  final bool selected;
  final bool primary;
  final bool busy;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return SrCard(
      tone: selected || primary ? SrCardTone.tint : SrCardTone.plain,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label(c.ink2)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: large
                      ? AppText.metric(c.ink, size: 20)
                      : AppText.body(c.ink, size: 14),
                ),
                const SizedBox(height: 4),
                Text(meta, style: AppText.meta(c.ink2, size: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SrButton(
            label: selected
                ? l10n.settingsConflictKept
                : l10n.settingsConflictKeep,
            icon: selected ? Icons.check_rounded : null,
            size: SrButtonSize.sm,
            variant: primary
                ? SrButtonVariant.primary
                : SrButtonVariant.secondary,
            onPressed: busy ? null : onKeep,
          ),
        ],
      ),
    );
  }
}
