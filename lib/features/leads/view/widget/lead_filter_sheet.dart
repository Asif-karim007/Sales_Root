import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// #23: stage, owner (team leads and owners only), source, temperature,
/// deal value, created date and tags. The button shows how many leads the
/// draft would list.
class LeadFilterSheet extends ConsumerStatefulWidget {
  const LeadFilterSheet({super.key});

  @override
  ConsumerState<LeadFilterSheet> createState() => _LeadFilterSheetState();
}

class _LeadFilterSheetState extends ConsumerState<LeadFilterSheet> {
  late LeadFilter _draft = ref.read(leadFilterProvider);
  late final _min = TextEditingController(text: _amountText(_draft.minValue));
  late final _max = TextEditingController(text: _amountText(_draft.maxValue));
  Timer? _debounce;

  static String _amountText(double? value) =>
      value == null ? '' : value.round().toString();

  @override
  void dispose() {
    _debounce?.cancel();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _set(LeadFilter filter) => setState(() => _draft = filter);

  void _onAmount(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final min = double.tryParse(_min.text);
      final max = double.tryParse(_max.text);
      _set(_draft.copyWith(minValue: () => min, maxValue: () => max));
    });
  }

  void _clear() {
    _min.clear();
    _max.clear();
    _set(_draft.cleared());
  }

  void _apply() {
    ref.read(leadFilterProvider.notifier).apply(_draft);
    Navigator.of(context).pop();
  }

  Future<void> _pickStages(List<LeadStage> stages) async {
    final bangla = context.fmt.isBangla;
    final picked = await showSrSheet<List<LeadStage>>(
      context: context,
      builder: (context) => SrMultiOptionSheet<LeadStage>(
        title: context.l10n.leadsStage,
        options: stages,
        labelOf: (s) => s.name.of(bangla),
        isSelected: (s) => _draft.stageIds.contains(s.id),
      ),
    );
    if (picked == null || !mounted) return;
    _set(_draft.copyWith(stageIds: {for (final s in picked) s.id}));
  }

  Future<void> _pickOptions(
    String title,
    List<LeadOption> options,
    Set<int> selected,
    LeadFilter Function(Set<int>) change,
  ) async {
    final bangla = context.fmt.isBangla;
    final picked = await showSrSheet<List<LeadOption>>(
      context: context,
      builder: (_) => SrMultiOptionSheet<LeadOption>(
        title: title,
        options: options,
        labelOf: (o) => o.name.of(bangla),
        isSelected: (o) => selected.contains(o.id),
      ),
    );
    if (picked == null || !mounted) return;
    _set(change({for (final o in picked) o.id}));
  }

  Future<void> _pickOwner(LeadLookups lookups) async {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final choices = [
      _Owner(mine: true, label: l10n.leadsOwnerMe),
      _Owner(mine: false, label: l10n.leadsOwnerEveryone),
      for (final owner in lookups.owners)
        if (owner.id != lookups.currentEmployeeId)
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

  String _summary(List<String> labels, String none) {
    if (labels.isEmpty) return none;
    if (labels.length == 1) return labels.first;
    return context.l10n.leadsAndMore(
      labels.first,
      context.fmt.number(labels.length - 1),
    );
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
                  onPressed: _clear,
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
    String names(List<LeadOption> options, Set<int> ids) => _summary([
      for (final o in options)
        if (ids.contains(o.id)) o.name.of(bangla),
    ], l10n.commonAll);
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
          value: _summary([
            for (final s in stages)
              if (_draft.stageIds.contains(s.id)) s.name.of(bangla),
          ], l10n.leadsOpenStages),
          onTap: () => _pickStages(stages),
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
          value: names(lookups.sources, _draft.sourceIds),
          onTap: () => _pickOptions(
            l10n.leadsSource,
            lookups.sources,
            _draft.sourceIds,
            (ids) => _draft.copyWith(sourceIds: ids),
          ),
        ),
        const SizedBox(height: 14),
        _ChipField<LeadTemperature>(
          label: l10n.leadsTemperature,
          options: LeadTemperature.values,
          labelOf: (t) => t.label(l10n),
          isSelected: (t) => _draft.temperatures.contains(t),
          onTap: (t) {
            final next = {..._draft.temperatures};
            if (!next.remove(t)) next.add(t);
            _set(_draft.copyWith(temperatures: next));
          },
        ),
        const SizedBox(height: 14),
        SrFieldLabel(l10n.leadsDealValue),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _amountField(_min, l10n.leadsMinValue)),
            const SizedBox(width: 10),
            Expanded(child: _amountField(_max, l10n.leadsMaxValue)),
          ],
        ),
        const SizedBox(height: 14),
        _ChipField<LeadCreatedWithin?>(
          label: l10n.leadsCreated,
          options: const [null, ...LeadCreatedWithin.values],
          labelOf: (w) => w?.label(l10n) ?? l10n.leadsAnyTime,
          isSelected: (w) => _draft.createdWithin == w,
          onTap: (w) => _set(_draft.copyWith(createdWithin: () => w)),
        ),
        const SizedBox(height: 14),
        SrDropdownField(
          label: l10n.leadsTags,
          value: names(lookups.tags, _draft.tagIds),
          onTap: () => _pickOptions(
            l10n.leadsTags,
            lookups.tags,
            _draft.tagIds,
            (ids) => _draft.copyWith(tagIds: ids),
          ),
        ),
      ],
    );
  }

  Widget _amountField(TextEditingController controller, String hint) =>
      SrTextField(
        controller: controller,
        hint: hint,
        suffixText: '৳',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: _onAmount,
      );
}

class _Owner {
  const _Owner({
    required this.mine,
    required this.label,
    this.id,
    this.subtitle,
  });

  final bool mine;
  final int? id;
  final String label;
  final String? subtitle;
}

class _ChipField<T> extends StatelessWidget {
  const _ChipField({
    required this.label,
    required this.options,
    required this.labelOf,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final List<T> options;
  final String Function(T) labelOf;
  final bool Function(T) isSelected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SrFieldLabel(label),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final option in options)
            SrChip(
              label: labelOf(option),
              selected: isSelected(option),
              onTap: () => onTap(option),
            ),
        ],
      ),
    ],
  );
}
