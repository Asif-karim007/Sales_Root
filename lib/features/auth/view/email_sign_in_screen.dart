import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/auth_links.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_failure.dart';
import 'package:salesroot/features/auth/view/widget/auth_intro.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/auth_link.dart';
import 'package:salesroot/features/auth/view/widget/password_reset_sheet.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #12: email and password; the router takes a signed-in user home.
class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _showPassword = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    setState(() {
      _emailError = _email.text.contains('@') ? null : l10n.authEmailInvalid;
      _passwordError = _password.text.isEmpty
          ? l10n.authPasswordRequired
          : null;
    });
    if (_emailError != null || _passwordError != null) return;
    FocusScope.of(context).unfocus();
    ref
        .read(emailSignInProvider.notifier)
        .signIn(_email.text, _password.text, remember: _remember);
  }

  void _onResult(
    AsyncValue<AuthSession?>? previous,
    AsyncValue<AuthSession?> next,
  ) {
    if (next case AsyncError(:final error)) {
      final l10n = context.l10n;
      final field =
          authFieldError(error, 'Password') ?? authFieldError(error, 'Email');
      if (field == null) {
        showSrError(context, authFailureText(l10n, error));
        return;
      }
      setState(() => _passwordError = l10n.authEmailWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final busy = ref.watch(emailSignInProvider).isLoading;
    ref.listen(emailSignInProvider, _onResult);

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.authSignInTitle,
        actions: const [AuthLanguageToggle()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthIntro(title: l10n.authEmailTitle),
              const SizedBox(height: 16),
              SrTextField(
                controller: _email,
                label: l10n.authEmailLabel,
                hint: l10n.authEmailHint,
                error: _emailError,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) => setState(() => _emailError = null),
              ),
              const SizedBox(height: 14),
              SrTextField(
                controller: _password,
                label: l10n.authPasswordLabel,
                error: _passwordError,
                prefixIcon: Icons.lock_outline_rounded,
                obscure: !_showPassword,
                suffix: SrIconButton(
                  icon: _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  tooltip: _showPassword
                      ? l10n.authPasswordHide
                      : l10n.authPasswordShow,
                  compact: true,
                  onTap: () => setState(() => _showPassword = !_showPassword),
                ),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onChanged: (_) => setState(() => _passwordError = null),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  SrCheckbox(
                    value: _remember,
                    onChanged: (value) => setState(() => _remember = value),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.authEmailRemember,
                      style: AppText.body(c.ink, size: 13),
                    ),
                  ),
                  AuthLink(
                    label: l10n.authEmailForgot,
                    size: 13,
                    onTap: () => showPasswordResetSheet(context, _email.text),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SrButton(
                label: l10n.authSignInTitle,
                expand: true,
                loading: busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 14),
              _OrDivider(label: l10n.authOr),
              const SizedBox(height: 14),
              SrButton(
                label: l10n.authEmailUsePhone,
                icon: Icons.smartphone_rounded,
                variant: SrButtonVariant.secondary,
                expand: true,
                onPressed: () => context.go(AuthLinks.phone(signIn: true)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: c.line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: AppText.meta(c.ink3, size: 12)),
        ),
        Expanded(child: Divider(color: c.line, height: 1)),
      ],
    );
  }
}
