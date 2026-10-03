import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/view/widget/chat_labels.dart';
import 'package:salesroot/features/team/view/widget/paged_list.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #73 `chatlist`: groups, direct chats and lead threads. With [leadId] it
/// opens (or starts) that lead's discussion in place of itself.
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key, this.leadId});

  final int? leadId;

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(chatSearchProvider);
    _openLead();
  }

  @override
  void didUpdateWidget(ChatListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leadId != oldWidget.leadId) _openLead();
  }

  void _openLead() {
    final leadId = widget.leadId;
    if (leadId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(chatOpenerProvider.notifier).lead(leadId);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => ref.read(chatSearchProvider.notifier).set(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chat = ref.watch(moduleAccessProvider(AppModule.chat));
    final oversight = ref.watch(moduleAccessProvider(AppModule.chatOversight));
    final leadId = widget.leadId;
    if (leadId != null) {
      ref.listen(chatOpenerProvider, (_, next) {
        if (next case AsyncData(value: final thread?)) {
          context.replace(Routes.chatFor(thread.id));
        }
      });
    }
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.teamChatTitle,
        actions: [
          const TeamLanguageToggle(),
          if (oversight.canView)
            SrIconButton(
              icon: Icons.visibility_outlined,
              tooltip: l10n.teamOversightTitle,
              onTap: () => context.push(Routes.chatOversight),
            ),
          if (chat.canAdd)
            SrIconButton(
              icon: Icons.edit_square,
              tooltip: l10n.teamNewChat,
              onTap: () => context.push(Routes.chatNew),
            ),
        ],
      ),
      body: leadId == null
          ? _list(context, canAdd: chat.canAdd)
          : switch (ref.watch(chatOpenerProvider)) {
              AsyncError(:final error) => Center(
                child: SrErrorState(
                  error: error,
                  onRetry: () =>
                      ref.read(chatOpenerProvider.notifier).lead(leadId),
                ),
              ),
              _ => const SrSkeletonList(),
            },
    );
  }

  Widget _list(BuildContext context, {required bool canAdd}) {
    final l10n = context.l10n;
    final threads = ref.watch(chatListProvider);
    final notifier = ref.read(chatListProvider.notifier);
    final searching = ref.watch(chatSearchProvider).isNotEmpty;
    final header = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
        child: SrTextField(
          controller: _search,
          hint: l10n.teamChatSearch,
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: _onSearch,
        ),
      ),
    ];
    final empty = searching
        ? SrEmptyState(
            icon: Icons.search_off_rounded,
            title: l10n.dsSearchEmptyTitle,
            message: l10n.dsSearchEmptyBody,
          )
        : SrEmptyState(
            icon: Icons.forum_outlined,
            title: l10n.teamChatEmptyTitle,
            message: l10n.teamChatEmptyBody,
            actionLabel: canAdd ? l10n.teamNewChat : null,
            onAction: canAdd ? () => context.push(Routes.chatNew) : null,
          );
    return threads.when(
      data: (paged) => PagedCardList<ChatThread>(
        paged: paged,
        header: header,
        empty: empty,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        itemBuilder: (context, thread) => ChatThreadRow(thread: thread),
      ),
      loading: () => ListView(
        padding: const EdgeInsets.only(top: 14),
        children: [...header, const SrSkeletonList(shrinkWrap: true)],
      ),
      error: (error, _) => ListView(
        padding: const EdgeInsets.only(top: 14),
        children: [
          ...header,
          SrErrorState(error: error, onRetry: notifier.refresh),
        ],
      ),
    );
  }
}

/// A thread in a list: avatar, title, last message, time and unread count.
class ChatThreadRow extends StatelessWidget {
  const ChatThreadRow({super.key, required this.thread, this.subtitle});

  final ChatThread thread;

  /// Replaces the last-message preview.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final unread = thread.unreadCount;
    return SrListRow(
      title: context.threadTitle(thread),
      subtitle: subtitle ?? context.previewLine(thread),
      leading: context.threadAvatar(thread),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            context.chatTime(thread.lastActivityAt),
            style: AppText.meta(unread > 0 ? c.accent : c.ink3, size: 11.5),
          ),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            SrTag(context.fmt.number(unread), tone: SrTone.accent),
          ],
        ],
      ),
      onTap: () => context.push(Routes.chatFor(thread.id)),
    );
  }
}
