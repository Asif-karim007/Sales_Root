import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/home_variant.dart';
import 'package:salesroot/features/home/models/money_summary.dart';
import 'package:salesroot/features/home/providers/home_providers.dart';

import '../../helpers/api_stub.dart';
import 'home_test_setup.dart';

void main() {
  group('homeLayoutFor', () {
    HomeVariant pick(
      WorkspaceRole role,
      ExperienceLevel level, {
      bool ownerDashboard = true,
    }) =>
        homeLayoutFor(role: role, level: level, ownerDashboard: ownerDashboard);

    test('members get Easy or Standard by level', () {
      expect(
        pick(WorkspaceRole.member, ExperienceLevel.easy),
        HomeVariant.easy,
      );
      expect(
        pick(WorkspaceRole.member, ExperienceLevel.standard),
        HomeVariant.standard,
      );
      expect(
        pick(WorkspaceRole.member, ExperienceLevel.advanced),
        HomeVariant.standard,
      );
    });

    test('team leads get the team home, managers at Advanced', () {
      expect(
        pick(WorkspaceRole.teamLead, ExperienceLevel.standard),
        HomeVariant.teamLead,
      );
      expect(
        pick(WorkspaceRole.teamLead, ExperienceLevel.advanced),
        HomeVariant.manager,
      );
    });

    test('owners get the money dashboard from Standard up', () {
      expect(pick(WorkspaceRole.owner, ExperienceLevel.easy), HomeVariant.easy);
      expect(
        pick(WorkspaceRole.owner, ExperienceLevel.standard),
        HomeVariant.owner,
      );
      expect(
        pick(
          WorkspaceRole.owner,
          ExperienceLevel.standard,
          ownerDashboard: false,
        ),
        HomeVariant.standard,
      );
    });
  });

  group('GET home', () {
    test('parses counts and today’s plan', () {
      final summary = HomeSummary.fromJson(fixtureMap('home_home'));

      expect(summary.isNew, isFalse);
      expect(summary.followUpsDue, 2);
      expect(summary.openLeads, 3);
      expect(summary.agenda, hasLength(4));
      final visit = summary.agenda.first;
      expect(visit.kind, AgendaKind.visit);
      expect(visit.leadId, '01a10101-866a-7007-90bc-2326bcdb9d50');
      expect(visit.who, 'Mr Rahim');
      expect(visit.isOverdue, isTrue);
      expect(summary.agenda[2].kind, AgendaKind.collect);
      final followUp = summary.agenda.last;
      expect(followUp.kind, AgendaKind.followUp);
      expect(followUp.isOverdue, isFalse);
      expect(summary.followUpsOverdue, 3);
      expect(summary.visitsToday, 0);
    });

    test('a workspace with nothing in it is new', () {
      final summary = HomeSummary.fromJson(emptyHome());
      expect(summary.isNew, isTrue);
      expect(summary.onboarding.done, 1);
    });

    test('a task already planned counts as a follow-up set', () {
      final json = emptyHome()..['today'] = fixtureMap('home_home')['today'];
      final summary = HomeSummary.fromJson(json);
      expect(summary.isNew, isTrue);
      expect(summary.onboarding.done, 2);
    });
  });

  group('summary by role', () {
    test('an empty workspace shows the new-user home from real data', () async {
      final stub = homeStub()..on('GET', 'home', emptyHome());
      final container = await homeContainer(stub);
      container.listen(homeVariantProvider, (_, _) {});

      await container.read(homeSummaryProvider.future);
      expect(container.read(homeVariantProvider), HomeVariant.newUser);
      expect(stub.last('GET', 'reports/me'), isNull);
    });

    test('Easy adds the last seven days of calls', () async {
      final stub = homeStub();
      final container = await homeContainer(stub);
      container.listen(homeVariantProvider, (_, _) {});

      final summary = await container.read(homeSummaryProvider.future);
      expect(container.read(homeVariantProvider), HomeVariant.easy);
      expect(
        stub.last('GET', 'reports/me')?.queryParameters['preset'],
        'last_7',
      );
      expect(summary.week?.callsToday, 1);
      expect(summary.week?.callsYesterday, 0);
      expect(summary.week?.calls, 2);
      expect(summary.week?.teamCalls, 0.7);
    });

    test('Standard adds the pipeline, target and quotations', () async {
      final stub = homeStub();
      final container = await homeContainer(stub, level: 'standard');

      final summary = await container.read(homeSummaryProvider.future);
      expect(summary.pipeline.map((s) => s.name.en), [
        'To contact',
        'Visited',
        'Sample given',
        'Ordered',
      ]);
      expect(summary.openDealsValue, 221410);
      expect(summary.targetPercent, isNull);
      expect(stub.last('GET', 'quotes')?.queryParameters['status'], 'sent');
      final quote = summary.quotations.single;
      expect(quote.companyName, 'Rahim Traders');
      expect(quote.amount, 206400);
      expect(quote.sentDaysAgo, 2);
      expect(quote.needsFollowUp, isTrue);
    });

    test('a set target shows as a percent', () async {
      final report = fixtureMap('home_targets_report');
      final stub = homeStub()
        ..on('GET', 'reports/targets', {
          ...report,
          'summary': {'sales_target': 400000, 'sales_actual': 100000},
        });
      final container = await homeContainer(stub, level: 'standard');

      final summary = await container.read(homeSummaryProvider.future);
      expect(summary.targetPercent, 25);
    });

    test('a report the role may not see is left out', () async {
      final stub = homeStub()
        ..fail('GET', 'reports/pipeline', 403, message: 'Forbidden');
      final container = await homeContainer(stub, level: 'standard');

      final summary = await container.read(homeSummaryProvider.future);
      expect(summary.pipeline, isEmpty);
      expect(summary.quotations, hasLength(1));
    });

    test('a team lead sees members, their calls and approvals', () async {
      final stub = homeStub()
        ..on('GET', 'ai/daily-summary', {
          ...fixtureMap('home_daily_summary'),
          'numbers': {'pendingApprovals': 3},
        });
      final container = await homeContainer(
        stub,
        role: 'teamlead',
        level: 'standard',
      );

      final summary = await container.read(homeSummaryProvider.future);
      final team = summary.team;
      expect(team, isNotNull);
      expect(team?.activityToday, 0);
      expect(team?.noFollowUp, 0);
      expect(team?.approvalsCount, 3);
      expect(team?.members.single.name, 'Rafi Ahmed');
      expect(
        stub.last('GET', 'ai/daily-summary')?.queryParameters['day'],
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
      );
    });

    test('the owner’s money comes from collection and targets', () async {
      final stub = homeStub();
      final container = await homeContainer(
        stub,
        role: 'owner',
        level: 'standard',
      );

      final money = (await container.read(homeSummaryProvider.future)).money;
      expect(money, isNotNull);
      expect(money?.receivable, 118000);
      expect(money?.overdue, 68000);
      expect(money?.month.total, 0);
      expect(money?.month.previous, 50000);
      expect(money?.month.changePercent, -100);
      expect(money?.today.previous, 0);
      expect(money?.today.changePercent, isNull);
      expect(money?.teamToday.headcount, 1);
      expect(money?.topSellers, isEmpty);
    });

    test('the manager sees overdue dues, forecast and teams', () async {
      final stub = homeStub();
      final container = await homeContainer(
        stub,
        role: 'manager',
        level: 'advanced',
      );

      final money = (await container.read(homeSummaryProvider.future)).money;
      expect(stub.last('GET', 'dues')?.queryParameters['bucket'], 'overdue');
      expect(money?.overdueCustomers, 1);
      expect(money?.overdueCustomer?.name, 'Rahim Traders');
      expect(money?.overdueCustomer?.days, 44);
      expect(money?.forecastWeeks, hasLength(5));
      expect(money?.forecastPipeline, closeTo(99631, 1));
      expect(money?.departments, isEmpty);
    });

    test('offline fails the whole home', () async {
      final stub = homeStub();
      final container = await homeContainer(stub);
      stub.offline = true;

      await expectLater(
        container.read(homeSummaryProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });

    test('switching workspace loads the home again', () async {
      final me = meWith(role: 'executive', level: 'easy');
      final first = (me['workspaces'] as List).first as Map<String, dynamic>;
      final tokens = fixtureMap('auth_tokens');
      final stub = homeStub()
        ..on('GET', 'auth/me', {
          ...me,
          'workspaces': [
            first,
            {...first, 'id': 'other', 'name': 'Karim Textiles'},
          ],
        })
        ..on('POST', 'auth/workspace/{id}', {
          ...tokens,
          'me': {
            ...tokens['me'] as Map<String, dynamic>,
            'workspaceId': 'other',
          },
        });
      final container = await homeContainer(stub);
      container.listen(homeSummaryProvider, (_, _) {});
      await container.read(homeSummaryProvider.future);
      int homeCalls() =>
          stub.requests.where((r) => r.uri.path.endsWith('/home')).length;
      final before = homeCalls();

      await container.read(sessionProvider.notifier).switchWorkspace('other');
      await container.read(homeSummaryProvider.future);

      expect(homeCalls(), before + 1);
    });
  });

  test('teams are scored against their members’ targets', () {
    const people = [
      TopSeller(
        memberId: 'a',
        name: 'A',
        amount: 0,
        teamId: 't1',
        teamName: 'North',
      ),
      TopSeller(
        memberId: 'b',
        name: 'B',
        amount: 0,
        teamId: 't1',
        teamName: 'North',
      ),
      TopSeller(
        memberId: 'c',
        name: 'C',
        amount: 0,
        teamId: 't2',
        teamName: 'South',
      ),
      TopSeller(memberId: 'd', name: 'D', amount: 0),
    ];
    final scores = DepartmentScore.of(people, const [
      PersonTarget(memberId: 'a', actual: 50000, target: 100000),
      PersonTarget(memberId: 'b', actual: 30000, target: 60000),
      PersonTarget(memberId: 'c', actual: 10000, target: 0),
      PersonTarget(memberId: 'd', actual: 10000, target: 10000),
    ]);
    expect(scores.map((s) => (s.name, s.percent)), [('North', 50)]);
  });
}
