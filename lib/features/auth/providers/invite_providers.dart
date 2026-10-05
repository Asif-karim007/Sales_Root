import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/auth/models/invitation.dart';
import 'package:salesroot/features/auth/models/referral.dart';
import 'package:salesroot/features/auth/models/team_setup.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';

part 'invite_providers.g.dart';

@riverpod
Future<Invitation> invitation(Ref ref, String code) =>
    ref.watch(authRepositoryProvider).invitation(code);

@riverpod
Future<Referral> referral(Ref ref, String code) =>
    ref.watch(authRepositoryProvider).referral(code);

enum InviteOutcome { accepted, declined }

@riverpod
class InviteActionNotifier extends _$InviteActionNotifier {
  @override
  FutureOr<InviteOutcome?> build(String code) => null;

  /// Joins the team and makes it the current workspace.
  Future<void> accept() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final current = ref.read(currentWorkspaceProvider.notifier);
    final result = await AsyncValue.guard(() async {
      final workspace = await ref
          .read(authRepositoryProvider)
          .acceptInvitation(code);
      await current.select(workspace);
      return workspace;
    });
    if (!ref.mounted) return;
    if (result.hasValue) {
      ref.invalidate(workspacesProvider);
      ref.read(signUpFlowProvider.notifier).clear();
    }
    state = result.whenData((_) => InviteOutcome.accepted);
  }

  Future<void> decline() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).declineInvitation(code);
      return InviteOutcome.declined;
    });
    if (!ref.mounted) return;
    if (result.hasValue) ref.read(signUpFlowProvider.notifier).clear();
    state = result;
  }
}

/// #9. A failed setup after the team exists retries only the setup.
@riverpod
class CreateTeamNotifier extends _$CreateTeamNotifier {
  Workspace? _created;

  @override
  FutureOr<Workspace?> build() => null;

  Future<void> create(String name, TeamSetup setup) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final workspace =
          _created ??
          await ref
              .read(workspacesProvider.notifier)
              .create(name, industryPack: setup.industry.wire);
      _created = workspace;
      await ref.read(authRepositoryProvider).setUpTeam(setup);
      return workspace;
    });
    if (!ref.mounted) return;
    state = result;
  }
}
