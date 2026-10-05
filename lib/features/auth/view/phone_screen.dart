import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/auth/auth_links.dart';
import 'package:salesroot/features/auth/models/bd_phone.dart';
import 'package:salesroot/features/auth/models/otp_challenge.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_failure.dart';
import 'package:salesroot/features/auth/view/widget/auth_intro.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/phone_field.dart';
import 'package:salesroot/features/auth/view/widget/referral_banner.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #2 mobile number, and #188 when opened from a referral link. Sign-in
/// uses the same screen without the steps and the referral field.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({
    super.key,
    this.signIn = false,
    this.referralCode,
    this.inviteCode,
  });

  final bool signIn;

  /// Prefilled from `/r/:code`; shows the inviter banner.
  final String? referralCode;

  /// Set when coming from an invitation, to accept it after verifying.
  final String? inviteCode;

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  late final _referral = TextEditingController(text: widget.referralCode);
  final _referralFocus = FocusNode();
  String _digits = '';
  String? _phoneError;
  String? _referralError;

  @override
  void initState() {
    super.initState();
    _referralFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _referral.dispose();
    _referralFocus.dispose();
    super.dispose();
  }

  void _digit(int value) {
    if (_digits.length >= BdPhone.maxDigits(_digits)) return;
    setState(() {
      _digits += '$value';
      _phoneError = null;
    });
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() {
      _digits = _digits.substring(0, _digits.length - 1);
      _phoneError = null;
    });
  }

  void _send() {
    if (!BdPhone.isValid(_digits)) {
      setState(() => _phoneError = context.l10n.authPhoneInvalid);
      return;
    }
    FocusScope.of(context).unfocus();
    ref
        .read(sendCodeProvider.notifier)
        .send(
          _digits,
          referralCode: widget.signIn ? null : _referral.text,
          inviteCode: widget.inviteCode,
        );
  }

  void _onSent(
    AsyncValue<OtpChallenge?>? previous,
    AsyncValue<OtpChallenge?> next,
  ) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(value: _?) when previous is AsyncLoading:
        context.push(AuthLinks.code(signIn: widget.signIn));
      case AsyncError(:final error):
        final phone = authFieldError(error, 'Phone');
        final referral = authFieldError(error, 'ReferralCode');
        if (phone == null && referral == null) {
          showSrError(context, authFailureText(l10n, error));
        }
        setState(() {
          _phoneError = phone == null ? null : l10n.authPhoneInvalid;
          _referralError = referral == null
              ? null
              : error is ApiFailure && error.isConflict
              ? l10n.authReferralUsed
              : l10n.authReferralInvalid;
        });
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final referralCode = widget.referralCode;
    final sending = ref.watch(sendCodeProvider).isLoading;
    ref.listen(sendCodeProvider, _onSent);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return SrScaffold(
      appBar: SrAppBar(
        title: widget.signIn ? l10n.authSignInTitle : l10n.authSignUpTitle,
        subtitle: widget.signIn
            ? null
            : l10n.authStep(fmt.number(1), fmt.number(4)),
        actions: const [AuthLanguageToggle()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (referralCode != null) ReferralBanner(code: referralCode),
                  AuthIntro(
                    title: l10n.authPhoneTitle,
                    lead: Text(l10n.authPhoneLead),
                  ),
                  const SizedBox(height: 18),
                  if (!widget.signIn) ...[
                    SrFieldLabel(l10n.authPhoneLabel),
                    const SizedBox(height: 6),
                  ],
                  PhoneField(
                    digits: _digits,
                    focused: !_referralFocus.hasFocus,
                    error: _phoneError,
                    onTap: () => FocusScope.of(context).unfocus(),
                  ),
                  if (!widget.signIn) ...[
                    const SizedBox(height: 14),
                    _ReferralField(
                      controller: _referral,
                      focusNode: _referralFocus,
                      error: _referralError,
                      onChanged: () => setState(() => _referralError = null),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SrButton(
                    label: l10n.authSendCode,
                    expand: true,
                    loading: sending,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
          if (!keyboardOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SrKeypad(
                onDigit: _digit,
                onBackspace: _backspace,
                enabled: !sending,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReferralField extends StatelessWidget {
  const _ReferralField({
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrTextField(
      controller: controller,
      focusNode: focusNode,
      label: l10n.authReferralLabel,
      optional: true,
      hint: l10n.authReferralHint,
      helper: l10n.authReferralHelper,
      error: error,
      prefixIcon: Icons.card_giftcard_rounded,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
        LengthLimitingTextInputFormatter(12),
      ],
      textInputAction: TextInputAction.done,
      onChanged: (_) => onChanged(),
    );
  }
}
