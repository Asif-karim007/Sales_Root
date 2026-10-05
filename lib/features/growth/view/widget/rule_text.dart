import 'package:flutter/widgets.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/translations/translations.dart';

/// Names and labels a rule's conditions and actions are written with.
class RuleVocabulary {
  const RuleVocabulary({this.members = const {}, this.areas = const {}});

  final Map<String, GrowthMember> members;

  /// Keyed by the English area name rules store.
  final Map<String, LocalizedName> areas;

  String member(BuildContext context, String? id) {
    final member = members[id];
    if (member == null) return context.l10n.growthModeQueue;
    return member.nameOf(context.fmt.isBangla);
  }

  String sources(BuildContext context, List<String> wires) {
    final l10n = context.l10n;
    if (wires.isEmpty) return l10n.growthRuleAny;
    return [
      for (final wire in wires) RuleSource.fromWire(wire).label(l10n),
    ].join(', ');
  }

  String areaNames(BuildContext context, List<String> names) {
    if (names.isEmpty) return context.l10n.growthRuleAny;
    final bangla = context.fmt.isBangla;
    return [
      for (final name in names) areas[name]?.of(bangla) ?? name,
    ].join(', ');
  }

  String forms(BuildContext context, List<String> names) =>
      names.isEmpty ? context.l10n.growthRuleAny : names.join(', ');

  String memberNames(BuildContext context, List<String> ids) {
    if (ids.isEmpty) return context.l10n.growthRuleNobody;
    return [for (final id in ids) member(context, id)].join(', ');
  }

  /// One line: what the rule matches, then where the lead goes.
  String summary(BuildContext context, DistributionRule rule) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final conditions = [
      if (rule.sources.isNotEmpty)
        l10n.growthRuleIfSource(sources(context, rule.sources)),
      if (rule.areas.isNotEmpty)
        l10n.growthRuleIfArea(areaNames(context, rule.areas)),
      if (rule.forms.isNotEmpty)
        l10n.growthRuleIfForm(forms(context, rule.forms)),
    ];
    final count = fmt.number(rule.memberIds.length);
    final action = switch (rule.mode) {
      AssignMode.member => l10n.growthRuleToMember(
        member(context, rule.memberIds.firstOrNull),
      ),
      AssignMode.roundRobin => l10n.growthRuleRoundRobin(count),
      AssignMode.byLoad => l10n.growthRuleByLoad(count),
      AssignMode.queue => l10n.growthModeQueue,
    };
    final escalate = rule.escalateMinutes;
    return [
      if (conditions.isEmpty) l10n.growthRuleEveryLead else ...conditions,
      action,
      if (rule.onlyCheckedIn) l10n.growthRuleCheckedInShort,
      if (escalate != null) l10n.growthRuleEscalate(fmt.number(escalate)),
    ].join(' · ');
  }
}
