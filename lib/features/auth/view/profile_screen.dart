import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_failure.dart';
import 'package:salesroot/features/auth/view/widget/auth_intro.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/sign_up_steps.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #5: the user's name and how they work. Joining a team asks for the
/// invitation code and skips the industry step.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  late final _invite = TextEditingController(
    text: ref.read(signUpFlowProvider).inviteCode,
  );
  late WorkStyle _style = _invite.text.isEmpty
      ? WorkStyle.solo
      : WorkStyle.joining;
  String? _nameError;
  String? _inviteError;

  @override
  void dispose() {
    _name.dispose();
    _invite.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final joining = _style == WorkStyle.joining;
    setState(() {
      _nameError = _name.text.trim().length < 2 ? l10n.authNameRequired : null;
      _inviteError = joining && _invite.text.trim().isEmpty
          ? l10n.authInviteCodeRequired
          : null;
    });
    if (_nameError != null || _inviteError != null) return;
    FocusScope.of(context).unfocus();
    ref
        .read(profileSubmitProvider.notifier)
        .submit(_name.text, _style, inviteCode: _invite.text);
  }

  void _onSaved(
    AsyncValue<AuthSession?>? previous,
    AsyncValue<AuthSession?> next,
  ) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(value: _?) when previous is AsyncLoading:
        if (_style == WorkStyle.joining) {
          finishSignUp(context, ref);
        } else {
          context.push(Routes.authIndustry);
        }
      case AsyncError(:final error):
        final name = authFieldError(error, 'name');
        final invite = authFieldError(error, 'inviteCode');
        if (name == null && invite == null) {
          showSrError(context, authFailureText(l10n, error));
        }
        setState(() {
          _nameError = name == null ? null : l10n.authNameRequired;
          _inviteError = invite == null ? null : l10n.authInviteCodeInvalid;
        });
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final saving = ref.watch(profileSubmitProvider).isLoading;
    ref.listen(profileSubmitProvider, _onSaved);

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.authSignUpTitle,
        subtitle: l10n.authStep(fmt.number(4), fmt.number(4)),
        actions: const [AuthLanguageToggle()],
      ),
      footer: SrButton(
        label: l10n.authGetStarted,
        expand: true,
        loading: saving,
        onPressed: _submit,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthIntro(title: l10n.authNameTitle),
            const SizedBox(height: 14),
            SrTextField(
              controller: _name,
              label: l10n.authNameLabel,
              hint: l10n.authNameHint,
              error: _nameError,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.name],
              onChanged: (_) => setState(() => _nameError = null),
            ),
            const SizedBox(height: 20),
            Text(l10n.authWorkTitle, style: AppText.sectionTitle(c.ink)),
            const SizedBox(height: 10),
            for (final style in WorkStyle.values) ...[
              _WorkStyleCard(
                style: style,
                selected: style == _style,
                onTap: () => setState(() => _style = style),
              ),
              const SizedBox(height: 8),
            ],
            if (_style == WorkStyle.joining) ...[
              const SizedBox(height: 6),
              SrTextField(
                controller: _invite,
                label: l10n.authInviteCodeLabel,
                hint: l10n.authInviteCodeHint,
                error: _inviteError,
                prefixIcon: Icons.mail_outline_rounded,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                onChanged: (_) => setState(() => _inviteError = null),
              ),
              const SizedBox(height: 8),
            ],
            Text(l10n.authWorkChangeLater, style: AppText.meta(c.ink2)),
          ],
        ),
      ),
    );
  }
}

class _WorkStyleCard extends StatelessWidget {
  const _WorkStyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final WorkStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final (icon, title, subtitle) = switch (style) {
      WorkStyle.solo => (
        Icons.person_outline_rounded,
        l10n.authWorkSolo,
        l10n.authWorkSoloSub,
      ),
      WorkStyle.team => (
        Icons.groups_outlined,
        l10n.authWorkTeam,
        l10n.authWorkTeamSub,
      ),
      WorkStyle.joining => (
        Icons.group_add_outlined,
        l10n.authWorkJoining,
        l10n.authWorkJoiningSub,
      ),
    };

    return Semantics(
      selected: selected,
      child: SrCard(
        tone: selected ? SrCardTone.tint : SrCardTone.plain,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            SrAvatar(
              icon: icon,
              tone: selected ? SrAvatarTone.accent : SrAvatarTone.neutral,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.rowTitle(c.ink)),
                  Text(subtitle, style: AppText.meta(c.ink2)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_rounded, size: 22, color: c.accent),
          ],
        ),
      ),
    );
  }
}
