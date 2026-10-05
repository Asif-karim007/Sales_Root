import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/providers/inbox_providers.dart';
import 'package:salesroot/features/growth/view/widget/accept_lead_sheet.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/features/growth/view/widget/inbox_actions.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #137 One enquiry; with [openAccept] (#138) the accept sheet opens as soon
/// as it loads.
class NewLeadScreen extends ConsumerStatefulWidget {
  const NewLeadScreen({super.key, required this.id, this.openAccept = false});

  final String id;
  final bool openAccept;

  @override
  ConsumerState<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends ConsumerState<NewLeadScreen> {
  bool _acceptShown = false;

  @override
  void initState() {
    super.initState();
    if (!widget.openAccept) return;
    ref.listenManual(conversationProvider(widget.id), (_, next) {
      final conversation = next.value;
      if (_acceptShown || conversation == null || !conversation.open) return;
      _acceptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAcceptLeadSheet(context, conversation);
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = ref.watch(conversationProvider(widget.id));
    final conversation = value.value;
    final access = ref.watch(moduleAccessProvider(AppModule.inbox));
    final canAct = conversation != null && conversation.open && access.canEdit;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthInboxLeadTitle,
        actions: [
          const GrowthLanguageAction(),
          if (canAct)
            SrIconButton(
              icon: Icons.person_add_alt_rounded,
              tooltip: l10n.growthInboxAssign,
              onTap: () => assignConversation(context, ref, conversation),
            ),
        ],
      ),
      body: SrAsyncView(
        value: value,
        onRetry: () => ref.invalidate(conversationProvider(widget.id)),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 4, cards: true),
        data: (context, conversation) => _Details(conversation: conversation),
      ),
      footer: canAct
          ? Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l10n.growthInboxReject,
                    variant: SrButtonVariant.danger,
                    onPressed: () async {
                      final rejected = await rejectConversation(
                        context,
                        ref,
                        conversation,
                      );
                      if (rejected && context.mounted && context.canPop()) {
                        context.pop();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l10n.growthInboxAccept,
                    onPressed: () => showAcceptLeadSheet(context, conversation),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final linked = _linkedNote(context, conversation);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        _Header(conversation: conversation),
        const SizedBox(height: 12),
        _Facts(conversation: conversation),
        const SizedBox(height: 12),
        _StatusNote(conversation: conversation),
        if (linked != null) ...[const SizedBox(height: 12), linked],
        const SizedBox(height: 12),
        _ContactButtons(conversation: conversation),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final phone = conversation.phone;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SrAvatar(
            name: conversation.name,
            tone: SrAvatarTone.accent,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.name,
                  style: AppText.rowTitle(c.ink, size: 16),
                ),
                if (phone != null)
                  Text(
                    growthPhone(context, phone),
                    style: AppText.meta(c.ink2),
                  ),
              ],
            ),
          ),
          SrTag(conversation.channel.label(l10n), tone: SrTone.accent),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final received = conversation.createdAt;
    final last = conversation.lastAt;
    return GrowthInfoCard(
      lines: [
        if (conversation.lastMessage case final message?)
          (l10n.growthInboxLastMessage, message),
        if (received != null) (l10n.growthInboxReceived, fmt.dayTime(received)),
        if (last != null && last != received)
          (l10n.growthInboxLastActivity, fmt.relative(last)),
        (l10n.growthInboxSource, conversation.channel.label(l10n)),
      ],
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!conversation.open) {
      return SrNote(
        tone: SrNoteTone.neutral,
        icon: Icons.block_rounded,
        message: l10n.growthInboxClosedNote,
      );
    }
    final assignee = conversation.assignedTo;
    if (conversation.isUnassigned || assignee == null) {
      return SrNote(
        icon: Icons.timer_outlined,
        message: l10n.growthInboxNotTaken,
      );
    }
    return SrNote(
      icon: Icons.person_outline_rounded,
      message: l10n.growthInboxAssignedTo(assignee),
    );
  }
}

/// The lead or customer this number already belongs to, if any.
Widget? _linkedNote(BuildContext context, Conversation conversation) {
  final l10n = context.l10n;
  final leadId = conversation.leadId;
  final companyId = conversation.companyId;
  final (title, route) = leadId != null
      ? (l10n.growthInboxDuplicateLead, Routes.leadFor(leadId))
      : companyId != null
      ? (l10n.growthInboxDuplicateCustomer, Routes.customerFor(companyId))
      : (null, null);
  if (title == null || route == null) return null;
  return SrNote(
    tone: SrNoteTone.gold,
    icon: Icons.content_copy_rounded,
    title: title,
    message: conversation.name,
    action: SrButton(
      label: l10n.growthInboxOpen,
      size: SrButtonSize.sm,
      variant: SrButtonVariant.secondary,
      onPressed: () => context.push(route),
    ),
  );
}

class _ContactButtons extends StatelessWidget {
  const _ContactButtons({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phone = conversation.phone;
    return Row(
      children: [
        if (phone != null) ...[
          Expanded(
            child: SrButton(
              label: l10n.commonCall,
              icon: Icons.call_outlined,
              size: SrButtonSize.sm,
              variant: SrButtonVariant.secondary,
              onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: SrButton(
            label: conversation.channel.label(l10n),
            icon: Icons.chat_rounded,
            size: SrButtonSize.sm,
            variant: SrButtonVariant.secondary,
            onPressed: () =>
                context.push(Routes.messageThreadFor(conversation.id)),
          ),
        ),
      ],
    );
  }
}
