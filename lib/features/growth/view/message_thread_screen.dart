import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';
import 'package:salesroot/features/growth/providers/messages_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/features/growth/view/widget/inbox_actions.dart';
import 'package:salesroot/features/growth/view/widget/thread_composer.dart';
import 'package:salesroot/features/growth/view/widget/thread_parts.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #142 A conversation with a customer. Messages stream in; the customer
/// answers after a while.
class MessageThreadScreen extends ConsumerStatefulWidget {
  const MessageThreadScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<MessageThreadScreen> createState() =>
      _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  final _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(threadMessagesProvider(widget.id), (_, next) {
      final last = next.value?.lastOrNull;
      if (last == null || last.mine) return;
      ref.read(messageActionsProvider.notifier).markRead(widget.id).ignore();
      ref.invalidate(messageThreadProvider(widget.id));
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = ref.watch(messageThreadProvider(widget.id));
    final thread = value.value;
    final canReply = ref.watch(moduleAccessProvider(AppModule.inbox)).canAdd;
    return SrScaffold(
      appBar: SrAppBar(
        title: thread?.name ?? l10n.growthMessagesTitle,
        subtitle: thread == null ? null : _subtitle(context, thread),
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
        onRetry: () => ref.invalidate(messageThreadProvider(widget.id)),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 5, cards: true),
        data: (context, thread) => GrowthClock(
          every: const Duration(minutes: 1),
          builder: (context) => ThreadMessages(
            thread: thread,
            canReply: canReply,
            onUseSuggestion: (text) => _composer.text = text,
          ),
        ),
      ),
      footer: thread == null
          ? null
          : canReply
          ? ThreadComposer(thread: thread, controller: _composer)
          : SrNote(
              message: l10n.growthMessagesReadOnly,
              tone: SrNoteTone.neutral,
            ),
    );
  }

  String _subtitle(BuildContext context, MessageThread thread) {
    final l10n = context.l10n;
    final assignee = thread.assignedTo;
    final who = thread.assignedToMe
        ? l10n.growthMessagesYouShort
        : assignee?.of(context.fmt.isBangla);
    return [
      thread.channel.label(l10n),
      if (who != null) l10n.growthMessagesAssigned(who),
    ].join(' · ');
  }

  Future<void> _more(MessageThread thread) async {
    final l10n = context.l10n;
    final canEdit = ref.read(moduleAccessProvider(AppModule.inbox)).canEdit;
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
      case _MoreAction.assign:
        await _assign(thread);
    }
  }

  Future<void> _assign(MessageThread thread) async {
    final l10n = context.l10n;
    final member = await pickGrowthMember(
      context,
      ref,
      title: l10n.growthInboxAssignTo,
      selected: thread.assignedToId,
    );
    if (member == null || !mounted) return;
    final done = await runGrowthTask(
      context,
      ref.read(messageActionsProvider.notifier).assign(thread.id, member.id),
    );
    if (!done || !mounted) return;
    showSrSuccess(
      context,
      l10n.growthInboxAssigned(member.nameOf(context.fmt.isBangla)),
    );
  }
}

enum _MoreAction { call, assign }
