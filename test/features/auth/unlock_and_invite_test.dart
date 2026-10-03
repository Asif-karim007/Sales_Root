import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/session/session_store.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/models/team_setup.dart';
import 'package:salesroot/features/auth/providers/invite_providers.dart';
import 'package:salesroot/features/auth/providers/pin_providers.dart';

import 'auth_test_setup.dart';

void main() {
  group('PIN unlock', () {
    Future<PinUnlockNotifier> lockedWithPin(ProviderContainer container) async {
      await container.read(sessionProvider.future);
      await container.read(sessionStoreProvider).writePin('2580', 1);
      expect(await container.read(pinLockProvider.future), isTrue);
      container.listen(pinUnlockProvider, (_, _) {});
      return container.read(pinUnlockProvider.notifier);
    }

    Future<void> type(PinUnlockNotifier notifier, String pin) async {
      for (final d in pin.split('')) {
        notifier.digit(int.parse(d));
      }
      await settle();
    }

    test('the right PIN unlocks', () async {
      final container = await authContainer(secure: storedSession);
      final notifier = await lockedWithPin(container);
      await type(notifier, '2580');

      expect(container.read(pinLockProvider).value, isFalse);
      expect(container.read(pinUnlockProvider).attempts, 0);
    });

    test('a wrong PIN stays locked and counts the try', () async {
      final container = await authContainer(secure: storedSession);
      final notifier = await lockedWithPin(container);
      await type(notifier, '1111');

      expect(container.read(pinLockProvider).value, isTrue);
      expect(container.read(pinUnlockProvider).attempts, 1);
      expect(container.read(pinUnlockProvider).entry, isEmpty);
    });

    test('five wrong PINs sign out', () async {
      final container = await authContainer(secure: storedSession);
      final notifier = await lockedWithPin(container);
      for (var i = 0; i < 5; i++) {
        await type(notifier, '1111');
      }

      expect(container.read(pinUnlockProvider).lockedOut, isTrue);
      expect(container.read(sessionProvider).value, isNull);
    });
  });

  group('invitation', () {
    test('accepting while signed in joins and selects the team', () async {
      final container = await authContainer(secure: storedSession);
      await container.read(workspacesProvider.future);
      container.listen(currentWorkspaceProvider, (_, _) {});
      container.listen(inviteActionProvider('MGS4K8'), (_, _) {});
      await container.read(inviteActionProvider('MGS4K8').notifier).accept();

      expect(
        container.read(inviteActionProvider('MGS4K8')).value,
        InviteOutcome.accepted,
      );
      final list = await container.read(workspacesProvider.future);
      final joined = list.where((w) => w.id == 400).single;
      expect(joined.role, WorkspaceRole.member);
      expect(container.read(currentWorkspaceProvider)?.id, 400);
    });

    test('an expired invitation is a 404', () async {
      final container = await authContainer();
      container.listen(invitationProvider('OLD9X1'), (_, _) {});
      await expectLater(
        container.read(invitationProvider('OLD9X1').future),
        throwsA(
          isA<ApiFailure>().having((f) => f.isNotFound, 'isNotFound', true),
        ),
      );
    });

    test(
      'creating a team makes the user its owner and switches to it',
      () async {
        final container = await authContainer(secure: storedSession);
        await container.read(workspacesProvider.future);
        container.listen(currentWorkspaceProvider, (_, _) {});
        container.listen(createTeamProvider, (_, _) {});
        await container
            .read(createTeamProvider.notifier)
            .create(
              'Rajshahi Solar',
              const TeamSetup(
                industry: IndustryTemplate.trading,
                currency: TeamCurrency.bdt,
              ),
            );

        final created = container.read(createTeamProvider).value;
        expect(created?.role, WorkspaceRole.owner);
        await container.read(workspacesProvider.future);
        expect(
          container.read(currentWorkspaceProvider)?.name,
          'Rajshahi Solar',
        );
      },
    );
  });
}
