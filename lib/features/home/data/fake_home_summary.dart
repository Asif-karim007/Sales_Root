import 'dart:math';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';

/// What the server's home summary endpoint computes, from the shared graph,
/// the user's tasks and the pending approvals.
class FakeHomeSummary {
  FakeHomeSummary({
    required this.graph,
    required this.role,
    required this.tasks,
    required this.approvals,
  });

  final SeedGraph graph;
  final WorkspaceRole role;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> approvals;

  late final DateTime _today = AppDateUtils.dateOnly(graph.anchor);
  late final List<SeedMember> _team = _teamOf();
  late final Set<int> _teamIds = {for (final m in _team) m.id};
  late final List<SeedLead> _mine = graph.leadsOf(SeedGraph.meId);

  Map<String, dynamic> build() {
    if (graph.leads.isEmpty) return const {'IsNewWorkspace': true};
    final scope = switch (role) {
      WorkspaceRole.member => _mine,
      WorkspaceRole.teamLead =>
        graph.leads
            .where(
              (l) =>
                  _teamIds.contains(l.ownerId) || l.ownerId == SeedGraph.meId,
            )
            .toList(),
      WorkspaceRole.owner => graph.leads,
    };
    final random = graph.random('home-summary');
    final open = _mine.where((l) => l.isOpen).toList();
    final pending = _pendingTasks();
    final dueToday = pending.where((t) => !_isOverdue(t)).toList();
    return {
      'IsNewWorkspace': false,
      'Onboarding': {
        'LeadAdded': true,
        'CallLogged': true,
        'FollowUpSet': tasks.isNotEmpty,
        'CardScanned': _mine.any((l) => l.source == 'Visiting card'),
      },
      'CallsToday': 2 + random.nextInt(4) + _touched(0),
      'CallsYesterday': 3 + random.nextInt(5) + _touched(1),
      'FollowUpsDue': pending.length,
      'FollowUpsOverdue': pending.length - dueToday.length,
      'VisitsToday': dueToday.where((t) => t['Kind'] == 'Visit').length,
      'OpenLeads': open.length,
      'Agenda': [for (final task in pending.take(6)) _agenda(task)],
      'OpenDealsValue': _sum(scope.where((l) => l.isOpen)),
      'TargetPercent': _targetPercent(scope, random),
      'Pipeline': _pipeline(scope),
      'QuotationsAwaiting': _quotations(scope, random),
      'MeetingRate': 18 + random.nextInt(14),
      'TeamMeetingRate': 15 + random.nextInt(9),
      if (role != WorkspaceRole.member) 'Team': _teamSummary(scope),
      if (role != WorkspaceRole.member) 'Money': _money(),
    };
  }

  /// Members of the user's own team: their reports, else the team of the
  /// lead they report to, else everyone but the owners.
  List<SeedMember> _teamOf() {
    final me = graph.me;
    final reports = graph.members.where((m) => m.managerId == me.id).toList();
    if (reports.isNotEmpty) return reports;
    final managerId = me.managerId;
    if (managerId != null) {
      return graph.members.where((m) => m.managerId == managerId).toList();
    }
    return graph.members
        .where((m) => m.role != WorkspaceRole.owner && m.id != me.id)
        .toList();
  }

  int _touched(int daysAgo) =>
      _mine.where((l) => l.lastTouchDaysAgo == daysAgo).length;

  int _sum(Iterable<SeedLead> leads) =>
      leads.fold(0, (sum, lead) => sum + lead.value);

  DateTime _due(Map<String, dynamic> task) =>
      jsonDate(task['DueAt']) ?? graph.anchor;

  bool _isOverdue(Map<String, dynamic> task) =>
      AppDateUtils.dateOnly(_due(task)).isBefore(_today);

  List<Map<String, dynamic>> _pendingTasks() {
    final tomorrow = _today.add(const Duration(days: 1));
    return tasks
        .where(
          (t) =>
              t['AssigneeId'] == SeedGraph.meId &&
              t['IsDone'] != true &&
              _due(t).isBefore(tomorrow),
        )
        .toList()
      ..sort((a, b) => _due(a).compareTo(_due(b)));
  }

