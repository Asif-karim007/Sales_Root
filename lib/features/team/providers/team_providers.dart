import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/team/data/api_team_repository.dart';
import 'package:salesroot/features/team/data/team_api.dart';
import 'package:salesroot/features/team/data/team_repository.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';

part 'team_providers.g.dart';

@Riverpod(keepAlive: true)
TeamApi teamApi(Ref ref) => TeamApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
TeamRepository teamRepository(Ref ref) {
  final me = ref.watch(currentWorkspaceProvider.select((w) => w?.membershipId));
  return ApiTeamRepository(ref.watch(teamApiProvider), me: me);
}

@riverpod
class MemberFilterNotifier extends _$MemberFilterNotifier {
  @override
  MemberFilter build() => MemberFilter.all;

  void set(MemberFilter filter) => state = filter;
}

@riverpod
class MemberListNotifier extends _$MemberListNotifier {
  static const countsKey = ApiTeamRepository.countsKey;

  @override
  Future<Paged<Member>> build() async {
    final filter = ref.watch(memberFilterProvider);
    final page = await ref
        .watch(teamRepositoryProvider)
        .members(MemberQuery(filter: filter));
    return Paged.first(page, facetKeys: const [countsKey]);
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
Future<Invite> invite(Ref ref, String id) =>
    ref.watch(teamRepositoryProvider).invite(id);

@riverpod
Future<List<Member>> teamDirectory(Ref ref) =>
    ref.watch(teamRepositoryProvider).directory();

@riverpod
Future<Member> member(Ref ref, String id) =>
    ref.watch(teamRepositoryProvider).member(id);

@riverpod
Future<List<SeatPack>> seatPacks(Ref ref) async {
  final repository = ref.watch(teamRepositoryProvider);
  final plan = await ref.watch(planProvider.future);
  if (plan == null) return const [];
  return repository.seatPacks(plan.code);
}

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

/// Revokes one pending invitation; true once done.
@riverpod
class InviteRevoker extends _$InviteRevoker {
  @override
  FutureOr<bool> build(String id) => false;

  Future<void> revoke() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(teamRepositoryProvider).revokeInvite(id);
      return true;
    });
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) _invalidateTeam(ref);
  }
}

/// Role, level, manager and active changes on one member.
@riverpod
class MemberEditor extends _$MemberEditor {
  @override
  FutureOr<Member?> build(String id) => null;

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
  FutureOr<bool> build(String id) => false;

  Future<void> remove({required String successorId}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(teamRepositoryProvider)
          .removeMember(id, successorId: successorId);
      return true;
    });
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) _invalidateTeam(ref);
  }
}

void _invalidateTeam(Ref ref, {String? memberId}) {
  ref
    ..invalidate(memberListProvider)
    ..invalidate(pendingInvitesProvider)
    ..invalidate(teamDirectoryProvider);
  if (memberId != null) ref.invalidate(memberProvider(memberId));
}
