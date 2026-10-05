import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/growth/data/api_campaign_repository.dart';
import 'package:salesroot/features/growth/data/campaign_repository.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';

part 'campaign_providers.g.dart';

@Riverpod(keepAlive: true)
CampaignRepository campaignRepository(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiCampaignRepository(ref.watch(growthApiProvider));
}

/// The campaign list (#143).
@riverpod
class CampaignListNotifier extends _$CampaignListNotifier {
  @override
  Future<Paged<Campaign>> build() async =>
      Paged.first(await ref.watch(campaignRepositoryProvider).list());

  Future<void> refresh() async {
    ref
      ..invalidateSelf()
      ..invalidate(planProvider);
    await future;
  }
}

@riverpod
Future<Campaign> campaign(Ref ref, String id) =>
    ref.watch(campaignRepositoryProvider).get(id);

/// The workspace's SMS credit balance, from the plan.
@riverpod
Future<int> smsCredits(Ref ref) async =>
    (await ref.watch(planProvider.future))?.smsCredits ?? 0;

@riverpod
Future<List<Audience>> campaignAudiences(Ref ref, CampaignChannel channel) =>
    ref.watch(campaignRepositoryProvider).audiences(channel);

@riverpod
Future<List<MessageTemplate>> smsTemplates(Ref ref) =>
    ref.watch(messageTemplatesProvider(CampaignChannel.sms.wire).future);

/// Cancelling a scheduled campaign; callers show the outcome.
@Riverpod(keepAlive: true)
class CampaignActions extends _$CampaignActions {
  @override
  void build() {}

  Future<Campaign> cancel(String id) async {
    final campaign = await ref.read(campaignRepositoryProvider).cancel(id);
    if (ref.mounted) {
      ref
        ..invalidate(campaignProvider(id))
        ..invalidate(campaignListProvider)
        ..invalidate(planProvider);
    }
    return campaign;
  }
}

/// Sending or scheduling a bulk SMS (#144) or email (#145).
@riverpod
class CampaignSubmit extends _$CampaignSubmit {
  @override
  AsyncValue<Campaign?> build() => const AsyncData(null);

  Future<void> submit(CampaignInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(campaignRepositoryProvider).send(input),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) {
      ref
        ..invalidate(campaignListProvider)
        ..invalidate(planProvider);
    }
  }
}
