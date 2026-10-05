import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';

import '../../helpers/api_stub.dart';
import 'team_test_helpers.dart';

void main() {
  late ApiStub stub;
  late ProviderContainer container;

  Future<void> start({String role = 'owner', bool withInvite = false}) async {
    stub = teamStub(withInvite: withInvite);
    container = await teamContainer(stub: stub, role: role);
  }

  group('members', () {
    test('parses the roster with managers, reports and today', () async {
      await start();
      container.listen(memberListProvider, (_, _) {});

      final list = await container.read(memberListProvider.future);
      final members = list.items;
      expect(members, hasLength(5));
      expect(members.first.id, nadia);
      expect(members.first.isOwner, isTrue);
      expect(members[1].role, MemberRole.teamLead);

      final me = members.firstWhere((m) => m.id == rafi);
      expect(me.isMe, isTrue);
      expect(me.name.en, 'Rafi Ahmed');
      expect(me.phone, '+8801711000002');
      expect(me.level, ExperienceLevel.easy);
      expect(me.managerId, rumpa);
      expect(me.managerName?.en, 'Rumpa Sarker');
      expect(me.status, MemberStatus.active);
      expect(me.joiningDate, isNotNull);

      final lead = members.firstWhere((m) => m.id == rumpa);
      expect(lead.reportCount, 2);
      expect(lead.status, MemberStatus.notStarted);
      expect(
        members.firstWhere((m) => m.name.en == 'Karim Hossain').role,
        MemberRole.finance,
      );
      expect(list.hasMore, isFalse);
    });

    test('filters by chip, with counts for every chip', () async {
      await start(withInvite: true);
      container.listen(memberListProvider, (_, _) {});

      final all = await container.read(memberListProvider.future);
      expect(all.items.map((m) => m.id), isNot(contains(tanvir)));
      expect(all.facets[MemberListNotifier.countsKey], {
        'all': 5,
        'activeToday': 1,
        'pending': 1,
        'teamLeads': 1,
      });

      container.read(memberFilterProvider.notifier).set(MemberFilter.teamLeads);
      final leads = await container.read(memberListProvider.future);
      expect(leads.items.map((m) => m.id), [rumpa]);

      container
          .read(memberFilterProvider.notifier)
          .set(MemberFilter.activeToday);
      final active = await container.read(memberListProvider.future);
      expect(active.items.map((m) => m.id), [rafi]);
    });

    test('lists without today when attendance is forbidden', () async {
      await start(role: 'executive');
      stub.on('GET', 'attendance', fixture('team_forbidden'), status: 403);

      final members = await container.read(teamDirectoryProvider.future);
      expect(members, hasLength(5));
      expect(members.every((m) => m.status == MemberStatus.notStarted), isTrue);
    });

    test('a suspended member shows as deactivated, last', () async {
      await start();
      stub.on('GET', 'workspaces/members', [
        for (final row in membersWith())
          row['id'] == bushra ? {...row, 'status': 'suspended'} : row,
      ]);

      final members = await container.read(teamDirectoryProvider.future);
      expect(members.last.id, bushra);
      expect(members.last.isActive, isFalse);
      expect(members.last.status, MemberStatus.deactivated);
    });

    test('offline is an offline failure', () async {
      await start();
      stub.offline = true;

      await expectLater(
        container.read(teamDirectoryProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('member detail', () {
    test('adds this month and open work for people in the targets', () async {
      await start();

      final member = await container.read(memberProvider(rafi).future);
      final stats = member.stats;
      expect(stats?.leadsThisMonth, 3);
      expect(stats?.collected, 7000);
      expect(stats?.openLeads, 3);
      expect(stats?.overdueTasks, 3);
      final leads = stub.last('GET', 'leads')?.queryParameters;
      expect(leads?['ownerId'], rafi);
      expect(leads?['status'], 'open');
      final tasks = stub.last('GET', 'tasks')?.queryParameters;
      expect(tasks?['assignee'], rafi);
      expect(tasks?['view'], 'overdue');
    });

    test('has no numbers for people outside the targets', () async {
      await start();

      final member = await container.read(memberProvider(bushra).future);
      expect(member.stats, isNull);
      expect(stub.last('GET', 'leads'), isNull);
    });

    test('an unknown id is not found', () async {
      await start();

      await expectLater(
        container.read(memberProvider('nobody').future),
        throwsA(isA<ApiFailure>().having((f) => f.isNotFound, '404', true)),
      );
    });
  });

  group('changes', () {
    test('a role change patches only the role', () async {
      await start();
      stub.on('PATCH', 'workspaces/members/{id}', <String, dynamic>{});
      final editor = memberEditorProvider(bushra);
      container.listen(editor, (_, _) {});

      await container
          .read(editor.notifier)
          .apply(const MemberUpdate(role: MemberRole.teamLead));

      expect(container.read(editor).value?.id, bushra);
      expect(
        stub.last('PATCH', 'workspaces/members/{id}')?.path,
        endsWith(bushra),
      );
      expect(stub.lastBody('PATCH', 'workspaces/members/{id}'), {
        'role': 'teamlead',
      });
    });

    test('deactivating sends the suspended status', () async {
      await start();
      stub.on('PATCH', 'workspaces/members/{id}', <String, dynamic>{});
      final editor = memberEditorProvider(bushra);
      container.listen(editor, (_, _) {});

      await container
          .read(editor.notifier)
          .apply(const MemberUpdate(status: MembershipStatus.suspended));

      expect(stub.lastBody('PATCH', 'workspaces/members/{id}'), {
        'status': 'suspended',
      });
    });

    test('a member without the right gets the 403', () async {
      await start(role: 'executive');
      stub.fail(
        'PATCH',
        'workspaces/members/{id}',
        403,
        code: 'E-403',
        message: "You don't have permission for this. Ask your manager",
      );
      final editor = memberEditorProvider(bushra);
      container.listen(editor, (_, _) {});

      await container
          .read(editor.notifier)
          .apply(const MemberUpdate(level: ExperienceLevel.standard));

      final failure = container.read(editor).error;
      expect((failure as ApiFailure?)?.isForbidden, isTrue);
    });

    test('removing hands the work to the successor', () async {
      await start();
      stub.on('PATCH', 'workspaces/members/{id}', <String, dynamic>{});
      final removal = memberRemovalProvider(bushra);
      container.listen(removal, (_, _) {});

      await container.read(removal.notifier).remove(successorId: rumpa);

      expect(container.read(removal).value, isTrue);
      expect(stub.lastBody('PATCH', 'workspaces/members/{id}'), {
        'status': 'removed',
        'successorId': rumpa,
      });
    });
  });

  group('invitations', () {
    const input = InviteInput(
      phone: '+880 1912-999888',
      managerId: rumpa,
      level: ExperienceLevel.easy,
    );

    test('sends the InviteRequest and opens the new invitation', () async {
      await start(withInvite: true);
      stub.on(
        'POST',
        'workspaces/members/invite',
        (RequestOptions r) => {
          'id': tanvir,
          'status': 'invited',
          ...r.data as Map<String, dynamic>,
        },
      );
      container.listen(inviteSenderProvider, (_, _) {});

      await container.read(inviteSenderProvider.notifier).send(input);

      expect(stub.lastBody('POST', 'workspaces/members/invite'), {
        'phone': '+8801912999888',
        'role': 'executive',
        'reportsTo': rumpa,
        'level': 'easy',
      });
      final sent = container.read(inviteSenderProvider).requireValue;
      expect(sent?.id, tanvir);
      final invite = await container.read(inviteProvider(tanvir).future);
      expect(invite.phone, '+8801912999888');
      expect(invite.managerName?.en, 'Rumpa Sarker');
      expect(invite.expiresAt?.toUtc(), DateTime.utc(2026, 10, 12, 9));
    });

    test('a bad number, a duplicate and a full plan fail as such', () async {
      await start();
      final repository = container.read(teamRepositoryProvider);

      stub.fail(
        'POST',
        'workspaces/members/invite',
        422,
        code: 'V-002',
        message: 'Enter a valid mobile number',
        field: 'phone',
      );
      await expectLater(
        repository.sendInvite(const InviteInput(phone: '12345')),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.fieldError('phone'),
            'phone',
            'Enter a valid mobile number',
          ),
        ),
      );

      stub.fail('POST', 'workspaces/members/invite', 409, message: 'Exists');
      await expectLater(
        repository.sendInvite(input),
        throwsA(isA<ApiFailure>().having((f) => f.isConflict, '409', true)),
      );

      stub.fail('POST', 'workspaces/members/invite', 402, message: 'Seats');
      await expectLater(
        repository.sendInvite(input),
        throwsA(isA<ApiFailure>().having((f) => f.isQuota, '402', true)),
      );
    });

    test('pending lists the invited, and revoking removes one', () async {
      await start(withInvite: true);
      stub.on('PATCH', 'workspaces/members/{id}', <String, dynamic>{});
      final revoker = inviteRevokerProvider(tanvir);
      container.listen(revoker, (_, _) {});

      final pending = await container.read(pendingInvitesProvider.future);
      expect(pending.map((i) => i.id), [tanvir]);
      expect(pending.single.label, '+8801912999888');

      await container.read(revoker.notifier).revoke();

      expect(container.read(revoker).value, isTrue);
      expect(stub.lastBody('PATCH', 'workspaces/members/{id}'), {
        'status': 'removed',
      });
    });
  });

  test('seat packs are priced from the plan catalogue', () async {
    await start();

    final packs = await container.read(seatPacksProvider.future);
    expect(packs.map((p) => p.seats), [1, 5, 10]);
    expect(packs.map((p) => p.pricePerMonth), [599, 2995, 5990]);
  });
}
