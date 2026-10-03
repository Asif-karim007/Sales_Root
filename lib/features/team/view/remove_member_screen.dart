import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/widget/info_card.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #71 `removemember`: hand the member's work to someone, then remove them.
class RemoveMemberScreen extends ConsumerWidget {
  const RemoveMemberScreen({super.key, required this.memberId});

  final int memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberProvider(memberId));
    return SrScaffold(
      appBar: SrAppBar(
        title: context.l10n.teamRemoveTitle,
        actions: const [TeamLanguageToggle()],
      ),
      body: SrAsyncView(
        value: member,
        onRetry: () => ref.invalidate(memberProvider(memberId)),
        data: (context, member) => _RemoveForm(member: member),
      ),
    );
  }
}

class _RemoveForm extends ConsumerStatefulWidget {
  const _RemoveForm({required this.member});

  final Member member;

  @override
  ConsumerState<_RemoveForm> createState() => _RemoveFormState();
}

class _RemoveFormState extends ConsumerState<_RemoveForm> {
  final _reason = TextEditingController();
  late int? _targetId = widget.member.managerId;
  bool _leads = true;
  bool _tasks = true;
  bool _visits = true;
  bool _chat = true;
  bool _contacts = false;
  bool _missingTarget = false;

  Member get _member => widget.member;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (_targetId == null) {
      setState(() => _missingTarget = true);
      return;
    }
    ref
        .read(memberRemovalProvider(_member.id).notifier)
        .remove(
          RemovalInput(
            reassignToId: _targetId,
            reassignLeads: _leads,
            reassignTasks: _tasks,
            reassignVisits: _visits,
            keepChatHistory: _chat,
            keepContactsCopy: _contacts,
            reason: _reason.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final name = context.name(_member.name);
    final stats = _member.stats ?? const MemberStats();
    final removal = ref.watch(memberRemovalProvider(_member.id));
    final hasFieldForce =
        ref.watch(planProvider).value?.has(AddOn.fieldForce) ?? false;
    final directory = ref.watch(teamDirectoryProvider).value ?? const [];
    ref.listen(memberRemovalProvider(_member.id), (_, next) {
      switch (next) {
        case AsyncData(value: true):
          context.go(Routes.team);
          showSrSuccess(context, l10n.teamRemoved(name));
        case AsyncError(:final error):
          showSrError(context, failureText(context, error));
        default:
      }
    });
    final serverError = removal.error;
    final targetError = _missingTarget
        ? l10n.commonRequired
        : serverError is ApiFailure &&
              serverError.fieldError('ReassignToId') != null
        ? l10n.teamManagerInvalid
        : null;
    return SrKeyboardDismiss(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SrMetrics.gutter,
                14,
                SrMetrics.gutter,
                24,
              ),
              children: [
                SrNote(
                  tone: SrNoteTone.err,
                  message: l10n.teamRemoveNote(
                    name,
                    fmt.number(stats.openLeads),
                    fmt.number(stats.openTasks),
                  ),
                ),
                const SizedBox(height: 14),
                SrLookupPicker(
                  title: l10n.teamReassignTo,
                  label: l10n.teamReassignTo,
                  placeholder: l10n.teamReassignToHint,
                  withAvatar: true,
                  error: targetError,
                  selected: _targetId,
                  onChanged: (id) => setState(() {
                    _targetId = id;
                    _missingTarget = false;
                  }),
                  options: [
                    for (final m in directory)
                      if (m.isActive && m.id != _member.id)
                        SrLookupOption(
                          id: m.id,
                          name: context.name(m.name),
                          subtitle: context.memberSubtitle(m),
                        ),
                  ],
                ),
                const SizedBox(height: 14),
                SwitchCard(
                  rows: [
                    SwitchRow(
                      title: l10n.teamRemoveLeads(fmt.number(stats.openLeads)),
                      value: _leads,
                      onChanged: (v) => setState(() => _leads = v),
                    ),
                    SwitchRow(
                      title: l10n.teamRemoveTasks(fmt.number(stats.openTasks)),
                      value: _tasks,
                      onChanged: (v) => setState(() => _tasks = v),
                    ),
                    if (hasFieldForce)
                      SwitchRow(
                        title: l10n.teamRemoveVisits(
                          fmt.number(stats.todayVisits),
                        ),
                        value: _visits,
                        onChanged: (v) => setState(() => _visits = v),
                      ),
                    SwitchRow(
                      title: l10n.teamKeepChatHistory,
                      value: _chat,
                      onChanged: (v) => setState(() => _chat = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchCard(
                  tone: SrCardTone.gold,
                  rows: [
                    SwitchRow(
                      title: l10n.teamKeepContacts,
                      subtitle: l10n.teamKeepContactsAbout,
                      value: _contacts,
                      onChanged: (v) => setState(() => _contacts = v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SrTextField(
                  controller: _reason,
                  label: l10n.teamRemoveReason,
                  optional: true,
                  hint: l10n.teamRemoveReasonHint,
                ),
              ],
            ),
          ),
          SrFooter(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SrButton(
                    label: l10n.commonCancel,
                    variant: SrButtonVariant.secondary,
                    expand: true,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: SrButton(
                    label: l10n.teamReassignAndRemove,
                    variant: SrButtonVariant.danger,
                    expand: true,
                    loading: removal.isLoading,
                    onPressed: removal.isLoading ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
