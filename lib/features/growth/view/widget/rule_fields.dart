import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';
import 'package:salesroot/features/growth/providers/distribution_providers.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/features/growth/view/widget/inbox_actions.dart';
import 'package:salesroot/features/growth/view/widget/rule_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

typedef RuleEdit = void Function(RuleInput Function(RuleInput draft) edit);

/// The "If" card: source, area and form or campaign.
class RuleConditions extends ConsumerWidget {
  const RuleConditions({
    super.key,
    required this.draft,
    required this.enabled,
    required this.vocabulary,
    required this.onChange,
  });

  final RuleInput draft;
  final bool enabled;
  final RuleVocabulary vocabulary;
  final RuleEdit onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          SrDropdownField(
            label: l10n.growthRuleSource,
            value: vocabulary.sources(context, draft.sources),
            onTap: enabled ? () => _pickSources(context) : null,
          ),
          const SizedBox(height: 12),
          SrDropdownField(
            label: l10n.growthFieldArea,
            value: vocabulary.areaNames(context, draft.areas),
            onTap: enabled ? () => _pickAreas(context, ref) : null,
          ),
          const SizedBox(height: 12),
          SrDropdownField(
            label: l10n.growthRuleForm,
            value: vocabulary.forms(context, draft.forms),
            onTap: enabled ? () => _pickForms(context, ref) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _pickSources(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showSrSheet<List<InboxSource>>(
      context: context,
      builder: (_) => SrMultiOptionSheet<InboxSource>(
        title: l10n.growthRuleSource,
        options: InboxSource.values,
        labelOf: (s) => s.label(l10n),
        isSelected: (s) => draft.sources.contains(s.wire),
      ),
    );
    if (picked == null) return;
    onChange((d) => d.copyWith(sources: [for (final s in picked) s.wire]));
  }

  Future<void> _pickAreas(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final areas = await runGrowthAction(
      context,
      ref.read(ruleAreasProvider.future),
    );
    if (areas == null || !context.mounted) return;
    final picked = await showSrSheet<List<LocalizedName>>(
      context: context,
      builder: (_) => SrMultiOptionSheet<LocalizedName>(
        title: l10n.growthFieldArea,
        options: areas,
        labelOf: (a) => a.of(bangla),
        isSelected: (a) => draft.areas.contains(a.en),
      ),
    );
    if (picked == null) return;
    onChange((d) => d.copyWith(areas: [for (final a in picked) a.en]));
  }

  Future<void> _pickForms(BuildContext context, WidgetRef ref) async {
    final forms = await runGrowthAction(
      context,
      ref.read(ruleFormsProvider.future),
    );
    if (forms == null || !context.mounted) return;
    final picked = await showSrSheet<List<String>>(
      context: context,
      builder: (_) => SrMultiOptionSheet<String>(
        title: context.l10n.growthRuleForm,
        options: forms,
        labelOf: (f) => f,
        isSelected: draft.forms.contains,
      ),
    );
    if (picked == null) return;
    onChange((d) => d.copyWith(forms: picked));
  }
}

/// The "Then" card: who gets the lead, fallback and escalation.
class RuleAssignment extends ConsumerWidget {
  const RuleAssignment({
    super.key,
    required this.draft,
    required this.enabled,
    required this.vocabulary,
    required this.onChange,
    this.membersError,
  });

  final RuleInput draft;
  final bool enabled;
  final RuleVocabulary vocabulary;
  final RuleEdit onChange;
  final String? membersError;

