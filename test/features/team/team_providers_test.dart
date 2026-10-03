import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';

import 'team_test_helpers.dart';

void main() {
  late ProviderContainer container;

  tearDown(() => container.dispose());

  group('members', () {
    test('pages 20 at a time with filter counts', () async {
      container = await teamContainer();
      container.listen(memberListProvider, (_, _) {});

      final first = await container.read(memberListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.totalCount, 21);
      expect(first.facets[MemberListNotifier.countsKey]?['All'], 21);
      expect(first.items.first.role, WorkspaceRole.owner);

      await container.read(memberListProvider.notifier).loadMore();
      final all = container.read(memberListProvider).requireValue;
      expect(all.items, hasLength(21));
      expect(all.hasMore, isFalse);
    });

    test('the team leads filter rebuilds the list', () async {
      container = await teamContainer();
      container.listen(memberListProvider, (_, _) {});
      container.read(memberFilterProvider.notifier).set(MemberFilter.teamLeads);

      final leads = await container.read(memberListProvider.future);
      expect(leads.items.map((m) => m.role).toSet(), {WorkspaceRole.teamLead});
    });

    test('offline shows as an offline failure', () async {
      container = await teamContainer();
      setDev(container, (s) => s.copyWith(offline: true));

      await expectLater(
        container.read(teamRepositoryProvider).members(const MemberQuery()),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('invite', () {
    const input = InviteInput(
      channel: InviteChannel.phone,
      phone: '01912 999 888',
      name: 'Tanvir Hasan',
      managerId: 3,
    );

    test('sends, lists it as pending and builds the accept link', () async {
      container = await teamContainer();
      container.listen(inviteSenderProvider, (_, _) {});

      await container.read(inviteSenderProvider.notifier).send(input);

      final invite = container.read(inviteSenderProvider).requireValue;
      expect(invite, isNotNull);
      expect(invite?.phone, '+8801912999888');
      expect(
        invite?.link,
        endsWith(Routes.acceptInviteFor(invite?.code ?? '')),
      );
      expect(invite?.managerName?.en, 'Rafiqul Islam');
      final pending = await container.read(pendingInvitesProvider.future);
      expect(pending.map((i) => i.id), contains(invite?.id));
    });

    test('a full plan answers 402 for users', () async {
      container = await teamContainer();
      container.listen(inviteSenderProvider, (_, _) {});
      setDev(container, (s) => s.copyWith(quotaReached: true));

      await container.read(inviteSenderProvider.notifier).send(input);

      final failure = container.read(inviteSenderProvider).error;
      expect(failure, isA<ApiFailure>());
      expect((failure as ApiFailure).isQuota, isTrue);
      expect(failure.quota, QuotaKind.users);
    });

    test('rejects a bad number and a duplicate', () async {
      container = await teamContainer();
      final repository = container.read(teamRepositoryProvider);

      await expectLater(
        repository.sendInvite(
          const InviteInput(channel: InviteChannel.phone, phone: '12345'),
        ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.fieldError('Phone'),
            'Phone',
            isNotNull,
          ),
        ),
      );
      await expectLater(
        repository.sendInvite(
          const InviteInput(
            channel: InviteChannel.phone,
            phone: '+8801912345678',
          ),
        ),
        throwsA(
          isA<ApiFailure>().having((f) => f.isConflict, 'conflict', true),
        ),
      );
    });

    test('a member may not invite', () async {
      container = await teamContainer(role: WorkspaceRole.member);

      await expectLater(
        container.read(teamRepositoryProvider).sendInvite(input),
        throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
      );
    });

    test('revoking removes it from the pending list', () async {
      container = await teamContainer();
      container.listen(inviteActionsProvider(1), (_, _) {});

      await container.read(inviteActionsProvider(1).notifier).revoke();

      expect(
        container.read(inviteActionsProvider(1)).value,
        InviteOutcome.revoked,
      );
      final pending = await container.read(pendingInvitesProvider.future);
      expect(pending.map((i) => i.id), isNot(contains(1)));
    });
  });

  group('remove member', () {
    test('reassigns their reports and removes them', () async {
      container = await teamContainer();
      container.listen(memberRemovalProvider(3), (_, _) {});
      final before = await container.read(teamDirectoryProvider.future);
      final reports = before.where((m) => m.managerId == 3).map((m) => m.id);
      expect(reports, isNotEmpty);

      await container
          .read(memberRemovalProvider(3).notifier)
          .remove(const RemovalInput(reassignToId: 8, reason: 'Left'));

      expect(container.read(memberRemovalProvider(3)).value, isTrue);
      final after = await container.read(teamDirectoryProvider.future);
      expect(after.map((m) => m.id), isNot(contains(3)));
      for (final id in reports) {
        expect(after.firstWhere((m) => m.id == id).managerId, 2);
      }
    });

    test('needs someone to take over', () async {
      container = await teamContainer();
      container.listen(memberRemovalProvider(5), (_, _) {});

      await container
          .read(memberRemovalProvider(5).notifier)
          .remove(const RemovalInput(reassignToId: null));

      final failure = container.read(memberRemovalProvider(5)).error;
      expect(failure, isA<ApiFailure>());
      expect((failure as ApiFailure).isValidation, isTrue);
      final directory = await container.read(teamDirectoryProvider.future);
      expect(directory.map((m) => m.id), contains(5));
    });

    test('the owner cannot be removed', () async {
      container = await teamContainer();

      await expectLater(
        container
            .read(teamRepositoryProvider)
            .removeMember(2, const RemovalInput(reassignToId: 3)),
        throwsA(isA<ApiFailure>().having((f) => f.isValidation, '400', true)),
      );
    });
  });

  test('member detail carries stats and a role change persists', () async {
    container = await teamContainer();
    container.listen(memberEditorProvider(5), (_, _) {});

    final member = await container.read(memberProvider(5).future);
    expect(member.stats, isNotNull);
    expect(member.canEdit, isTrue);

    await container
        .read(memberEditorProvider(5).notifier)
        .apply(const MemberUpdate(role: WorkspaceRole.teamLead));

    final updated = await container.read(memberProvider(5).future);
    expect(updated.role, WorkspaceRole.teamLead);
  });
}
