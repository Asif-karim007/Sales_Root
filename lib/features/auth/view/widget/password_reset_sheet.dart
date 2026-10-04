import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_failure.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

Future<void> showPasswordResetSheet(BuildContext context, String email) =>
    showSrSheet<void>(
      context: context,
      builder: (_) => _PasswordResetSheet(email: email),
    );

class _PasswordResetSheet extends ConsumerStatefulWidget {
  const _PasswordResetSheet({required this.email});

  final String email;

  @override
  ConsumerState<_PasswordResetSheet> createState() =>
      _PasswordResetSheetState();
}

class _PasswordResetSheetState extends ConsumerState<_PasswordResetSheet> {
  late final _email = TextEditingController(text: widget.email);
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    if (!_email.text.contains('@')) {
      setState(() => _error = context.l10n.authEmailInvalid);
      return;
    }
    ref.read(passwordResetProvider.notifier).send(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sending = ref.watch(passwordResetProvider).isLoading;
    ref.listen(passwordResetProvider, (previous, next) {
      switch (next) {
        case AsyncData(value: true):
          showSrSuccess(context, l10n.authResetSent);
          Navigator.of(context).pop();
        case AsyncError(:final error):
          if (authFieldError(error, 'Email') != null) {
            setState(() => _error = l10n.authEmailInvalid);
          } else {
            showSrError(context, authFailureText(l10n, error));
          }
        default:
      }
    });

    return SrSheet(
      title: l10n.authResetTitle,
      subtitle: l10n.authResetLead,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrTextField(
            controller: _email,
            label: l10n.authEmailLabel,
            hint: l10n.authEmailHint,
            error: _error,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autofocus: widget.email.isEmpty,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 16),
          SrButton(
            label: l10n.authResetSend,
            expand: true,
            loading: sending,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