  Map<String, dynamic> _agenda(Map<String, dynamic> task) {
    final leadId = jsonInt(task['LeadId']);
    final lead = leadId == null ? null : graph.lead(leadId);
    final area = lead == null ? null : graph.company(lead.companyId).area;
    final stage = lead == null ? null : _stage(lead.stageId);
    return {
      'TaskId': task['Id'],
      'Kind': task['Kind'],
      'Title': lead?.title ?? task['Title'],
      'LeadId': leadId,
      'DueAt': task['DueAt'],
      'Note': task['Note'],
      if (area != null) 'Area': {'Name': area.name, 'NameBn': area.nameBn},
      if (stage != null) 'Stage': {'Name': stage.$2, 'NameBn': stage.$3},
      'StageId': lead?.stageId,
      'IsOverdue': _isOverdue(task),
      'IsNew': lead != null && lead.stageId == 1 && lead.createdDaysAgo < 3,
      'DaysSilent': lead?.lastTouchDaysAgo ?? 0,
    }..removeWhere((_, value) => value == null);
  }

  (int, String, String, int) _stage(int id) =>
      SeedGraph.stages.firstWhere((s) => s.$1 == id);

  int _targetPercent(List<SeedLead> scope, Random random) {
    final won = _sum(scope.where((l) => l.stageId == 5));
    final open = _sum(scope.where((l) => l.isOpen));
    if (won + open == 0) return 0;
    final percent = (won * 100 / (won + open * 0.25)).round();
    return (percent - random.nextInt(8)).clamp(0, 100);
  }

  List<Map<String, dynamic>> _pipeline(List<SeedLead> scope) => [
    for (final stage in SeedGraph.stages.where((s) => s.$1 <= 5))
      {
        'StageId': stage.$1,
        'Name': stage.$2,
        'NameBn': stage.$3,
        'Count': scope.where((l) => l.stageId == stage.$1).length,
        'Value': _sum(scope.where((l) => l.stageId == stage.$1)),
      },
  ];

  List<Map<String, dynamic>> _quotations(List<SeedLead> scope, Random random) {
    final quoted = scope.where((l) => l.stageId == 4).toList()
      ..sort((a, b) => a.lastTouchDaysAgo.compareTo(b.lastTouchDaysAgo));
    return [
      for (final lead in quoted.take(3))
        {
          'Id': lead.id,
          'LeadId': lead.id,
          'CompanyName': graph.company(lead.companyId).name,
          'Amount': lead.value,
          'SentDaysAgo': lead.lastTouchDaysAgo,
          'Viewed': lead.lastTouchDaysAgo > 0 && random.nextInt(3) > 0,
        },
    ];
  }

  Map<String, dynamic> _teamSummary(List<SeedLead> scope) {
    final days = [for (final member in _team) _day(member)];
    final pending = approvals.where(
      (a) => a['Status'] == 'Pending' && _teamIds.contains(a['MemberId']),
    );
    return {
      'ActivityToday': days.fold<int>(
        0,
        (sum, d) => sum + (d['Calls'] as int) + (d['Visits'] as int),
      ),
      'NoFollowUp': scope
          .where((l) => l.isOpen && l.lastTouchDaysAgo >= 7)
          .length,
      'TargetPercent': _targetPercent(scope, graph.random('home-team')),
      'Members': days.take(5).toList(),
      'Approvals': pending.take(3).toList(),
      'ApprovalsCount': pending.length,
    };
  }

  /// A member's day so far; the same for every screen that asks.
  Map<String, dynamic> _day(SeedMember member) {
    final random = graph.random('home-day-${member.id}');
    final roll = random.nextInt(10);
    final status = roll < 6
        ? 'Active'
        : roll < 8
        ? 'Late'
        : 'Absent';
    final checkIn = switch (status) {
      'Active' => graph.daysAgo(0, hour: 8, minute: 40 + random.nextInt(19)),
      'Late' => graph.daysAgo(0, hour: 9, minute: 20 + random.nextInt(35)),
      _ => null,
    };
    return {
      'MemberId': member.id,
      'Name': member.name,
      'NameBn': member.nameBn,
      'Calls': status == 'Absent' ? 0 : 3 + random.nextInt(11),
      'Visits': status == 'Absent' ? 0 : random.nextInt(5),
      'Status': status,
      'CheckInAt': jsonUtc(checkIn),
    }..removeWhere((_, value) => value == null);
  }

