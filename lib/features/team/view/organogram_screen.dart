import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/member_detail_screen.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #72 `organogram`: who reports to whom, one team lead's branch at a time.
class OrganogramScreen extends ConsumerStatefulWidget {
  const OrganogramScreen({super.key});

  @override
  ConsumerState<OrganogramScreen> createState() => _OrganogramScreenState();
}

class _OrganogramScreenState extends ConsumerState<OrganogramScreen> {
  String? _focusId;
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final directory = ref.watch(teamDirectoryProvider);
    final canEdit = ref.watch(
      moduleAccessProvider(AppModule.team).select((a) => a.canEdit),
    );
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.teamOrganogram,
        actions: [
          const TeamLanguageToggle(),
          if (canEdit)
            SrIconButton(
              icon: _editing ? Icons.check_rounded : Icons.edit_outlined,
              tooltip: _editing ? l10n.commonDone : l10n.commonEdit,
              onTap: () => setState(() => _editing = !_editing),
            ),
        ],
      ),
      body: SrAsyncView(
        value: directory,
        onRetry: () => ref.invalidate(teamDirectoryProvider),
        isEmpty: (members) => members.length < 2,
        empty: (_) => Center(
          child: SrEmptyState(
            icon: Icons.account_tree_outlined,
            title: l10n.teamEmptyTitle,
            message: l10n.teamEmptyBody,
          ),
        ),
        data: (context, members) => _tree(context, members),
      ),
    );
  }

  Widget _tree(BuildContext context, List<Member> all) {
    final l10n = context.l10n;
    final members = all.where((m) => m.isActive).toList();
    final owner = members.where((m) => m.isOwner).firstOrNull;
    List<Member> reportsOf(String id) =>
        members.where((m) => m.managerId == id).toList();
    final heads = [
      ...members.where((m) => m.isTeamLead),
      if (owner != null && reportsOf(owner.id).any((m) => !m.isTeamLead)) owner,
    ];
    final me = members.where((m) => m.isMe).firstOrNull;
    final focus =
        heads.where((h) => h.id == _focusId).firstOrNull ??
        heads
            .where((h) => h.id == me?.managerId || h.id == me?.id)
            .firstOrNull ??
        heads.firstOrNull;
    final branch = focus == null
        ? const <Member>[]
        : reportsOf(focus.id).where((m) => !m.isTeamLead).toList();
    final others = heads.where((h) => h != focus).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        14,
        SrMetrics.gutter,
        24,
      ),
      children: [
        if (owner != null)
          Center(
            child: _Node(
              member: owner,
              tone: SrAvatarTone.dark,
              onTap: () => _open(owner),
            ),
          ),
        if (focus != null && focus != owner) ...[
          const _Connector(),
          Center(
            child: _Node(
              member: focus,
              tone: SrAvatarTone.accent,
              onTap: () => _open(focus),
            ),
          ),
        ],
        if (branch.isNotEmpty) ...[
          const _Connector(),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in branch)
                _Node(member: m, compact: true, onTap: () => _open(m)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        SrNote(
          message: _editing
              ? l10n.teamOrganogramEditing
              : l10n.teamOrganogramNote,
        ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 18),
          SrRowGroup(
            title: l10n.teamOtherLeads,
            dividerIndent: 66,
            rows: [
              for (final head in others)
                SrListRow(
                  title: context.name(head.name),
                  subtitle: [
                    context.roleLabel(head.role),
                    ?head.area,
                    l10n.teamPeople(
                      reportsOf(head.id).length,
                      context.fmt.number(reportsOf(head.id).length),
                    ),
                  ].join(' · '),
                  leading: SrAvatar(
                    name: context.avatarName(context.name(head.name)),
                    tone: SrAvatarTone.accent,
                  ),
                  chevron: true,
                  onTap: () => setState(() => _focusId = head.id),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _open(Member member) async {
    if (!_editing) {
      context.push(Routes.memberFor(member.id));
      return;
    }
    if (member.isOwner) return;
    final result = await changeManager(context, ref, member);
    if (!mounted || result == null) return;
    switch (result) {
      case AsyncError(:final error):
        showSrError(context, failureText(context, error));
      default:
        showSrSuccess(context, context.l10n.teamSaved);
    }
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(width: 1, height: 16, color: SrColors.of(context).line),
    );
  }
}

/// One person in the tree: avatar, name and role in a bordered box.
class _Node extends StatelessWidget {
  const _Node({
    required this.member,
    required this.onTap,
    this.tone = SrAvatarTone.neutral,
    this.compact = false,
  });

  final Member member;
  final VoidCallback onTap;
  final SrAvatarTone tone;

  /// Shows the first name only, for the leaves.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final full = context.name(member.name);
    final name = compact ? full.split(' ').first : full;
    final area = member.area;
    final subtitle = [
      context.roleLabel(member.role),
      if (!compact && member.isTeamLead && area != null) area,
    ].join(' · ');
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SrAvatar(name: context.avatarName(full), size: 30, tone: tone),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: AppText.rowTitle(c.ink, size: 13)),
                  Text(subtitle, style: AppText.meta(c.ink2, size: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
