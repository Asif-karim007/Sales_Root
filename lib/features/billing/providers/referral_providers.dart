import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/billing/data/billing_repositories.dart';
import 'package:salesroot/features/billing/models/referral.dart';

part 'referral_providers.g.dart';

@riverpod
Future<ReferralOverview> referralOverview(Ref ref) =>
    ref.watch(referralRepositoryProvider).overview();

@riverpod
class ReferralsNotifier extends _$ReferralsNotifier {
  @override
  Future<Paged<Referral>> build() async =>
      Paged.first(await ref.watch(referralRepositoryProvider).list(1));

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(referralRepositoryProvider)
          .list(current.page + 1);
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
Future<InviteEligibility> inviteCheck(Ref ref, String contact) =>
    ref.watch(referralRepositoryProvider).check(contact);

/// Sends or records one invite; the data is the server's answer once saved.
@riverpod
class InviteNotifier extends _$InviteNotifier {
  @override
  FutureOr<InviteResult?> build() => null;

  Future<void> send(String contact, {required bool sms}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(referralRepositoryProvider)
          .invite(contact, sendSms: sms);
      if (!ref.mounted) return;
      ref
        ..invalidate(referralOverviewProvider)
        ..invalidate(referralsProvider)
        ..invalidate(inviteCheckProvider(contact));
      state = AsyncData(result);
    } on ApiFailure catch (failure, stack) {
      if (!ref.mounted) return;
      state = AsyncError(failure, stack);
    }
  }
}
