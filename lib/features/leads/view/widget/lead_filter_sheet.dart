import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #23: stage, owner (team leads and owners only), source and temperature.
/// The button shows how many leads the draft would list.
class LeadFilterSheet extends ConsumerStatefulWidget {
  const LeadFilterSheet({super.key});

  @override
  ConsumerState<LeadFilterSheet> createState() => _LeadFilterSheetState();
}

class _LeadFilterSheetState extends ConsumerState<LeadFilterSheet> {
  late LeadFilter _draft = ref.read(leadFilterProvider);

  void _set(LeadFilter filter) => setState(() => _draft = filter);

  void _apply() {
    ref.read(leadFilterProvider.notifier).apply(_draft);
    Navigator.of(context).pop();
  }

  Future<void> _pickStage(List<LeadStage> stages) async {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final picked = await showSrSheet<_Choice>(
      context: context,
      builder: (context) => SrOptionSheet<_Choice>(
        title: l10n.leadsStage,
        options: [
          _Choice(null, l10n.leadsOpenStages),
          for (final s in stages) _Choice(s.id, s.name.of(bangla)),
        ],
        labelOf: (c) => c.label,
        isSelected: (c) => c.id == _draft.stageId,
      ),
    );
    if (picked == null || !mounted) return;
    _set(_draft.copyWith(stageId: () => picked.id));
  }

  Future<void> _pickSource() async {
    final l10n = context.l10n;
    final picked = await showSrSheet<_Choice>(
      context: context,
      builder: (context) => SrOptionSheet<_Choice>(
        title: l10n.leadsSource,
        options: [
          _Choice(null, l10n.commonAll),
          for (final s in LeadSource.values) _Choice(s.wire, s.label(l10n)),
        ],
        labelOf: (c) => c.label,
        isSelected: (c) => c.id == _draft.source,
      ),
    );
    if (picked == null || !mounted) return;
    _set(_draft.copyWith(source: () => picked.id));
  }

  Future<void> _pickOwner(LeadLookups lookups) async {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final choices = [
      _Owner(mine: true, label: l10n.leadsOwnerMe),
      _Owner(mine: false, label: l10n.leadsOwnerEveryone),
      for (final owner in lookups.owners)
        if (owner.id != lookups.currentMemberId)
          _Owner(
            mine: false,
            id: owner.id,
            label: owner.name.of(bangla),
            subtitle: owner.subtitle,
          ),
    ];
    final picked = await showSrSheet<_Owner>(
      context: context,
      builder: (_) => SrOptionSheet<_Owner>(
        title: l10n.leadsOwner,
        options: choices,
        labelOf: (o) => o.label,
        subtitleOf: (o) => o.subtitle,
        withAvatar: true,
        isSelected: (o) => o.mine == _draft.mine && o.id == _draft.ownerId,
      ),
    );
    if (picked == null || !mounted) return;
    _set(_draft.copyWith(mine: picked.mine, ownerId: () => picked.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = ref.watch(leadFilterPreviewProvider(_draft)).value;
    final level = ref.watch(experienceLevelProvider);
    final stages =
        ref.watch(leadStagesProvider).value?.columnsFor(level) ??
        const <LeadStage>[];
    final showOwner = ref.watch(currentRoleProvider) != WorkspaceRole.member;
    return SrSheet(
      title: l10n.commonFilter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SrAsyncView(
              value: ref.watch(leadLookupsProvider),
              loading: (_) => const SrSkeletonList(count: 4, shrinkWrap: true),
              onRetry: () => ref.invalidate(leadLookupsProvider),
              data: (context, lookups) => SingleChildScrollView(
                child: _fields(lookups, stages: stages, showOwner: showOwner),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SrButton(
                  label: l10n.commonClear,
                  variant: SrButtonVariant.secondary,
                  expand: true,
                  onPressed: () => _set(_draft.cleared()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SrButton(
                  label: preview == null
                      ? l10n.leadsShowLeads
                      : l10n.leadsShowCount(context.fmt.number(preview)),
                  expand: true,
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fields(
    LeadLookups lookups, {
    required List<LeadStage> stages,
    required bool showOwner,
  }) {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final ownerName = _draft.mine
        ? l10n.leadsOwnerMe
        : _draft.ownerId == null
        ? l10n.leadsOwnerEveryone
        : lookups.owners
                  .where((o) => o.id == _draft.ownerId)
                  .firstOrNull
                  ?.name
                  .of(bangla) ??
              l10n.leadsOwnerEveryone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrDropdownField(
          label: l10n.leadsStage,
          value:
              stages.byId(_draft.stageId)?.name.of(bangla) ??
              l10n.leadsOpenStages,
          onTap: () => _pickStage(stages),
        ),
        if (showOwner) ...[
          const SizedBox(height: 14),
          SrDropdownField(
            label: l10n.leadsOwner,
            value: ownerName,
            onTap: () => _pickOwner(lookups),
          ),
        ],
        const SizedBox(height: 14),
        SrDropdownField(
          label: l10n.leadsSource,
          value: leadSourceLabel(l10n, _draft.source) ?? l10n.commonAll,
          onTap: _pickSource,
        ),
        const SizedBox(height: 14),
        SrFieldLabel(l10n.leadsTemperature),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in LeadTemperature.values)
              SrChip(
                label: t.label(l10n),
                selected: _draft.temperature == t,
                onTap: () => _set(
                  _draft.copyWith(
                    temperature: () => _draft.temperature == t ? null : t,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Choice {
  const _Choice(this.id, this.label);

  final String? id;
  final String label;
}

class _Owner {
  const _Owner({
    required this.mine,
    required this.label,
    this.id,
    this.subtitle,
  });

  final bool mine;
  final String? id;
  final String label;
  final String? subtitle;
}
