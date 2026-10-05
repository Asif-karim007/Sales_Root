import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/auth/models/bd_phone.dart';
import 'package:salesroot/features/auth/models/otp_challenge.dart';
import 'package:salesroot/features/auth/models/phone_verification.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/view/widget/auth_failure.dart';
import 'package:salesroot/features/auth/view/widget/auth_intro.dart';
import 'package:salesroot/features/auth/view/widget/auth_language_toggle.dart';
import 'package:salesroot/features/auth/view/widget/auth_link.dart';
import 'package:salesroot/features/auth/view/widget/shake.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #3: the 6-digit SMS code, checked as soon as the last digit is typed.
class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key, this.signIn = false});

  final bool signIn;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  static const _length = 6;

  String _code = '';
  bool _wrong = false;
  int _mistakes = 0;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(ref.read(signUpFlowProvider).challenge);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(OtpChallenge? challenge) {
    _timer?.cancel();
    _secondsLeft = challenge?.resendAfterSeconds ?? 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft = _secondsLeft > 0 ? _secondsLeft - 1 : 0);
    });
  }

  void _digit(int value) {
    final restart = _wrong;
    if (!restart && _code.length >= _length) return;
    setState(() {
      _code = restart ? '$value' : '$_code$value';
      _wrong = false;
    });
    ref.read(verifyCodeProvider.notifier).clearError();
    if (_code.length == _length) _verify();
  }

  void _backspace() {
    if (_code.isEmpty) return;
    setState(() {
      _code = _code.substring(0, _code.length - 1);
      _wrong = false;
    });
  }

  void _verify() => ref.read(verifyCodeProvider.notifier).verify(_code);

  void _onVerified(
    AsyncValue<PhoneVerification?>? previous,
    AsyncValue<PhoneVerification?> next,
  ) {
    switch (next) {
      case AsyncData(:final value?):
        final flow = ref.read(signUpFlowProvider.notifier);
        final invite = ref.read(signUpFlowProvider).inviteCode;
        if (value.isNewUser) {
          context.go(Routes.authPin);
        } else if (invite != null) {
          context.go(Routes.acceptInviteFor(invite));
          flow.signIn();
        }
      case AsyncError(:final error):
        if (authFieldError(error, 'code') != null) {
          setState(() {
            _wrong = true;
            _mistakes++;
          });
        } else {
          showSrError(context, authFailureText(context.l10n, error));
        }
      default:
    }
  }

  void _onResent(
    AsyncValue<OtpChallenge?>? previous,
    AsyncValue<OtpChallenge?> next,
  ) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(:final value?) when previous is AsyncLoading:
        _startCountdown(value);
        setState(() {
          _code = '';
          _wrong = false;
        });
        showSrInfo(
          context,
          value.channel == OtpChannel.call
              ? l10n.authCodeCalling
              : l10n.authCodeResent,
        );
      case AsyncError(:final error):
        showSrError(context, authFailureText(l10n, error));
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final phone = ref.watch(
      signUpFlowProvider.select((f) => f.challenge?.phone ?? ''),
    );
    final verifying = ref.watch(verifyCodeProvider).isLoading;
    final resending = ref.watch(resendCodeProvider).isLoading;
    ref
      ..listen(verifyCodeProvider, _onVerified)
      ..listen(resendCodeProvider, _onResent);
    final canResend = _secondsLeft == 0 && !resending;
    void resend(OtpChannel channel) =>
        ref.read(resendCodeProvider.notifier).resend(channel);

    return SrScaffold(
      appBar: SrAppBar(
        title: widget.signIn ? l10n.authSignInTitle : l10n.authSignUpTitle,
        subtitle: widget.signIn
            ? null
            : l10n.authStep(fmt.number(2), fmt.number(4)),
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
                  AuthIntro(
                    title: l10n.authCodeTitle,
                    lead: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.authCodeSentTo(
                            fmt.phone(BdPhone.display(phone)),
                          ),
                        ),
                        AuthLink(
                          label: l10n.authCodeChange,
                          size: 14,
                          onTap: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Shake(
                    trigger: _mistakes,
                    child: SrOtpBoxes(
                      value: _code,
                      obscure: true,
                      error: _wrong,
                    ),
                  ),
                  if (_wrong) ...[
                    const SizedBox(height: 8),
                    Text(l10n.authCodeWrong, style: AppText.meta(c.danger)),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      _secondsLeft > 0
                          ? Text(
                              l10n.authCodeResendIn(
                                fmt.digits(_clock(_secondsLeft)),
                              ),
                              style: AppText.meta(c.ink2, size: 13),
                            )
                          : AuthLink(
                              label: l10n.authCodeResend,
                              size: 13,
                              onTap: canResend
                                  ? () => resend(OtpChannel.sms)
                                  : null,
                            ),
                      AuthLink(
                        label: l10n.authCodeCallMe,
                        size: 13,
                        onTap: canResend ? () => resend(OtpChannel.call) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SrButton(
                    label: l10n.commonNext,
                    expand: true,
                    loading: verifying,
                    onPressed: _code.length == _length && !_wrong
                        ? _verify
                        : null,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SrKeypad(
              onDigit: _digit,
              onBackspace: _backspace,
              enabled: !verifying,
            ),
          ),
        ],
      ),
    );
  }

  static String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