  Map<String, dynamic> _money() {
    final random = graph.random('home-money');
    final won = graph.leads.where((l) => l.stageId == 5).toList();
    final sales = _sum(won);
    final open = graph.leads.where((l) => l.isOpen).toList();
    final weeks = List.filled(4, 0);
    for (final lead in won) {
      for (var w = (lead.id + lead.lastTouchDaysAgo) % 4; w < 4; w++) {
        weeks[w] += lead.value;
      }
    }
    final likely = open.where((l) => l.stageId >= 3).toList();
    final staff = graph.members
        .where((m) => m.role != WorkspaceRole.owner)
        .toList();
    final days = [for (final member in staff) _day(member)];
    return {
      'Today': _collection(sales * (3 + random.nextInt(4)) ~/ 100, random),
      'Month': _collection(sales * (60 + random.nextInt(20)) ~/ 100, random),
      ..._receivables(won, random),
      'SalesMonth': sales,
      'SalesLastMonth': _round(sales * (80 + random.nextInt(18)) / 100),
      'SalesTarget': _round(sales * 100 / (62 + random.nextInt(22)), 100000),
      'TeamToday': {
        'Calls': days.fold<int>(0, (s, d) => s + (d['Calls'] as int)),
        'Visits': days.fold<int>(0, (s, d) => s + (d['Visits'] as int)),
        'NewLeads': graph.leads.where((l) => l.createdDaysAgo == 0).length,
        'Present': days.where((d) => d['Status'] != 'Absent').length,
        'Headcount': days.length,
      },
      'TopSellers': _topSellers(won),
      'ForecastWeeks': weeks,
      'ForecastPipeline': _weighted(likely),
      'ForecastAtRisk': _weighted(likely.where((l) => l.lastTouchDaysAgo >= 7)),
      ..._departments(open, won),
    };
  }

  Map<String, dynamic> _collection(int total, Random random) {
    final amount = _round(total.toDouble());
    final cash = _round(amount * (30 + random.nextInt(10)) / 100);
    final mobile = _round(amount * (40 + random.nextInt(15)) / 100);
    return {
      'Total': amount,
      'Previous': _round(amount * (82 + random.nextInt(30)) / 100),
      'Cash': cash,
      'Mobile': mobile,
      'Bank': amount - cash - mobile,
    };
  }

  Map<String, dynamic> _receivables(List<SeedLead> won, Random random) {
    final due = [for (final lead in won) (lead, _round(lead.value * 0.35))];
    final overdue = due.where((d) => d.$1.id % 4 == 0).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final worst = overdue.isEmpty ? null : overdue.first.$1;
    final owner = worst == null ? null : graph.member(worst.ownerId);
    return {
      'Receivable': due.fold<int>(0, (sum, d) => sum + d.$2),
      'Overdue': overdue.fold<int>(0, (sum, d) => sum + d.$2),
      'OverdueCustomers': overdue.length,
      if (worst != null && owner != null)
        'OverdueCustomer': {
          'CompanyId': worst.companyId,
          'Name': graph.company(worst.companyId).name,
          'Days': 35 + random.nextInt(80),
          'Amount': overdue.first.$2,
          'OwnerName': owner.name.split(' ').first,
          'OwnerNameBn': owner.nameBn.split(' ').first,
        },
    };
  }

  List<Map<String, dynamic>> _topSellers(List<SeedLead> won) {
    final totals = <int, int>{};
    for (final lead in won) {
      totals[lead.ownerId] = (totals[lead.ownerId] ?? 0) + lead.value;
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in ranked.take(3))
        {
          'MemberId': entry.key,
          'Name': graph.member(entry.key).name,
          'NameBn': graph.member(entry.key).nameBn,
          'Amount': entry.value,
        },
    ];
  }

  Map<String, dynamic> _departments(List<SeedLead> open, List<SeedLead> won) {
    final leads = graph.members.where((m) => m.role == WorkspaceRole.teamLead);
    final rows = <Map<String, dynamic>>[];
    for (final lead in leads) {
      final team = {
        lead.id,
        for (final m in graph.members)
          if (m.managerId == lead.id) m.id,
      };
      final teamWon = _sum(won.where((l) => team.contains(l.ownerId)));
      final teamOpen = _sum(open.where((l) => team.contains(l.ownerId)));
      rows.add({
        'LeadId': lead.id,
        'Name': lead.name,
        'NameBn': lead.nameBn,
        'Percent': teamWon + teamOpen == 0
            ? 0
            : (teamWon * 100 / (teamWon + teamOpen * 0.3)).round(),
        'Count': open
            .where((l) => team.contains(l.ownerId) && l.lastTouchDaysAgo >= 7)
            .length,
      });
    }
    rows.sort((a, b) => (b['Count'] as int).compareTo(a['Count'] as int));
    return {
      'Departments': [
        for (final row in rows) {...row}..remove('Count'),
      ]..sort((a, b) => (b['Percent'] as int).compareTo(a['Percent'] as int)),
      'StaleLeads': open.where((l) => l.lastTouchDaysAgo >= 7).length,
      if (rows.isNotEmpty) 'StaleLeadsTeam': rows.first,
    };
  }

  int _weighted(Iterable<SeedLead> leads) =>
      leads.fold(0, (sum, l) => sum + l.value * _stage(l.stageId).$4 ~/ 100);

  int _round(double value, [int step = 50]) => (value / step).round() * step;
}
