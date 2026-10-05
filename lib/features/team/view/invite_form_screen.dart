import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/widget/lookup_field.dart';
import 'package:salesroot/features/team/view/widget/team_labels.dart';
import 'package:salesroot/features/team/view/widget/team_language_toggle.dart';
import 'package:salesroot/features/team/view/widget/team_sheets.dart';
import 'package:salesroot/features/team/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #65 `inviteform`: who to invite, their role, manager and level.
class InviteFormScreen extends ConsumerStatefulWidget {
  const InviteFormScreen({super.key});

  @override
  ConsumerState<InviteFormScreen> createState() => _InviteFormScreenState();
}

class _InviteFormScreenState extends ConsumerState<InviteFormScreen> {
  final _phone = TextEditingController();
  MemberRole _role = MemberRole.executive;
  String? _managerId;
  ExperienceLevel _level = ExperienceLevel.easy;
  bool _missingPhone = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Member? _suggested(List<Member> managers) {
    if (managers.isEmpty) return null;
    return managers.firstWhere(
      (m) => m.isMe || m.isTeamLead,
      orElse: () => managers.first,
    );
  }

  void _submit({required bool levelLocked, required String? managerId}) {
    if (_phone.text.trim().isEmpty) {
      setState(() => _missingPhone = true);
      return;
    }
    setState(() => _missingPhone = false);
    ref
        .read(inviteSenderProvider.notifier)
        .send(
          InviteInput(
            phone: _phone.text,
            role: _role,
            managerId: managerId,
            level: levelLocked ? null : _level,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sender = ref.watch(inviteSenderProvider);
    final plan = ref.watch(planProvider).value;
    final locked = ref.watch(experienceLevelLockedProvider);
    final directory = ref.watch(teamDirectoryProvider);
    final managers = managersOf(directory.value ?? const []);
    final managerId = _managerId ?? _suggested(managers)?.id;
    ref.listen(inviteSenderProvider, (_, next) {
      switch (next) {
        case AsyncData(value: final invite?):
          context.pushReplacement('${Routes.teamInviteSent}?id=${invite.id}');
        case AsyncError(error: final ApiFailure failure) when failure.isQuota:
          showNoSeatSheet(context);
        case AsyncError(:final error)
            when _phoneError(error) == null && _managerError(error) == null:
          showSrError(context, failureText(context, error));
        default:
      }
    });
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.teamInviteTitle,
          actions: const [TeamLanguageToggle()],
        ),
        footer: SrButton(
          label: l10n.teamInviteSend,
          expand: true,
          loading: sender.isLoading,
          onPressed: sender.isLoading
              ? null
              : () => _submit(levelLocked: locked, managerId: managerId),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            14,
            SrMetrics.gutter,
            24,
          ),
          children: [
            if (plan != null) ...[
              SrNote(
                message: l10n.teamSeatsFree(
                  context.fmt.number(plan.usersUsed),
                  context.fmt.number(plan.users),
                  context.fmt.number(plan.users - plan.usersUsed),
                ),
              ),
              const SizedBox(height: 14),
            ],
            SrTextField(
              controller: _phone,
              label: l10n.teamInviteByPhone,
              hint: l10n.teamInvitePhoneHint,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              error: _missingPhone
                  ? l10n.commonRequired
                  : _phoneError(sender.error),
            ),
            const SizedBox(height: 14),
            SrDropdownField(
              label: l10n.teamRole,
              value: context.roleLabel(_role),
              onTap: () async {
                final role = await showRolePickSheet(context, selected: _role);
                if (role != null) setState(() => _role = role);
              },
            ),
            const SizedBox(height: 14),
            _ManagerPicker(
              managers: managers,
              selected: managerId,
              failed: directory.hasError,
              error: _managerError(sender.error),
              onChanged: (id) => setState(() => _managerId = id),
            ),
            const SizedBox(height: 14),
            _levelField(context, locked),
          ],
        ),
      ),
    );
  }

  Widget _levelField(BuildContext context, bool locked) {
    final l10n = context.l10n;
    final level = ref.watch(experienceLevelProvider);
    if (locked) {
      return SrDropdownField(
        label: l10n.teamLevel,
        value: l10n.teamLevelLocked(context.levelLabel(level)),
        enabled: false,
        trailingIcon: Icons.lock_outline_rounded,
        onTap: null,
      );
    }
    return SrDropdownField(
      label: l10n.teamLevel,
      value: context.levelLabel(_level),
      onTap: () async {
        final picked = await showLevelSheet(context, _level);
        if (picked != null) setState(() => _level = picked);
      },
    );
  }

  String? _phoneError(Object? error) {
    if (error is! ApiFailure) return null;
    if (error.isConflict) return context.l10n.teamInviteDuplicate;
    final message = error.fieldError('phone');
    if (message == null) return null;
    return message.isEmpty ? context.l10n.teamInvitePhoneInvalid : message;
  }

  String? _managerError(Object? error) =>
      error is ApiFailure && error.fieldError('reportsTo') != null
      ? context.l10n.teamManagerInvalid
      : null;
}

/// Picks an experience level.
Future<ExperienceLevel?> showLevelSheet(
  BuildContext context,
  ExperienceLevel current,
) => showSrSheet<ExperienceLevel>(
  context: context,
  builder: (_) => SrOptionSheet<ExperienceLevel>(
    title: context.l10n.teamLevel,
    options: ExperienceLevel.values,
    labelOf: context.levelLabel,
    subtitleOf: (level) => switch (level) {
      ExperienceLevel.easy => context.l10n.teamLevelEasyAbout,
      ExperienceLevel.standard => context.l10n.teamLevelStandardAbout,
      ExperienceLevel.advanced => context.l10n.teamLevelAdvancedAbout,
    },
    isSelected: (level) => level == current,
  ),
);

/// "Reports to": the owner and team leads.
class _ManagerPicker extends StatelessWidget {
  const _ManagerPicker({
    required this.managers,
    required this.selected,
    required this.onChanged,
    this.failed = false,
    this.error,
  });

  final List<Member> managers;
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool failed;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LookupField<Member>(
      title: l10n.teamReportsTo,
      label: l10n.teamReportsTo,
      placeholder: failed ? l10n.errorGeneric : l10n.teamReportsToHint,
      error: error,
      withAvatar: true,
      selected: selected,
      onChanged: (m) => onChanged(m.id),
      options: managers,
      idOf: (m) => m.id,
      labelOf: (m) => l10n.teamNameWithRole(
        context.name(m.name),
        context.roleLabel(m.role),
      ),
      subtitleOf: (m) => m.area,
    );
  }
}

/// The owner and active team leads, the user first when they are one.
List<Member> managersOf(List<Member> members) => [
  for (final m in members)
    if (m.isActive && (m.isOwner || m.isTeamLead)) m,
]..sort((a, b) => (b.isMe ? 1 : 0) - (a.isMe ? 1 : 0));
