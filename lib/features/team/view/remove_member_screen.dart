import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/widget/lookup_field.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #71 `removemember`: hand the member's work to someone, then remove them.
class RemoveMemberScreen extends ConsumerWidget {
  const RemoveMemberScreen({super.key, required this.memberId});

  final String memberId;

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
  late String? _targetId = widget.member.managerId;
  bool _missingTarget = false;

  Member get _member => widget.member;

  void _submit() {
    final targetId = _targetId;
    if (targetId == null) {
      setState(() => _missingTarget = true);
      return;
    }
    ref
        .read(memberRemovalProvider(_member.id).notifier)
        .remove(successorId: targetId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final name = context.name(_member.name);
    final openLeads = _member.stats?.openLeads;
    final removal = ref.watch(memberRemovalProvider(_member.id));
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
              serverError.fieldError('successorId') != null
        ? l10n.teamManagerInvalid
        : null;
    return Column(
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
                message: openLeads == null
                    ? l10n.teamRemoveNote(name)
                    : l10n.teamRemoveNoteLeads(name, fmt.number(openLeads)),
              ),
              const SizedBox(height: 14),
              LookupField<Member>(
                title: l10n.teamReassignTo,
                label: l10n.teamReassignTo,
                placeholder: l10n.teamReassignToHint,
                withAvatar: true,
                error: targetError,
                selected: _targetId,
                idOf: (m) => m.id,
                labelOf: (m) => context.name(m.name),
                subtitleOf: context.memberSubtitle,
                onChanged: (m) => setState(() {
                  _targetId = m.id;
                  _missingTarget = false;
                }),
                options: [
                  for (final m in directory)
                    if (m.isActive && m.id != _member.id) m,
                ],
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
    );
  }
}
