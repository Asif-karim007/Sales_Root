import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/growth/data/api_messages_repository.dart';
import 'package:salesroot/features/growth/data/messages_repository.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';

part 'messages_providers.g.dart';

@Riverpod(keepAlive: true)
MessagesRepository messagesRepository(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiMessagesRepository(ref.watch(growthApiProvider));
}

@riverpod
class ThreadBoxNotifier extends _$ThreadBoxNotifier {
  @override
  ConversationBox build() => ConversationBox.all;

  void set(ConversationBox box) => state = box;
}

/// The unified inbox (#141): every conversation, latest first.
@riverpod
class ThreadListNotifier extends _$ThreadListNotifier {
  @override
  Future<Paged<Conversation>> build() async {
    final box = ref.watch(threadBoxProvider);
    return Paged.first(await ref.watch(leadInboxRepositoryProvider).list(box));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(leadInboxRepositoryProvider)
          .list(ref.read(threadBoxProvider), page: current.page + 1);
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

/// The Page and number the inbox is connected to, e.g. "Rahim Traders ·
/// +8801711…"; null when nothing is connected or the list is out of reach.
@riverpod
String? messagingAccount(Ref ref) {
  final integrations = ref.watch(integrationsProvider).value ?? const [];
  final names = [
    for (final provider in const [
      IntegrationProvider.meta,
      IntegrationProvider.whatsapp,
    ])
      ?integrations
          .where((i) => i.provider == provider)
          .firstOrNull
          ?.displayName,
  ];
  return names.isEmpty ? null : names.join(' · ');
}

/// Templates for one channel, e.g. `whatsapp` or `sms`.
@riverpod
Future<List<MessageTemplate>> messageTemplates(Ref ref, String channel) =>
    ref.watch(messagesRepositoryProvider).templates(channel: channel);

/// An AI reply for a conversation tied to a lead or customer; null when it
/// is with someone the CRM doesn't know yet.
@riverpod
Future<String?> replyDraft(Ref ref, String conversationId) async {
  final repository = ref.watch(messagesRepositoryProvider);
  final conversation = await ref.watch(
    conversationProvider(conversationId).future,
  );
  final leadId = conversation.leadId;
  final companyId = conversation.companyId;
  if (leadId == null && companyId == null) return null;
  final text = await repository.draft(
    DraftAsk(
      purpose: DraftAsk.followUp,
      leadId: leadId,
      companyId: leadId == null ? companyId : null,
    ),
  );
  return text.trim().isEmpty ? null : text.trim();
}