  static const _escalations = [0, 5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final mode = draft.mode;
    final people = mode != AssignMode.queue;
    final escalate = draft.escalateMinutes;
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        children: [
          SrDropdownField(
            label: l10n.growthRuleAssign,
            value: mode.label(l10n),
            onTap: enabled ? () => _pickMode(context) : null,
          ),
          if (people) ...[
            const SizedBox(height: 12),
            SrDropdownField(
              label: mode == AssignMode.member
                  ? l10n.growthRuleMember
                  : l10n.growthRuleMembers(fmt.number(draft.memberIds.length)),
              value: vocabulary.memberNames(context, draft.memberIds),
              error: membersError,
              onTap: enabled ? () => _pickMembers(context, ref) : null,
            ),
            const SizedBox(height: 4),
            GrowthToggleRow(
              title: l10n.growthRuleCheckedIn,
              value: draft.onlyCheckedIn,
              onChanged: enabled
                  ? (v) => onChange((d) => d.copyWith(onlyCheckedIn: v))
                  : null,
            ),
            GrowthToggleRow(
              title: l10n.growthRuleSkipLeave,
              value: draft.skipOnLeave,
              onChanged: enabled
                  ? (v) => onChange((d) => d.copyWith(skipOnLeave: v))
                  : null,
            ),
            SrDropdownField(
              label: l10n.growthRuleFallback,
              value: vocabulary.member(context, draft.fallbackMemberId),
              onTap: enabled ? () => _pickFallback(context, ref) : null,
            ),
          ],
          const SizedBox(height: 12),
          SrDropdownField(
            label: l10n.growthRuleNoResponse,
            value: _escalationLabel(context, escalate),
            onTap: enabled ? () => _pickEscalation(context) : null,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _escalationLabel(BuildContext context, int? minutes) {
    final l10n = context.l10n;
    if (minutes == null || minutes == 0) return l10n.growthRuleNoEscalation;
    return l10n.growthRuleEscalateTo(context.fmt.number(minutes));
  }

  Future<void> _pickMode(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showSrSheet<AssignMode>(
      context: context,
      builder: (_) => SrOptionSheet<AssignMode>(
        title: l10n.growthRuleAssign,
        options: AssignMode.values,
        labelOf: (m) => m.label(l10n),
        subtitleOf: (m) => switch (m) {
          AssignMode.member => l10n.growthModeMemberHint,
          AssignMode.roundRobin => l10n.growthModeRoundRobinHint,
          AssignMode.byLoad => l10n.growthModeByLoadHint,
          AssignMode.queue => l10n.growthModeQueueHint,
        },
        isSelected: (m) => m == draft.mode,
      ),
    );
    if (picked == null) return;
    onChange(
      (d) => d.copyWith(
        mode: picked,
        memberIds: picked == AssignMode.member
            ? d.memberIds.take(1).toList()
            : d.memberIds,
      ),
    );
  }

  Future<void> _pickMembers(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (draft.mode == AssignMode.member) {
      final member = await pickGrowthMember(
        context,
        ref,
        title: l10n.growthRuleMember,
        selected: draft.memberIds.firstOrNull,
      );
      if (member == null) return;
      onChange((d) => d.copyWith(memberIds: [member.id]));
      return;
    }
    final members = await runGrowthAction(
      context,
      ref.read(growthMembersProvider.future),
    );
    if (members == null || !context.mounted) return;
    final fmt = context.fmt;
    final picked = await showSrSheet<List<GrowthMember>>(
      context: context,
      builder: (_) => SrMultiOptionSheet<GrowthMember>(
        title: l10n.growthRuleMembers(fmt.number(draft.memberIds.length)),
        options: members,
        withAvatar: true,
        labelOf: (m) => m.nameOf(fmt.isBangla),
        subtitleOf: (m) => m.onLeave
            ? l10n.growthMemberOnLeave
            : m.checkedIn
            ? l10n.growthMemberCheckedIn(fmt.number(m.openLeads))
            : l10n.growthMemberLoad(fmt.number(m.openLeads)),
        isSelected: (m) => draft.memberIds.contains(m.id),
      ),
    );
    if (picked == null) return;
    onChange((d) => d.copyWith(memberIds: [for (final m in picked) m.id]));
  }

  Future<void> _pickFallback(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final members = await runGrowthAction(
      context,
      ref.read(growthMembersProvider.future),
    );
    if (members == null || !context.mounted) return;
    final bangla = context.fmt.isBangla;
    final byId = {for (final m in members) m.id: m};
    const queue = 0;
    final picked = await showSrSheet<int>(
      context: context,
      builder: (_) => SrOptionSheet<int>(
        title: l10n.growthRuleFallback,
        options: [queue, ...byId.keys],
        labelOf: (id) => byId[id]?.nameOf(bangla) ?? l10n.growthModeQueue,
        isSelected: (id) => id == (draft.fallbackMemberId ?? queue),
      ),
    );
    if (picked == null) return;
    onChange(
      (d) =>
          d.copyWith(fallbackMemberId: () => picked == queue ? null : picked),
    );
  }

  Future<void> _pickEscalation(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showSrSheet<int>(
      context: context,
      builder: (_) => SrOptionSheet<int>(
        title: l10n.growthRuleNoResponse,
        options: _escalations,
        labelOf: (m) => _escalationLabel(context, m),
        isSelected: (m) => m == (draft.escalateMinutes ?? 0),
      ),
    );
    if (picked == null) return;
    onChange(
      (d) => d.copyWith(escalateMinutes: () => picked == 0 ? null : picked),
    );
  }
}

/// Days, hours and the per-member daily cap.
class RuleSchedule extends StatelessWidget {
  const RuleSchedule({
    super.key,
    required this.draft,
    required this.enabled,
    required this.onChange,
  });

  final RuleInput draft;
  final bool enabled;
  final RuleEdit onChange;

  /// Saturday first, as the Bangladeshi work week runs.
  static const _week = [6, 7, 1, 2, 3, 4, 5];
  static const _caps = [0, 5, 8, 10, 20, 50];
  static const _windows = <(int?, int?)>[(null, null), (9, 18), (18, 9)];

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final cap = draft.dailyCap;
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.growthRuleDays, style: AppText.fieldLabel(c.ink2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final day in _week)
                SrChip(
                  label: _dayName(l10n, day),
                  selected: draft.days.isEmpty || draft.days.contains(day),
                  onTap: enabled ? () => _toggleDay(day) : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          SrDropdownField(
            label: l10n.growthRuleHours,
            value: _windowLabel(context, (draft.fromHour, draft.toHour)),
            onTap: enabled ? () => _pickWindow(context) : null,
          ),
          const SizedBox(height: 12),
          SrDropdownField(
            label: l10n.growthRuleCap,
            value: cap == null
                ? l10n.growthRuleNoCap
                : l10n.growthRuleCapValue(fmt.number(cap)),
            onTap: enabled ? () => _pickCap(context) : null,
          ),
        ],
      ),
    );
  }

