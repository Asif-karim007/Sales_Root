import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/billing/data/fake_referral_repository.dart';
import 'package:salesroot/features/billing/data/referral_repository.dart';
import 'package:salesroot/features/billing/models/referral.dart';

part 'referral_providers.g.dart';

@Riverpod(keepAlive: true)
ReferralRepository referralRepository(Ref ref) =>
    FakeReferralRepository(ref.watch(fakeBackendProvider));

@riverpod
Future<ReferralOverview> referralOverview(Ref ref) =>
    ref.watch(referralRepositoryProvider).overview();

/// The status chip on the referral list; null shows all.
@riverpod
class ReferralFilter extends _$ReferralFilter {
  @override
  ReferralStatus? build() => null;

  void set(ReferralStatus? status) => state = status;
}

@riverpod
class ReferralsNotifier extends _$ReferralsNotifier {
  @override
  Future<Paged<Referral>> build() async {
    final status = ref.watch(referralFilterProvider);
    final first = await ref
        .watch(referralRepositoryProvider)
        .list(ReferralQuery(status: status));
    return Paged.first(first, facetKeys: const ['StatusCounts']);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(referralRepositoryProvider)
          .list(
            ReferralQuery(
              status: ref.read(referralFilterProvider),
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
}

@riverpod
class WalletEntriesNotifier extends _$WalletEntriesNotifier {
  @override
  Future<Paged<WalletEntry>> build() async =>
      Paged.first(await ref.watch(referralRepositoryProvider).wallet(1));

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(referralRepositoryProvider)
          .wallet(current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }
}

@riverpod
Future<List<LeaderboardEntry>> referralLeaderboard(Ref ref) =>
    ref.watch(referralRepositoryProvider).leaderboard();

@riverpod
Future<InviteCheck> inviteCheck(Ref ref, String contact) =>
    ref.watch(referralRepositoryProvider).check(contact);

/// Sends or records one invite; the data is the referral once saved.
@riverpod
class InviteNotifier extends _$InviteNotifier {
  @override
  FutureOr<Referral?> build() => null;

  Future<void> send(String contact, {required bool sms}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      final referral = await ref
          .read(referralRepositoryProvider)
          .invite(contact, sendSms: sms);
      if (!ref.mounted) return;
      ref
        ..invalidate(referralOverviewProvider)
        ..invalidate(referralsProvider)
        ..invalidate(inviteCheckProvider(contact));
      state = AsyncData(referral);
    } on ApiFailure catch (failure, stack) {
      if (!ref.mounted) return;
      state = AsyncError(failure, stack);
    }
  }
}

/// The reward to celebrate once; marked seen as soon as it is shown.
@riverpod
class PendingRewardNotifier extends _$PendingRewardNotifier {
  @override
  Future<RewardMoment?> build() =>
      ref.watch(referralRepositoryProvider).pendingReward();

  Future<void> markSeen(int id) async {
    state = const AsyncData(null);
    try {
      await ref.read(referralRepositoryProvider).markRewardSeen(id);
    } on ApiFailure {
      return;
    }
  }
}
