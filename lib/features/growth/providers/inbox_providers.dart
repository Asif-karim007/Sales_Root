import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/growth/data/api_lead_inbox_repository.dart';
import 'package:salesroot/features/growth/data/lead_inbox_repository.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/features/growth/providers/sources_providers.dart';

part 'inbox_providers.g.dart';

@Riverpod(keepAlive: true)
LeadInboxRepository leadInboxRepository(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiLeadInboxRepository(ref.watch(growthApiProvider));
}

/// The signed-in member's membership id, to tell their conversations apart.
@riverpod
String? myMembershipId(Ref ref) =>
    ref.watch(currentWorkspaceProvider.select((w) => w?.membershipId));

@riverpod
class InboxBoxNotifier extends _$InboxBoxNotifier {
  @override
  ConversationBox build() => ConversationBox.all;

  void set(ConversationBox box) => state = box;
}

/// The new-leads inbox (#136): open conversations, newest first.
@riverpod
class InboxListNotifier extends _$InboxListNotifier {
  @override
  Future<Paged<Conversation>> build() async {
    final box = ref.watch(inboxBoxProvider);
    final page = await ref
        .watch(leadInboxRepositoryProvider)
        .list(box, openOnly: true);
    return Paged.first(page);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(leadInboxRepositoryProvider)
          .list(
            ref.read(inboxBoxProvider),
            openOnly: true,
            page: current.page + 1,
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

/// One conversation with its messages.
@riverpod
Future<Conversation> conversation(Ref ref, String id) =>
    ref.watch(leadInboxRepositoryProvider).get(id);

@riverpod
Future<List<GrowthMember>> inboxMembers(Ref ref) =>
    ref.watch(leadInboxRepositoryProvider).members();

/// Take, assign, close and reply, from the lists or a conversation;
/// callers show the outcome.
@Riverpod(keepAlive: true)
class InboxActions extends _$InboxActions {
  @override
  void build() {}

  Future<Conversation> take(String id) =>
      _change(id, () => ref.read(leadInboxRepositoryProvider).take(id));

  Future<Conversation> assign(String id, String membershipId) => _change(
    id,
    () => ref.read(leadInboxRepositoryProvider).assign(id, membershipId),
  );

  Future<Conversation> close(String id) =>
      _change(id, () => ref.read(leadInboxRepositoryProvider).close(id));

  Future<Conversation> reply(String id, ReplyInput input) =>
      _change(id, () => ref.read(leadInboxRepositoryProvider).reply(id, input));

  Future<Conversation> _change(
    String id,
    Future<Conversation> Function() work,
  ) async {
    final conversation = await work();
    if (ref.mounted) {
      ref
        ..invalidate(inboxListProvider)
        ..invalidate(threadListProvider)
        ..invalidate(conversationProvider(id));
    }
    return conversation;
  }
}

/// Accepting an enquiry (#138): the member takes the conversation, then
/// finishes the lead.
@riverpod
class AcceptLeadSubmit extends _$AcceptLeadSubmit {
  @override
  AsyncValue<Conversation?> build(String id) => const AsyncData(null);

  Future<void> submit() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(inboxActionsProvider.notifier).take(id),
    );
    if (!ref.mounted) return;
    state = result;
  }
}
