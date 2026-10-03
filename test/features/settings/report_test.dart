import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/settings/data/fake_report_repository.dart';
import 'package:salesroot/features/settings/models/report_models.dart';
import 'package:salesroot/features/settings/providers/report_providers.dart';

import 'settings_test_utils.dart';

void main() {
  test(
    'sales totals agree across members, products and the seed leads',
    () async {
      final container = await signedInContainer(role: WorkspaceRole.owner);
      addTearDown(container.dispose);
      keepAlive(container, salesReportProvider);
      container
          .read(reportQueryProvider.notifier)
          .setRange(ReportRange.thisQuarter);
      final query = container.read(reportQueryProvider);
      expect(query.scope, ReportScope.team);

      final report = await container.read(salesReportProvider.future);
      final graph = container.read(fakeBackendProvider).graph;
      final end = DateTime(query.to.year, query.to.month, query.to.day + 1);
      final expected = graph.leads
          .where((l) {
            final closed = graph.daysAgo(l.createdDaysAgo * 2 ~/ 3);
            return l.stageId == 5 &&
                !closed.isBefore(query.from) &&
                closed.isBefore(end);
          })
          .fold<int>(0, (sum, l) => sum + l.value);

      expect(report.total, expected);
      expect(report.total, greaterThan(0));
      expect(
        report.members.fold<int>(0, (s, m) => s + m.wonValue),
        report.total,
      );
      expect(
        report.categories.fold<int>(0, (s, c) => s + c.value),
        report.total,
      );
      expect(report.months, hasLength(6));
      expect(report.months.last.month.month, query.to.month);
    },
  );

  test('a category comes from the lead, so it never changes', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    final graph = container.read(fakeBackendProvider).graph;

    expect(
      categoryOf(graph, graph.leads.first),
      categoryOf(graph, graph.leads.first),
    );
    expect(
      graph.products.map((p) => p.category),
      contains(categoryOf(graph, graph.leads[7])),
    );
  });

  test('my numbers only count my leads', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, salesReportProvider);

    final query = container.read(reportQueryProvider);
    final report = await container.read(salesReportProvider.future);

    expect(query.scope, ReportScope.mine);
    expect(report.members.every((m) => m.memberId == 1), isTrue);
  });

  test('members are refused the team view', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, salesReportProvider);
    container.read(reportQueryProvider.notifier).setScope(ReportScope.team);

    await expectLater(
      container.read(salesReportProvider.future),
      throwsA(isA<ApiFailure>().having((f) => f.statusCode, 'status', 403)),
    );
  });

  test('the overview splits outcomes and counts eight weeks', () async {
    final container = await signedInContainer(role: WorkspaceRole.teamLead);
    addTearDown(container.dispose);
    keepAlive(container, reportOverviewProvider);

    final overview = await container.read(reportOverviewProvider.future);

    expect(overview.weeklyNewLeads, hasLength(8));
    expect(overview.winRate, inInclusiveRange(0, 1));
    expect(
      overview.sources.fold<int>(0, (s, x) => s + x.leads),
      greaterThanOrEqualTo(overview.open),
    );
  });

  test('presets cover whole months and quarters', () {
    final now = DateTime(2026, 10, 4);

    final month = ReportQuery.preset(ReportRange.thisMonth, now: now);
    final last = ReportQuery.preset(ReportRange.lastMonth, now: now);
    final quarter = ReportQuery.preset(ReportRange.thisQuarter, now: now);

    expect(
      (month.from, month.to),
      (DateTime(2026, 10), DateTime(2026, 10, 31)),
    );
    expect((last.from, last.to), (DateTime(2026, 9), DateTime(2026, 9, 30)));
    expect(
      (quarter.from, quarter.to),
      (DateTime(2026, 10), DateTime(2026, 12, 31)),
    );
    expect(month.isMonth, isTrue);
    expect(quarter.isMonth, isFalse);
  });
}
