import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/team/models/chat.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/widget/chat_labels.dart';
import 'package:salesroot/features/team/view/widget/info_card.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #79 `groupinfo`: who is in a thread, its settings, and leaving it.
class ChatInfoScreen extends ConsumerWidget {
  const ChatInfoScreen({super.key, required this.threadId});

  final int threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final thread = ref.watch(chatThreadProvider(threadId));
    ref.listen(chatThreadEditorProvider(threadId), (_, next) {
      switch (next) {
        case AsyncData(value: ChatEditOutcome.left):
          context.go(Routes.chats);
        case AsyncData(value: ChatEditOutcome.membersAdded):
          showSrSuccess(context, l10n.teamChatMembersAdded);
        case AsyncError(:final error):
          showSrError(context, failureText(context, error));
        default:
      }
    });
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.teamChatInfo,
        actions: const [TeamLanguageToggle()],
      ),
      body: SrAsyncView(
        value: thread,
        onRetry: () => ref.invalidate(chatThreadProvider(threadId)),
        data: (context, thread) => _Info(thread: thread),
      ),
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final team = ref.watch(
      currentWorkspaceProvider.select((w) => w?.kind == WorkspaceKind.team),
    );
    final editor = chatThreadEditorProvider(thread.id);
    final busy = ref.watch(editor).isLoading;
    final created = thread.createdAt;
    final lead = thread.lead;
    final people = thread.participants;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        18,
        SrMetrics.gutter,
        24,
      ),
      children: [
        Center(child: context.threadAvatar(thread, size: 72)),
        const SizedBox(height: 10),
        Text(
          context.threadTitle(thread),
          textAlign: TextAlign.center,
          style: AppText.sectionTitle(c.ink, size: 18),
        ),
        Text(
          [
            l10n.teamChatMembers(context.fmt.number(people.length)),
            if (created != null)
              l10n.teamChatCreated(context.fmt.monthYear(created)),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: AppText.meta(c.ink2, size: 13),
        ),
        if (team) ...[
          const SizedBox(height: 14),
          SrNote(tone: SrNoteTone.gold, message: l10n.teamChatOwnerReadsAll),
        ],
        if (lead != null) ...[
          const SizedBox(height: 14),
          SrRowGroup(
            rows: [
              SrListRow(
                title: lead.title,
                subtitle: context.fmt.moneyCompact(lead.value),
                leading: SrAvatar(name: lead.title, tone: SrAvatarTone.gold),
                chevron: true,
                onTap: () => context.push(Routes.leadFor(lead.id)),
              ),
            ],
          ),
        ],
        if (thread.isParticipant) ...[
          const SizedBox(height: 14),
          SwitchCard(
            rows: [
              SwitchRow(
                title: l10n.teamChatNotifications,
                value: thread.notifications,
                onChanged: busy
                    ? null
                    : (v) =>
                          ref.read(editor.notifier).settings(notifications: v),
              ),
              SwitchRow(
                title: l10n.teamChatAutoDownload,
                value: thread.autoDownload,
                onChanged: busy
                    ? null
                    : (v) =>
                          ref.read(editor.notifier).settings(autoDownload: v),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        SrRowGroup(
          title: l10n.teamChatMembers(context.fmt.number(people.length)),
          seeAllLabel: thread.canAddMembers ? l10n.commonAdd : null,
          onSeeAll: thread.canAddMembers ? () => _add(context, ref) : null,
          dividerIndent: 66,
          rows: [
            for (final person in people)
              SrListRow(
                title: person.isMe
                    ? l10n.teamChatYou
                    : context.name(person.name),
                subtitle: context.roleLabel(person.role),
                leading: SrAvatar(
                  name: context.avatarName(context.name(person.name)),
                ),
                trailing: person.id == thread.adminId
                    ? SrTag(l10n.teamChatAdmin, tone: SrTone.accent)
                    : null,
                onTap: () => context.push(Routes.memberFor(person.id)),
              ),
          ],
        ),
        if (thread.canLeave) ...[
          const SizedBox(height: 18),
          SrButton(
            label: l10n.teamChatLeave,
            variant: SrButtonVariant.danger,
            expand: true,
            loading: busy,
            onPressed: busy ? null : () => _leave(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final directory = await ref.read(teamDirectoryProvider.future);
    if (!context.mounted) return;
    final inside = {for (final p in thread.participants) p.id};
    final picked = await showSrSheet<List<Member>>(
      context: context,
      builder: (context) => SrMultiOptionSheet<Member>(
        title: context.l10n.teamChatAddMembers,
        searchHint: context.l10n.teamSearchMembers,
        withAvatar: true,
        options: [
          for (final m in directory)
            if (m.isActive && !inside.contains(m.id)) m,
        ],
        labelOf: (m) => context.name(m.name),
        subtitleOf: context.memberSubtitle,
        isSelected: (_) => false,
      ),
    );
    if (picked == null || picked.isEmpty) return;
    await ref.read(chatThreadEditorProvider(thread.id).notifier).addMembers([
      for (final m in picked) m.id,
    ]);
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sure = await showSrConfirm(
      context,
      title: l10n.teamChatLeaveTitle(context.threadTitle(thread)),
      message: l10n.teamChatLeaveBody,
      confirmLabel: l10n.teamChatLeave,
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (!sure) return;
    await ref.read(chatThreadEditorProvider(thread.id).notifier).leave();
  }
}
