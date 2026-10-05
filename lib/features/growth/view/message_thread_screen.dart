import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/features/growth/view/widget/inbox_actions.dart';
import 'package:salesroot/features/growth/view/widget/thread_composer.dart';
import 'package:salesroot/features/growth/view/widget/thread_parts.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #142 A conversation with a customer.
class MessageThreadScreen extends ConsumerStatefulWidget {
  const MessageThreadScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<MessageThreadScreen> createState() =>
      _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = ref.watch(conversationProvider(widget.id));
    final thread = value.value;
    final canReply = ref.watch(moduleAccessProvider(AppModule.inbox)).canAdd;
    return SrScaffold(
      appBar: SrAppBar(
        title: thread?.name ?? l10n.growthMessagesTitle,
        subtitle: thread == null ? null : _subtitle(thread),
        actions: [
          const GrowthLanguageAction(),
          if (thread != null)
            SrIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: l10n.commonMore,
              onTap: () => _more(thread),
            ),
        ],
      ),
      body: SrAsyncView(
        value: value,
        onRetry: () => ref.invalidate(conversationProvider(widget.id)),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 5, cards: true),
        data: (context, thread) => ThreadMessages(
          thread: thread,
          canReply: canReply,
          onUseSuggestion: (text) => _composer.text = text,
        ),
      ),
      footer: thread == null
          ? null
          : canReply && thread.open
          ? ThreadComposer(thread: thread, controller: _composer)
          : SrNote(
              message: thread.open
                  ? l10n.growthMessagesReadOnly
                  : l10n.growthInboxClosedNote,
              tone: SrNoteTone.neutral,
            ),
    );
  }

  String _subtitle(Conversation thread) {
    final l10n = context.l10n;
    final who = thread.isMine(ref.watch(myMembershipIdProvider))
        ? l10n.growthMessagesYouShort
        : thread.assignedTo;
    return [
      thread.channel.label(l10n),
      if (who != null) l10n.growthMessagesAssigned(who),
    ].join(' · ');
  }

  Future<void> _more(Conversation thread) async {
    final l10n = context.l10n;
    final canEdit =
        thread.open && ref.read(moduleAccessProvider(AppModule.inbox)).canEdit;
    final phone = thread.phone;
    final action = await showSrSheet<_MoreAction>(
      context: context,
      builder: (context) => SrSheet(
        title: thread.name,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phone != null)
              SrListRow(
                leading: const Icon(Icons.call_outlined),
                title: l10n.commonCall,
                onTap: () => Navigator.of(context).pop(_MoreAction.call),
              ),
            if (canEdit && thread.isUnassigned)
              SrListRow(
                leading: const Icon(Icons.pan_tool_alt_outlined),
                title: l10n.growthInboxTake,
                onTap: () => Navigator.of(context).pop(_MoreAction.take),
              ),
            if (canEdit)
              SrListRow(
                leading: const Icon(Icons.person_add_alt_rounded),
                title: l10n.growthInboxAssign,
                onTap: () => Navigator.of(context).pop(_MoreAction.assign),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _MoreAction.call:
        if (phone != null) await launchUrl(Uri(scheme: 'tel', path: phone));
      case _MoreAction.take:
        await _take(thread);
      case _MoreAction.assign:
        await assignConversation(context, ref, thread);
    }
  }

  Future<void> _take(Conversation thread) async {
    final done = await runGrowthAction(
      context,
      ref.read(inboxActionsProvider.notifier).take(thread.id),
    );
    if (done == null || !mounted) return;
    showSrSuccess(context, context.l10n.growthInboxTaken);
  }
}

enum _MoreAction { call, take, assign }
