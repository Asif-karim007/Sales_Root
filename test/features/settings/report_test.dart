import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/models/report_models.dart';
import 'package:salesroot/features/settings/providers/report_providers.dart';

import 'settings_test_setup.dart';

void main() {
  RequestOptions? request(List<RequestOptions> all, String path, String? by) =>
      all
          .where(
            (r) => r.path.endsWith(path) && r.queryParameters['group'] == by,
          )
          .lastOrNull;

  test('the overview reads outcomes, sources and eight weeks', () async {
    final stub = settingsStub();
    final container = await settingsContainer(stub);
    listenTo(container, reportOverviewProvider);

    final overview = await container.read(reportOverviewProvider.future);

    expect((overview.won, overview.lost, overview.open), (0, 0, 3));
    expect(overview.sources.map((s) => (s.source, s.leads)), [
      ('manual', 2),
      ('card', 1),
    ]);
    expect(overview.weeklyNewLeads, [0, 0, 0, 0, 0, 0, 3, 0]);
    final period = request(stub.requests, 'reports/conversion', null);
    expect(period?.queryParameters['preset'], 'this_month');
    expect(period?.queryParameters['ownerId'], memberId);
    final weeks = request(stub.requests, 'reports/conversion', 'week');
    expect(weeks?.queryParameters['preset'], 'custom');
  });

  test('the sales report combines sales, targets and people', () async {
    final stub = settingsStub();
    final container = await settingsContainer(stub);
    listenTo(container, salesReportProvider);
    container
        .read(reportQueryProvider.notifier)
        .setRange(ReportRange.lastMonth);

    final report = await container.read(salesReportProvider.future);

    expect(report.products.map((p) => (p.product, p.value)), [
      ('Detergent 1kg (carton of 12)', 100000),
      ('[test] Soap', 12900),
    ]);
    expect(report.months, hasLength(6));
    expect(report.months.first.month, DateTime(2026, 5));
    expect(report.members.single.name, 'Rafi Ahmed');
    expect(report.members.single.leads, 3);
    expect(report.target, 0);
    final sales = request(stub.requests, 'reports/sales', null);
    expect(sales?.queryParameters['ownerId'], memberId);
    final targets = stub.last('GET', 'reports/targets');
    expect(targets?.queryParameters.containsKey('ownerId'), isFalse);
    expect(targets?.queryParameters['preset'], 'last_month');
  });

  test(
    'the period before has the same length and ends the day before',
    () async {
      final stub = settingsStub();
      final container = await settingsContainer(stub);
      listenTo(container, salesReportProvider);
      container
          .read(reportQueryProvider.notifier)
          .setCustom(DateTime(2026, 9, 11), DateTime(2026, 9, 20));

      await container.read(salesReportProvider.future);

      final previous = stub.requests
          .where(
            (r) =>
                r.path.endsWith('reports/sales') &&
                r.queryParameters['to'] == '2026-09-10',
          )
          .single;
      expect(previous.queryParameters['from'], '2026-09-01');
    },
  );

  test('team scope drops the member filter', () async {
    final stub = settingsStub();
    final container = await settingsContainer(stub, role: 'owner');
    listenTo(container, reportOverviewProvider);

    expect(container.read(canSeeTeamReportsProvider), isTrue);
    expect(container.read(reportQueryProvider).scope, ReportScope.team);
    await container.read(reportOverviewProvider.future);

    expect(
      request(stub.requests, 'reports/conversion', null)?.queryParameters,
      isNot(contains('ownerId')),
    );
  });

  test('members only see their own numbers', () async {
    final container = await settingsContainer(settingsStub());

    expect(container.read(canSeeTeamReportsProvider), isFalse);
    expect(container.read(reportQueryProvider).scope, ReportScope.mine);
  });

  test('a refused report is an error', () async {
    final stub = settingsStub()..fail('GET', 'reports/conversion', 403);
    final container = await settingsContainer(stub);
    listenTo(container, reportOverviewProvider);

    await expectLater(
      container.read(reportOverviewProvider.future),
      throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', isTrue)),
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
    expect(quarter.toQuery(memberId: 'm'), {
      'preset': 'this_quarter',
      'ownerId': 'm',
    });
  });
}
