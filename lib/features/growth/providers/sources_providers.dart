import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/growth/data/api_lead_sources_repository.dart';
import 'package:salesroot/features/growth/data/growth_api.dart';
import 'package:salesroot/features/growth/data/lead_sources_repository.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';

part 'sources_providers.g.dart';

@Riverpod(keepAlive: true)
GrowthApi growthApi(Ref ref) => GrowthApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
LeadSourcesRepository leadSourcesRepository(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiLeadSourcesRepository(ref.watch(growthApiProvider));
}

@riverpod
Future<List<Integration>> integrations(Ref ref) =>
    ref.watch(leadSourcesRepositoryProvider).integrations();

/// Every channel (#134), connected or not.
@riverpod
Future<List<LeadChannel>> leadChannels(Ref ref) async {
  final [integrations, forms] = await Future.wait<List<Object>>([
    ref.watch(integrationsProvider.future),
    ref.watch(leadSourcesRepositoryProvider).forms(),
  ]);
  return LeadChannel.from(
    integrations.cast<Integration>(),
    forms.cast<LeadForm>(),
  );
}

/// The connected Meta Page, or null (#135).
@riverpod
Future<Integration?> facebookPage(Ref ref) async {
  final integrations = await ref.watch(integrationsProvider.future);
  return integrations
      .where((i) => i.provider == IntegrationProvider.meta)
      .firstOrNull;
}

/// Connect, disconnect and switch forms on or off; callers show the outcome.
@Riverpod(keepAlive: true)
class ChannelActions extends _$ChannelActions {
  @override
  void build() {}

  Future<Integration> connectWhatsApp(WhatsAppConnectInput input) async {
    final integration = await ref
        .read(leadSourcesRepositoryProvider)
        .connectWhatsApp(input);
    if (ref.mounted) ref.invalidate(integrationsProvider);
    return integration;
  }

  Future<void> disconnect(String integrationId) async {
    await ref.read(leadSourcesRepositoryProvider).disconnect(integrationId);
    if (ref.mounted) ref.invalidate(integrationsProvider);
  }

  /// Turns [form] on or off, or makes an enquiry form called [name] when
  /// there is none yet.
  Future<LeadForm> setForm(
    LeadForm? form, {
    required bool active,
    required String name,
  }) async {
    final repository = ref.read(leadSourcesRepositoryProvider);
    final saved = form == null
        ? await repository.createForm(
            LeadFormInput(name: name, fields: LeadFormInput.enquiryFields),
          )
        : await repository.updateForm(
            form.id,
            LeadFormInput(name: form.name, isActive: active),
          );
    if (ref.mounted) ref.invalidate(leadChannelsProvider);
    return saved;
  }
}
