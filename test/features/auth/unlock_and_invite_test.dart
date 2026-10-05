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

import '../../helpers/api_stub.dart';
import 'auth_test_setup.dart';

const _inviteId = 'invite-membership';
const _teamId = 'team-workspace';

Map<String, dynamic> _workspace(String id, String name, String role) => {
  ...(fixtureMap('auth_me')['workspaces'] as List).first
      as Map<String, dynamic>,
  'id': id,
  'name': name,
  'role': role,
};

/// `auth/me` for Rafi with one pending invitation to Karim Textiles.
Map<String, dynamic> _meInvited() => {
  ...fixtureMap('auth_me'),
  'invites': [
    {
      'membershipId': _inviteId,
      'workspaceId': _teamId,
      'workspaceName': 'Karim Textiles',
      'invitedByName': 'Karim Hossain',
      'role': 'executive',
    },
  ],
};

/// Tokens scoped to [workspaceId], as `POST auth/workspace/{id}` answers.
Map<String, dynamic> _tokensFor(String workspaceId) {
  final tokens = fixtureMap('auth_tokens');
  return {
    ...tokens,
    'accessToken': 'scoped.$workspaceId',
    'me': {...tokens['me'] as Map<String, dynamic>, 'workspaceId': workspaceId},
  };
}

