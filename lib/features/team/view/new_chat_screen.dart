import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/chat_providers.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/widget/member_row.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #78 `newchat`: a direct chat with one person, or a named group.
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _name = TextEditingController();
  final _search = TextEditingController();
  final Set<int> _picked = {};
  bool _group = true;
  bool _missingName = false;
  bool _missingPeople = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  void _onSearch() => setState(() {});

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    _name.dispose();
    super.dispose();
  }

  void _create() {
    setState(() {
      _missingName = _name.text.trim().isEmpty;
      _missingPeople = _picked.isEmpty;
    });
    if (_missingName || _missingPeople) return;
    ref
        .read(chatOpenerProvider.notifier)
        .group(_name.text.trim(), _picked.toList());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final opener = ref.watch(chatOpenerProvider);
    final directory = ref.watch(teamDirectoryProvider);
    ref.listen(chatOpenerProvider, (_, next) {
      switch (next) {
        case AsyncData(value: final thread?):
          context.pushReplacement(Routes.chatFor(thread.id));
        case AsyncError(:final error):
          showSrError(context, failureText(context, error));
        default:
      }
    });
    final serverName = switch (opener.error) {
      final ApiFailure f when f.fieldError('Name') != null =>
        l10n.commonRequired,
      _ => null,
    };
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: _group ? l10n.teamNewGroup : l10n.teamNewChat,
          actions: const [TeamLanguageToggle()],
        ),
        footer: _group
            ? SrButton(
                label: l10n.teamCreateGroup,
                expand: true,
                loading: opener.isLoading,
                onPressed: opener.isLoading ? null : _create,
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            14,
            SrMetrics.gutter,
            24,
          ),
          children: [
            SrSegmented(
              segments: [
                SrSegment(l10n.teamChatDirect),
                SrSegment(l10n.teamChatGroup),
              ],
              index: _group ? 1 : 0,
              onChanged: (i) => setState(() => _group = i == 1),
            ),
            const SizedBox(height: 14),
            if (_group) ...[
              SrTextField(
                controller: _name,
                label: l10n.teamGroupName,
                hint: l10n.teamGroupNameHint,
                textCapitalization: TextCapitalization.sentences,
                error: _missingName ? l10n.commonRequired : serverName,
                onChanged: (_) {
                  if (_missingName) setState(() => _missingName = false);
                },
              ),
              const SizedBox(height: 14),
            ],
            SrTextField(
              controller: _search,
              hint: l10n.teamSearchMembers,
              prefixIcon: Icons.search_rounded,
            ),
            if (_group && _missingPeople) ...[
              const SizedBox(height: 8),
              SrNote(tone: SrNoteTone.err, message: l10n.teamGroupPickPeople),
            ],
            const SizedBox(height: 12),
            SrAsyncView(
              value: directory,
              onRetry: () => ref.invalidate(teamDirectoryProvider),
              loading: (_) => const SrSkeletonList(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
              ),
              data: (context, members) => _people(context, members),
            ),
          ],
        ),
      ),
    );
  }

  Widget _people(BuildContext context, List<Member> members) {
    final query = _search.text.trim().toLowerCase();
    final shown = [
      for (final m in members)
        if (m.isActive &&
            !m.isMe &&
            (query.isEmpty ||
                m.name.en.toLowerCase().contains(query) ||
                m.name.bn.contains(query)))
          m,
    ];
    if (shown.isEmpty) {
      return SrEmptyState(
        icon: Icons.search_off_rounded,
        title: context.l10n.dsSearchEmptyTitle,
      );
    }
    return AbsorbPointer(
      absorbing: ref.watch(chatOpenerProvider).isLoading,
      child: SrRowGroup(
        dividerIndent: 66,
        rows: [
          for (final m in shown)
            MemberRow(
              member: m,
              chevron: !_group,
              trailing: const SizedBox.shrink(),
              leading: _group
                  ? SrCheckbox(
                      value: _picked.contains(m.id),
                      onChanged: (_) => _toggle(m.id),
                    )
                  : null,
              onTap: _group
                  ? () => _toggle(m.id)
                  : () => ref.read(chatOpenerProvider.notifier).direct(m.id),
            ),
        ],
      ),
    );
  }

  void _toggle(int id) => setState(() {
    if (!_picked.remove(id)) _picked.add(id);
    _missingPeople = false;
  });
}
