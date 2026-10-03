import 'package:salesroot/features/growth/models/distribution_rule.dart';

/// What a rule looks at in an incoming lead.
class RuleSubject {
  const RuleSubject({
    required this.source,
    this.area,
    this.form,
    this.campaign,
  });

  final String source;
  final String? area;
  final String? form;
  final String? campaign;
}

class RuleDecision {
  const RuleDecision({this.rule, this.memberId, this.cursor});

  /// The first rule that matched; null when none did.
  final DistributionRule? rule;

  /// Who gets the lead; null leaves it in the shared queue.
  final int? memberId;

  /// The rule's next round-robin position, when it moved.
  final int? cursor;

  bool get toQueue => memberId == null;
}

/// The server's lead distribution: rules run in order and the first match
/// assigns the lead.
abstract final class DistributionEngine {
  static RuleDecision decide({
    required bool enabled,
    required List<DistributionRule> rules,
    required RuleSubject subject,
    required Map<int, GrowthMember> members,
    required DateTime at,
  }) {
    if (!enabled) return const RuleDecision();
    final ordered = [...rules]
      ..sort((a, b) => a.position.compareTo(b.position));
    for (final rule in ordered) {
      if (rule.enabled && matches(rule, subject, at)) {
        return _assign(rule, members);
      }
    }
    return const RuleDecision();
  }

  static bool matches(DistributionRule rule, RuleSubject subject, DateTime at) {
    if (rule.sources.isNotEmpty && !rule.sources.contains(subject.source)) {
      return false;
    }
    if (rule.areas.isNotEmpty && !rule.areas.contains(subject.area)) {
      return false;
    }
    if (rule.forms.isNotEmpty &&
        !rule.forms.any((f) => f == subject.form || f == subject.campaign)) {
      return false;
    }
    if (rule.days.isNotEmpty && !rule.days.contains(at.weekday)) return false;
    final from = rule.fromHour;
    final to = rule.toHour;
    if (from == null || to == null) return true;
    final hour = at.hour;
    return from <= to ? hour >= from && hour < to : hour >= from || hour < to;
  }

  static RuleDecision _assign(
    DistributionRule rule,
    Map<int, GrowthMember> members,
  ) {
    if (rule.mode == AssignMode.queue) return RuleDecision(rule: rule);
    final ids = rule.memberIds;
    final eligible = [
      for (final id in ids)
        if (members[id] case final member? when _eligible(rule, member)) member,
    ];
    if (eligible.isEmpty) {
      final fallback = rule.fallbackMemberId;
      return RuleDecision(
        rule: rule,
        memberId: members.containsKey(fallback) ? fallback : null,
      );
    }
    switch (rule.mode) {
      case AssignMode.member || AssignMode.queue:
        return RuleDecision(rule: rule, memberId: eligible.first.id);
      case AssignMode.byLoad:
        final lightest = eligible.reduce(
          (a, b) => b.openLeads < a.openLeads ? b : a,
        );
        return RuleDecision(rule: rule, memberId: lightest.id);
      case AssignMode.roundRobin:
        for (var step = 0; step < ids.length; step++) {
          final index = (rule.cursor + step) % ids.length;
          final member = members[ids[index]];
          if (member != null && _eligible(rule, member)) {
            return RuleDecision(
              rule: rule,
              memberId: member.id,
              cursor: (index + 1) % ids.length,
            );
          }
        }
        return RuleDecision(rule: rule, memberId: eligible.first.id);
    }
  }

  static bool _eligible(DistributionRule rule, GrowthMember member) {
    if (rule.skipOnLeave && member.onLeave) return false;
    if (rule.onlyCheckedIn && !member.checkedIn) return false;
    final cap = rule.dailyCap;
    return cap == null || member.assignedToday < cap;
  }
}