void main() {
  group('PIN unlock', () {
    Future<PinUnlockNotifier> lockedWithPin(ProviderContainer container) async {
      await container.read(sessionProvider.future);
      await container.read(sessionStoreProvider).writePin('2580', testUserId);
      container.invalidate(pinLockProvider);
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

    test('the right PIN unlocks without the server', () async {
      final stub = authStub();
      final container = await authContainer(stub, signedIn: true);
      final notifier = await lockedWithPin(container);
      final calls = stub.requests.length;
      await type(notifier, '2580');

      expect(container.read(pinLockProvider).value, isFalse);
      expect(container.read(pinUnlockProvider).attempts, 0);
      expect(stub.requests, hasLength(calls));
    });

    test('a wrong PIN stays locked and counts the try', () async {
      final container = await authContainer(authStub(), signedIn: true);
      final notifier = await lockedWithPin(container);
      await type(notifier, '1111');

      expect(container.read(pinLockProvider).value, isTrue);
      expect(container.read(pinUnlockProvider).attempts, 1);
      expect(container.read(pinUnlockProvider).entry, isEmpty);
    });

    test('five wrong PINs sign out', () async {
      final stub = authStub()..on('POST', 'auth/logout', null);
      final container = await authContainer(stub, signedIn: true);
      final notifier = await lockedWithPin(container);
      for (var i = 0; i < 5; i++) {
        await type(notifier, '1111');
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(container.read(pinUnlockProvider).lockedOut, isTrue);
      expect(container.read(sessionProvider).value, isNull);
      expect(
        stub.lastBody('POST', 'auth/logout')['refreshToken'],
        'test.refresh',
      );
    });
  });

  group('invitation', () {
    test('reads the invitation from the account', () async {
      final stub = authStub()..on('GET', 'auth/me', _meInvited());
      final container = await authContainer(stub, signedIn: true);
      await container.read(sessionProvider.future);
      container.listen(invitationProvider(_inviteId), (_, _) {});

      final invite = await container.read(invitationProvider(_inviteId).future);
      expect(invite.workspaceName, 'Karim Textiles');
      expect(invite.inviter.en, 'Karim Hossain');
      expect(invite.role, WorkspaceRole.member);
    });

    test('one no longer on the account is a 404', () async {
      final container = await authContainer(authStub(), signedIn: true);
      await container.read(sessionProvider.future);
      container.listen(invitationProvider('gone'), (_, _) {});

      await expectLater(
        container.read(invitationProvider('gone').future),
        throwsA(isA<ApiFailure>().having((f) => f.isNotFound, '404', true)),
      );
    });

    test('accepting joins the team and switches to it', () async {
      var accepted = false;
      final stub = authStub()
        ..on(
          'GET',
          'auth/me',
          (_) => accepted
              ? {
                  ...fixtureMap('auth_me'),
                  'workspaces': [
                    ...fixtureMap('auth_me')['workspaces'] as List,
                    _workspace(_teamId, 'Karim Textiles', 'executive'),
                  ],
                }
              : _meInvited(),
        )
        ..on('POST', 'workspaces/invites/{id}/accept', (_) {
          accepted = true;
          return null;
        })
        ..on('POST', 'auth/workspace/{id}', _tokensFor(_teamId));
      final container = await authContainer(stub, signedIn: true);
      await container.read(workspacesProvider.future);
      container
        ..listen(currentWorkspaceProvider, (_, _) {})
        ..listen(inviteActionProvider(_inviteId), (_, _) {});

      await container.read(inviteActionProvider(_inviteId).notifier).accept();

      expect(
        container.read(inviteActionProvider(_inviteId)).value,
        InviteOutcome.accepted,
      );
      expect(
        stub.last('POST', 'workspaces/invites/{id}/accept')?.path,
        contains(_inviteId),
      );
      expect(stub.last('POST', 'auth/workspace/{id}')?.path, endsWith(_teamId));
      await container.read(workspacesProvider.future);
      expect(container.read(currentWorkspaceProvider)?.id, _teamId);
      expect(container.read(sessionProvider).value?.token, 'scoped.$_teamId');
    });

    test('declining tells the server', () async {
      final stub = authStub()
        ..on('GET', 'auth/me', _meInvited())
        ..on('POST', 'workspaces/invites/{id}/decline', null);
      final container = await authContainer(stub, signedIn: true);
      await container.read(sessionProvider.future);
      container.listen(inviteActionProvider(_inviteId), (_, _) {});

      await container.read(inviteActionProvider(_inviteId).notifier).decline();

      expect(
        container.read(inviteActionProvider(_inviteId)).value,
        InviteOutcome.declined,
      );
      expect(
        stub.last('POST', 'workspaces/invites/{id}/decline')?.path,
        contains(_inviteId),
      );
    });
  });

  group('create team', () {
    const setup = TeamSetup(
      industry: IndustryTemplate.trading,
      currency: TeamCurrency.bdt,
    );

    ApiStub teamStub({bool failSetup = false}) {
      var created = false;
      final stub = authStub()
        ..on(
          'GET',
          'auth/me',
          (_) => created
              ? {
                  ...fixtureMap('auth_me'),
                  'workspaces': [
                    ...fixtureMap('auth_me')['workspaces'] as List,
                    _workspace(_teamId, 'Rajshahi Solar', 'owner'),
                  ],
                }
              : fixtureMap('auth_me'),
        )
        ..on('POST', 'workspaces', (_) {
          created = true;
          return {'id': _teamId};
        })
        ..on('POST', 'auth/workspace/{id}', _tokensFor(_teamId))
        ..on('PATCH', 'workspaces/current', null);
      if (failSetup) stub.fail('PATCH', 'workspaces/current', 500);
      return stub;
    }

    test('creates it, signs into it and applies the setup', () async {
      final stub = teamStub();
      final container = await authContainer(stub, signedIn: true);
      await container.read(workspacesProvider.future);
      container
        ..listen(currentWorkspaceProvider, (_, _) {})
        ..listen(createTeamProvider, (_, _) {});

      await container
          .read(createTeamProvider.notifier)
          .create('Rajshahi Solar', setup);

      final created = container.read(createTeamProvider).value;
      expect(created?.id, _teamId);
      expect(created?.role, WorkspaceRole.owner);
      expect(stub.lastBody('POST', 'workspaces')['name'], 'Rajshahi Solar');
      expect(stub.lastBody('PATCH', 'workspaces/current'), {
        'industryPack': 'distribution',
        'currency': 'BDT',
      });
      expect(
        stub.last('PATCH', 'workspaces/current')?.headers['Authorization'],
        'Bearer scoped.$_teamId',
      );
      expect(container.read(currentWorkspaceProvider)?.name, 'Rajshahi Solar');
    });

    test('a failed setup retries only the setup', () async {
      final stub = teamStub(failSetup: true);
      final container = await authContainer(stub, signedIn: true);
      await container.read(workspacesProvider.future);
      container.listen(createTeamProvider, (_, _) {});
      final notifier = container.read(createTeamProvider.notifier);

      await notifier.create('Rajshahi Solar', setup);
      expect(container.read(createTeamProvider).hasError, isTrue);

      stub.on('PATCH', 'workspaces/current', null);
      await notifier.create('Rajshahi Solar', setup);
      expect(container.read(createTeamProvider).value?.id, _teamId);
      expect(
        stub.requests.where(
          (r) => r.method == 'POST' && r.uri.path.endsWith('/workspaces'),
        ),
        hasLength(1),
      );
    });
  });
}
