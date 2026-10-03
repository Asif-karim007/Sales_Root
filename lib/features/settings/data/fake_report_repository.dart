import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/settings/data/report_repository.dart';
import 'package:salesroot/features/settings/models/report_models.dart';

/// Reports are computed from the seed leads, so every total agrees with the
/// lead lists. A lead closes a third of the way from its creation to today,
/// and its product category comes from its id.
class FakeReportRepository implements ReportRepository {
  FakeReportRepository(this._backend);

  final FakeBackend _backend;

  static const _wonStage = 5;
  static const _lostStage = 6;
  static const _monthlyTargetPerSeller = 150000;

  SeedGraph get _graph => _backend.graph;

  @override
  Future<ReportOverview> overview(ReportQuery query) =>
      _backend.run('Report overview', () {
        final leads = _scoped(query);
        final created = leads.where((l) => _within(_createdAt(l), query));
        final closed = leads.where((l) => _within(_closedAt(l), query));
        final end = query.to.isAfter(_graph.anchor) ? _graph.anchor : query.to;
        final weekEnd = DateTime(end.year, end.month, end.day + 1);
        final sources = <String, List<int>>{};
        for (final lead in created) {
          final stat = sources.putIfAbsent(lead.source, () => [0, 0]);
          stat[0]++;
          if (lead.stageId == _wonStage) stat[1]++;
        }
        return ReportOverview.fromJson({
          'Won': closed.where((l) => l.stageId == _wonStage).length,
          'Lost': closed.where((l) => l.stageId == _lostStage).length,
          'Open': created.where((l) => l.isOpen).length,
          'WeeklyNewLeads': [
            for (var week = 7; week >= 0; week--)
              leads.where((l) {
                final at = _createdAt(l);
                final from = weekEnd.subtract(Duration(days: 7 * (week + 1)));
                final to = weekEnd.subtract(Duration(days: 7 * week));
                return !at.isBefore(from) && at.isBefore(to);
              }).length,
          ],
          'Sources': [
            for (final entry in sources.entries)
              {
                'Source': entry.key,
                'Leads': entry.value[0],
                'Won': entry.value[1],
              },
          ]..sort((a, b) => (b['Leads'] as int).compareTo(a['Leads'] as int)),
        });
      }, module: AppModule.reports);

  @override
  Future<SalesReport> sales(ReportQuery query) =>
      _backend.run('Report sales', () {
        final leads = _scoped(query);
        final won = leads.where(
          (l) => l.stageId == _wonStage && _within(_closedAt(l), query),
        );
        final previous = _previous(query);
        final lastMonth = DateTime(query.to.year, query.to.month);
        final days = query.to.difference(query.from).inDays + 1;
        final sellers = query.scope == ReportScope.mine ? 1 : _sellers.length;
        final target =
            (_monthlyTargetPerSeller * sellers * days / 30 / 10000).round() *
            10000;
        return SalesReport.fromJson({
          'Total': _sum(won),
          'PreviousTotal': _sum(
            leads.where(
              (l) => l.stageId == _wonStage && _within(_closedAt(l), previous),
            ),
          ),
          'Target': target,
          'Months': [
            for (var back = 5; back >= 0; back--)
              _month(leads, DateTime(lastMonth.year, lastMonth.month - back)),
          ],
          'Members': _members(leads, query),
          'Categories': _categories(won),
        });
      }, module: AppModule.reports);

  Iterable<SeedLead> _scoped(ReportQuery query) {
    if (query.scope == ReportScope.mine) {
      return _graph.leads.where((l) => l.ownerId == _backend.meId);
    }
    if (_backend.role == WorkspaceRole.member) {
      throw const ApiFailure(403, 'Team reports are for team leads and owners');
    }
    return _graph.leads;
  }

  List<SeedMember> get _sellers {
    final sellers = _graph.members
        .where((m) => m.role != WorkspaceRole.owner)
        .toList();
    return sellers.isEmpty ? _graph.members : sellers;
  }

  DateTime _createdAt(SeedLead lead) => _graph.daysAgo(lead.createdDaysAgo);

  DateTime _closedAt(SeedLead lead) =>
      _graph.daysAgo(lead.createdDaysAgo * 2 ~/ 3);

  static bool _within(DateTime at, ReportQuery query) =>
      !at.isBefore(query.from) &&
      at.isBefore(DateTime(query.to.year, query.to.month, query.to.day + 1));

  static ReportQuery _previous(ReportQuery query) {
    if (query.isMonth) {
      return query.copyWith(
        from: DateTime(query.from.year, query.from.month - 1),
        to: DateTime(query.from.year, query.from.month, 0),
      );
    }
    final days = query.to.difference(query.from).inDays + 1;
    return query.copyWith(
      from: query.from.subtract(Duration(days: days)),
      to: query.from.subtract(const Duration(days: 1)),
    );
  }

  static int _sum(Iterable<SeedLead> leads) =>
      leads.fold<int>(0, (total, l) => total + l.value);

  Map<String, dynamic> _month(Iterable<SeedLead> leads, DateTime month) {
    final query = ReportQuery(
      scope: ReportScope.mine,
      range: ReportRange.custom,
      from: month,
      to: DateTime(month.year, month.month + 1, 0),
    );
    return {
      'Month': '${month.year}-${month.month.toString().padLeft(2, '0')}-01',
      'Value': _sum(
        leads.where(
          (l) => l.stageId == _wonStage && _within(_closedAt(l), query),
        ),
      ),
    };
  }

  List<Map<String, dynamic>> _members(
    Iterable<SeedLead> leads,
    ReportQuery query,
  ) {
    final rows = <int, Map<String, dynamic>>{};
    Map<String, dynamic> row(int ownerId) => rows.putIfAbsent(ownerId, () {
      final member = _graph.member(ownerId);
      return {
        'MemberId': member.id,
        'Name': member.name,
        'NameBn': member.nameBn,
        'Leads': 0,
        'Won': 0,
        'WonValue': 0,
        'OpenValue': 0,
      };
    });
    for (final lead in leads) {
      if (_within(_createdAt(lead), query)) {
        final r = row(lead.ownerId);
        r['Leads'] = (r['Leads'] as int) + 1;
        if (lead.isOpen) r['OpenValue'] = (r['OpenValue'] as int) + lead.value;
      }
      if (lead.stageId == _wonStage && _within(_closedAt(lead), query)) {
        final r = row(lead.ownerId);
        r['Won'] = (r['Won'] as int) + 1;
        r['WonValue'] = (r['WonValue'] as int) + lead.value;
      }
    }
    return rows.values.toList()..sort(
      (a, b) => (b['WonValue'] as int) != (a['WonValue'] as int)
          ? (b['WonValue'] as int).compareTo(a['WonValue'] as int)
          : (b['Leads'] as int).compareTo(a['Leads'] as int),
    );
  }

  List<Map<String, dynamic>> _categories(Iterable<SeedLead> won) {
    final totals = <String, int>{};
    for (final lead in won) {
      final category = categoryOf(_graph, lead);
      totals[category] = (totals[category] ?? 0) + lead.value;
    }
    return [
      for (final entry in totals.entries)
        {'Category': entry.key, 'Value': entry.value},
    ]..sort((a, b) => (b['Value'] as int).compareTo(a['Value'] as int));
  }
}

/// The product category a seed lead is counted under.
String categoryOf(SeedGraph graph, SeedLead lead) =>
    graph.products[(lead.id * 7) % graph.products.length].category;