  void _toggleDay(int day) {
    final current = draft.days.isEmpty ? _week.toSet() : draft.days.toSet();
    current.contains(day) ? current.remove(day) : current.add(day);
    if (current.isEmpty) return;
    final days = current.length == _week.length
        ? <int>[]
        : [
            for (final d in _week)
              if (current.contains(d)) d,
          ];
    onChange((d) => d.copyWith(days: days));
  }

  String _windowLabel(BuildContext context, (int?, int?) window) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final (from, to) = window;
    if (from == null || to == null) return l10n.growthRuleAllDay;
    String at(int hour) => fmt.time(DateTime(2026, 1, 1, hour));
    return l10n.growthRuleBetween(at(from), at(to));
  }

  Future<void> _pickWindow(BuildContext context) async {
    final picked = await showSrSheet<(int?, int?)>(
      context: context,
      builder: (_) => SrOptionSheet<(int?, int?)>(
        title: context.l10n.growthRuleHours,
        options: _windows,
        labelOf: (w) => _windowLabel(context, w),
        isSelected: (w) => w == (draft.fromHour, draft.toHour),
      ),
    );
    if (picked == null) return;
    onChange((d) => d.copyWith(hours: picked));
  }

  Future<void> _pickCap(BuildContext context) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final picked = await showSrSheet<int>(
      context: context,
      builder: (_) => SrOptionSheet<int>(
        title: l10n.growthRuleCap,
        options: _caps,
        labelOf: (cap) => cap == 0
            ? l10n.growthRuleNoCap
            : l10n.growthRuleCapValue(fmt.number(cap)),
        isSelected: (cap) => cap == (draft.dailyCap ?? 0),
      ),
    );
    if (picked == null) return;
    onChange((d) => d.copyWith(dailyCap: () => picked == 0 ? null : picked));
  }

  String _dayName(AppLocalizations l10n, int day) => switch (day) {
    1 => l10n.growthDayMon,
    2 => l10n.growthDayTue,
    3 => l10n.growthDayWed,
    4 => l10n.growthDayThu,
    5 => l10n.growthDayFri,
    6 => l10n.growthDaySat,
    _ => l10n.growthDaySun,
  };
}
