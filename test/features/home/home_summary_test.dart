import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/home_variant.dart';
import 'package:salesroot/features/home/providers/home_providers.dart';

import 'home_test_setup.dart';

void main() {
  group('homeVariantFor', () {
    HomeVariant pick(
      WorkspaceRole role,
      ExperienceLevel level, {
      bool isNew = false,
      bool ownerDashboard = true,
    }) => homeVariantFor(
      isNew: isNew,
      role: role,
      level: level,
      ownerDashboard: ownerDashboard,
    );

    test('an empty workspace always gets the new-user home', () {
      for (final role in WorkspaceRole.values) {
        for (final level in ExperienceLevel.values) {
          expect(pick(role, level, isNew: true), HomeVariant.newUser);
        }
      }
    });

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
        pick(WorkspaceRole.teamLead, ExperienceLevel.easy),
        HomeVariant.teamLead,
      );
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
        pick(WorkspaceRole.owner, ExperienceLevel.advanced),
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

  group('homeVariantProvider', () {
    Future<HomeVariant?> variantFor(
      WorkspaceRole? role, {
      ExperienceLevel? level,
      bool empty = false,
    }) async {
      final container = await homeContainer(role: role, empty: empty);
      if (level != null) {
        container.read(experienceLevelProvider.notifier).set(level);
      }
      container.listen(homeVariantProvider, (_, _) {});
      await container.read(homeSummaryProvider.future);
      return container.read(homeVariantProvider);
    }

    test('a member starts on the Easy home', () async {
      expect(await variantFor(WorkspaceRole.member), HomeVariant.easy);
    });

    test('a member at Standard gets the Standard home', () async {
      expect(
        await variantFor(WorkspaceRole.member, level: ExperienceLevel.standard),
        HomeVariant.standard,
      );
    });

    test('a team lead gets the team home, or the manager home', () async {
      expect(await variantFor(WorkspaceRole.teamLead), HomeVariant.teamLead);
      expect(
        await variantFor(
          WorkspaceRole.teamLead,
          level: ExperienceLevel.advanced,
        ),
        HomeVariant.manager,
      );
    });

    test('an owner gets the money dashboard', () async {
      expect(await variantFor(WorkspaceRole.owner), HomeVariant.owner);
    });

    test('the empty-workspace switch shows the new-user home', () async {
      expect(
        await variantFor(WorkspaceRole.owner, empty: true),
        HomeVariant.newUser,
      );
    });
  });

  group('home summary', () {
    test('a member sees their own pipeline and today\'s work', () async {
      final container = await homeContainer(role: WorkspaceRole.member);
      container.listen(homeSummaryProvider, (_, _) {});
      final summary = await container.read(homeSummaryProvider.future);
      final graph = container.read(seedGraphProvider);
      final mine = graph.leadsOf(SeedGraph.meId);

      expect(summary.isNew, isFalse);
      for (final stage in summary.pipeline) {
        expect(
          stage.count,
          mine.where((l) => l.stageId == stage.stageId).length,
          reason: 'stage ${stage.stageId}',
        );
      }
      expect(summary.openLeads, mine.where((l) => l.isOpen).length);
      expect(
        summary.openDealsValue,
        mine.where((l) => l.isOpen).fold<int>(0, (s, l) => s + l.value),
      );
      expect(summary.agenda.length, lessThanOrEqualTo(6));
      expect(summary.followUpsDue, greaterThanOrEqualTo(summary.agenda.length));
      expect(
        summary.agenda.where((a) => a.isOverdue).length,
        lessThanOrEqualTo(summary.followUpsOverdue),
      );
      for (final item in summary.agenda) {
        final leadId = item.leadId;
        if (leadId == null) continue;
        expect(graph.lead(leadId).ownerId, SeedGraph.meId);
        expect(item.title, graph.lead(leadId).title);
      }
      expect(summary.team, isNull);
      expect(summary.money, isNull);
    });

    test('an owner gets money that adds up from won leads', () async {
      final container = await homeContainer(role: WorkspaceRole.owner);
      container.listen(homeSummaryProvider, (_, _) {});
      final summary = await container.read(homeSummaryProvider.future);
      final graph = container.read(seedGraphProvider);
      final money = summary.money;
      final won = graph.leads.where((l) => l.stageId == 5);

      expect(money, isNotNull);
      if (money == null) return;
      expect(money.salesMonth, won.fold<int>(0, (s, l) => s + l.value));
      expect(money.forecastWeeks.last, money.salesMonth);
      expect(money.topSellers, isNotEmpty);
      for (var i = 1; i < money.topSellers.length; i++) {
        expect(
          money.topSellers[i - 1].amount,
          greaterThanOrEqualTo(money.topSellers[i].amount),
        );
      }
      final pipelineTotal = summary.pipeline.fold<int>(
        0,
        (s, stage) => s + stage.count,
      );
      expect(pipelineTotal, graph.leads.where((l) => l.stageId <= 5).length);
      expect(
        money.today.cash + money.today.mobile + money.today.bank,
        money.today.total,
      );
    });

    test('a team lead gets the team and its approvals', () async {
      final container = await homeContainer(role: WorkspaceRole.teamLead);
      container.listen(homeSummaryProvider, (_, _) {});
      final summary = await container.read(homeSummaryProvider.future);
      final team = summary.team;

      expect(team, isNotNull);
      if (team == null) return;
      expect(team.members, isNotEmpty);
      expect(
        team.activityToday,
        greaterThanOrEqualTo(
          team.members.fold<int>(0, (s, m) => s + m.calls + m.visits),
        ),
      );
      expect(team.approvalsCount, greaterThanOrEqualTo(team.approvals.length));
    });

    test('the empty workspace comes back new and empty', () async {
      final container = await homeContainer(empty: true);
      container.listen(homeSummaryProvider, (_, _) {});
      final summary = await container.read(homeSummaryProvider.future);

      expect(summary.isNew, isTrue);
      expect(summary.agenda, isEmpty);
      expect(summary.onboarding.done, 1);
      expect(summary.onboarding.leadAdded, isFalse);
    });

    test('offline surfaces an offline failure', () async {
      final container = await homeContainer();
      goOffline(container);
      container.listen(homeSummaryProvider, (_, _) {});

      await expectLater(
        container.read(homeSummaryProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  test('summary JSON parses tolerantly', () {
    final summary = HomeSummary.fromJson(const {
      'IsNewWorkspace': false,
      'CallsToday': '4',
      'Agenda': [
        {'TaskId': 3, 'Kind': 'Visit', 'Title': 'Delta Power', 'LeadId': 2},
        'garbage',
      ],
    });
    expect(summary.callsToday, 4);
    expect(summary.agenda.single.kind, AgendaKind.visit);
    expect(summary.onboarding.done, 1);
  });
}
