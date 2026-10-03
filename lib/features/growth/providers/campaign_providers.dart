import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/data/campaign_repository.dart';
import 'package:salesroot/features/growth/data/fake_campaign_repository.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';

part 'campaign_providers.g.dart';

@Riverpod(keepAlive: true)
CampaignRepository campaignRepository(Ref ref) =>
    FakeCampaignRepository(ref.watch(fakeBackendProvider));

/// The campaign list (#143).
@riverpod
class CampaignListNotifier extends _$CampaignListNotifier {
  @override
  Future<Paged<Campaign>> build() async =>
      Paged.first(await ref.watch(campaignRepositoryProvider).list());

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(campaignRepositoryProvider)
          .list(page: current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref
      ..invalidateSelf()
      ..invalidate(messagingBalanceProvider);
    await future;
  }
}

@riverpod
Future<Campaign> campaign(Ref ref, int id) =>
    ref.watch(campaignRepositoryProvider).get(id);

@riverpod
Future<MessagingBalance> messagingBalance(Ref ref) =>
    ref.watch(campaignRepositoryProvider).balance();

@riverpod
Future<List<Audience>> campaignAudiences(Ref ref) =>
    ref.watch(campaignRepositoryProvider).audiences();

@riverpod
Future<List<MessageTemplate>> smsTemplates(Ref ref) =>
    ref.watch(campaignRepositoryProvider).smsTemplates();

@riverpod
Future<List<CreditPack>> creditPacks(Ref ref) =>
    ref.watch(campaignRepositoryProvider).creditPacks();

/// Test sends, retries and cancellations; callers show the outcome.
@Riverpod(keepAlive: true)
class CampaignActions extends _$CampaignActions {
  @override
  void build() {}

  Future<void> testSms(String message) async {
    await ref.read(campaignRepositoryProvider).testSms(message);
    if (ref.mounted) ref.invalidate(messagingBalanceProvider);
  }

  Future<Campaign> retry(int id) =>
      _change(id, () => ref.read(campaignRepositoryProvider).retryFailed(id));

  Future<Campaign> cancel(int id) =>
      _change(id, () => ref.read(campaignRepositoryProvider).cancel(id));

  Future<Campaign> _change(int id, Future<Campaign> Function() work) async {
    final campaign = await work();
    if (ref.mounted) {
      ref
        ..invalidate(campaignProvider(id))
        ..invalidate(campaignListProvider)
        ..invalidate(messagingBalanceProvider);
    }
    return campaign;
  }
}

/// Sending or scheduling a bulk SMS (#144).
@riverpod
class SmsCampaignSubmit extends _$SmsCampaignSubmit {
  @override
  AsyncValue<Campaign?> build() => const AsyncData(null);

  Future<void> submit(SmsCampaignInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(campaignRepositoryProvider).sendSms(input),
    );
    if (!ref.mounted) return;
    state = result;
    ref.invalidate(messagingBalanceProvider);
    if (result.hasValue) ref.invalidate(campaignListProvider);
  }
}

/// Sending a bulk email (#145).
@riverpod
class EmailCampaignSubmit extends _$EmailCampaignSubmit {
  @override
  AsyncValue<Campaign?> build() => const AsyncData(null);

  Future<void> submit(EmailCampaignInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(campaignRepositoryProvider).sendEmail(input),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) {
      ref
        ..invalidate(campaignListProvider)
        ..invalidate(messagingBalanceProvider);
    }
  }
}

/// Buying an SMS credit pack (#147).
@riverpod
class CreditPurchase extends _$CreditPurchase {
  @override
  AsyncValue<MessagingBalance?> build() => const AsyncData(null);

  Future<void> buy(int packId) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(campaignRepositoryProvider).buyCredits(packId),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) ref.invalidate(messagingBalanceProvider);
  }
}
