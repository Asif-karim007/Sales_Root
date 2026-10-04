import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/team/models/invite.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/features/team/providers/team_providers.dart';
import 'package:salesroot/features/team/view/widget/info_card.dart';
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
  final _email = TextEditingController();
  final _name = TextEditingController();
  InviteChannel _channel = InviteChannel.phone;
  WorkspaceRole _role = WorkspaceRole.member;
  int? _managerId;
  ExperienceLevel _level = ExperienceLevel.easy;
  bool _fieldForce = true;
  bool _teamOnly = false;
  bool _missingAddress = false;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Member? _suggested(List<Member> managers) {
    if (managers.isEmpty) return null;
    return managers.firstWhere(
      (m) => m.isMe || m.isTeamLead,
      orElse: () => managers.first,
    );
  }

  void _submit({required bool levelLocked, required int? managerId}) {
    final address = _channel == InviteChannel.phone ? _phone : _email;
    if (address.text.trim().isEmpty) {
      setState(() => _missingAddress = true);
      return;
    }
    setState(() => _missingAddress = false);
    final hasFieldForce =
        ref.read(planProvider).value?.has(AddOn.fieldForce) ?? false;
    ref
        .read(inviteSenderProvider.notifier)
        .send(
          InviteInput(
            channel: _channel,
            phone: _phone.text,
            email: _email.text,
            name: _name.text,
            role: _role,
            managerId: managerId,
            level: levelLocked ? null : _level,
            fieldForce: hasFieldForce && _fieldForce,
            teamOnlyCapture: _teamOnly,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sender = ref.watch(inviteSenderProvider);
    final plan = ref.watch(planProvider).value;
    final locked = ref.watch(experienceLevelLockedProvider);
    final easy = ref.watch(experienceLevelProvider) == ExperienceLevel.easy;
    final directory = ref.watch(teamDirectoryProvider);
    final managers = managersOf(directory.value ?? const []);
    final managerId = _managerId ?? _suggested(managers)?.id;
    ref.listen(inviteSenderProvider, (_, next) {
      switch (next) {
        case AsyncData(value: final invite?):
          context.pushReplacement('${Routes.teamInviteSent}?id=${invite.id}');
        case AsyncError(error: final ApiFailure failure) when failure.isQuota:
          showNoSeatSheet(context);
        case AsyncError(:final error) when _fieldError(error) == null:
          showSrError(context, failureText(context, error));
        default:
      }
    });
    final fieldError = _missingAddress
        ? l10n.commonRequired
        : _fieldError(sender.error);
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
            if (plan != null)
              SrNote(
                message: l10n.teamSeatsFree(
                  context.fmt.number(plan.usersUsed),
                  context.fmt.number(plan.users),
                  context.fmt.number(plan.users - plan.usersUsed),
                ),
              ),
            const SizedBox(height: 14),
            SrSegmented(
              segments: [
                SrSegment(l10n.teamInviteByPhone),
                SrSegment(l10n.teamInviteByEmail),
              ],
              index: _channel.index,
              onChanged: (i) => setState(() {
                _channel = InviteChannel.values[i];
                _missingAddress = false;
              }),
            ),
            const SizedBox(height: 14),
            _addressField(fieldError),
            const SizedBox(height: 14),
            SrTextField(
              controller: _name,
              label: l10n.teamInviteName,
              optional: true,
              hint: l10n.teamInviteNameHint,
              textCapitalization: TextCapitalization.words,
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
            if (!easy) ...[
              const SizedBox(height: 14),
              _toggles(plan?.has(AddOn.fieldForce) ?? false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addressField(String? error) {
    final l10n = context.l10n;
    return _channel == InviteChannel.phone
        ? SrTextField(
            key: const ValueKey('phone'),
            controller: _phone,
            label: l10n.teamInviteByPhone,
            hint: l10n.teamInvitePhoneHint,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            error: error,
          )
        : SrTextField(
            key: const ValueKey('email'),
            controller: _email,
            label: l10n.teamInviteByEmail,
            hint: l10n.teamInviteEmailHint,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            error: error,
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

  Widget _toggles(bool hasFieldForce) {
    final l10n = context.l10n;
    return SwitchCard(
      rows: [
        if (hasFieldForce)
          SwitchRow(
            title: l10n.teamFieldForce,
            subtitle: l10n.teamFieldForceAbout,
            value: _fieldForce,
            onChanged: (v) => setState(() => _fieldForce = v),
          ),
        SwitchRow(
          title: l10n.teamTeamOnlyCapture,
          subtitle: l10n.teamTeamOnlyCaptureAbout,
          value: _teamOnly,
          onChanged: (v) => setState(() => _teamOnly = v),
        ),
      ],
    );
  }

  String? _fieldError(Object? error) {
    if (error is! ApiFailure) return null;
    final key = _channel == InviteChannel.phone ? 'Phone' : 'Email';
    if (error.fieldError(key) == null) return null;
    if (error.isConflict) return context.l10n.teamInviteDuplicate;
    return _channel == InviteChannel.phone
        ? context.l10n.teamInvitePhoneInvalid
        : context.l10n.teamInviteEmailInvalid;
  }

  String? _managerError(Object? error) =>
      error is ApiFailure && error.fieldError('ManagerId') != null
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
  final int? selected;
  final ValueChanged<int> onChanged;
  final bool failed;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrLookupPicker(
      title: l10n.teamReportsTo,
      label: l10n.teamReportsTo,
      placeholder: failed ? l10n.errorGeneric : l10n.teamReportsToHint,
      error: error,
      withAvatar: true,
      selected: selected,
      onChanged: onChanged,
      options: [
        for (final m in managers)
          SrLookupOption(
            id: m.id,
            name: l10n.teamNameWithRole(
              context.name(m.name),
              context.roleLabel(m.role),
            ),
            subtitle: switch (m.area) {
              final area? => context.name(area),
              null => null,
            },
          ),
      ],
    );
  }
}

/// The owner and active team leads, the user first when they are one.
List<Member> managersOf(List<Member> members) => [
  for (final m in members)
    if (m.isActive && m.role != WorkspaceRole.member) m,
]..sort((a, b) => (b.isMe ? 1 : 0) - (a.isMe ? 1 : 0));
