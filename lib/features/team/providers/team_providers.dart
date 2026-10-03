import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/team/data/fake_team_repository.dart';
import 'package:salesroot/features/team/data/team_repository.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';

part 'team_providers.g.dart';

@Riverpod(keepAlive: true)
TeamRepository teamRepository(Ref ref) =>
    FakeTeamRepository(ref.watch(fakeBackendProvider));

@riverpod
class MemberFilterNotifier extends _$MemberFilterNotifier {
  @override
  MemberFilter build() => MemberFilter.all;

  void set(MemberFilter filter) => state = filter;
}

@riverpod
class MemberListNotifier extends _$MemberListNotifier {
  static const countsKey = 'Counts';

  @override
  Future<Paged<Member>> build() async {
    final filter = ref.watch(memberFilterProvider);
    final page = await ref
        .watch(teamRepositoryProvider)
        .members(MemberQuery(filter: filter));
    return Paged.first(page, facetKeys: const [countsKey]);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(teamRepositoryProvider)
          .members(
            MemberQuery(
              filter: ref.read(memberFilterProvider),
              page: current.page + 1,
            ),
          );
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<List<Invite>> pendingInvites(Ref ref) =>
    ref.watch(teamRepositoryProvider).invites();

@riverpod
Future<Invite> invite(Ref ref, int id) =>
    ref.watch(teamRepositoryProvider).invite(id);

@riverpod
Future<List<Member>> teamDirectory(Ref ref) =>
    ref.watch(teamRepositoryProvider).directory();

@riverpod
Future<Member> member(Ref ref, int id) =>
    ref.watch(teamRepositoryProvider).member(id);

@riverpod
Future<List<SeatPack>> seatPacks(Ref ref) =>
    ref.watch(teamRepositoryProvider).seatPacks();

/// Sends an invitation; the form listens for the sent invite or the failure.
@riverpod
class InviteSender extends _$InviteSender {
  @override
  FutureOr<Invite?> build() => null;

  Future<void> send(InviteInput input) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(teamRepositoryProvider).sendInvite(input),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) _invalidateTeam(ref);
  }
}

/// Resend and revoke on one pending invitation.
@riverpod
class InviteActions extends _$InviteActions {
  @override
  FutureOr<InviteOutcome?> build(int id) => null;

  Future<void> resend() => _run(InviteOutcome.resent, () async {
    await ref.read(teamRepositoryProvider).resendInvite(id);
  });

  Future<void> revoke() => _run(
    InviteOutcome.revoked,
    () => ref.read(teamRepositoryProvider).revokeInvite(id),
  );

  Future<void> _run(InviteOutcome outcome, Future<void> Function() work) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await work();
      return outcome;
    });
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) _invalidateTeam(ref);
  }
}

enum InviteOutcome { resent, revoked }

/// Role, level, manager and active changes on one member.
@riverpod
class MemberEditor extends _$MemberEditor {
  @override
  FutureOr<Member?> build(int id) => null;

  Future<void> apply(MemberUpdate update) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(teamRepositoryProvider).updateMember(id, update),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) _invalidateTeam(ref, memberId: id);
  }
}

/// Hands a member's work over and removes them; true once done.
@riverpod
class MemberRemoval extends _$MemberRemoval {
  @override
  FutureOr<bool> build(int id) => false;

  Future<void> remove(RemovalInput input) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(teamRepositoryProvider).removeMember(id, input);
      return true;
    });
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) _invalidateTeam(ref);
  }
}

void _invalidateTeam(Ref ref, {int? memberId}) {
  ref
    ..invalidate(memberListProvider)
    ..invalidate(pendingInvitesProvider)
    ..invalidate(teamDirectoryProvider);
  if (memberId != null) ref.invalidate(memberProvider(memberId));
}
