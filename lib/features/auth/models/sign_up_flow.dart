import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/features/auth/models/otp_challenge.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';

/// Sign-up in progress: the code sent, then the verified account that is not
/// signed in until the last step.
class SignUpFlow {
  const SignUpFlow({
    this.challenge,
    this.referralCode,
    this.inviteCode,
    this.session,
    this.workStyle,
  });

  final OtpChallenge? challenge;
  final String? referralCode;

  /// The invitation to accept once signed in.
  final String? inviteCode;
  final AuthSession? session;
  final WorkStyle? workStyle;

  SignUpFlow copyWith({
    OtpChallenge? challenge,
    AuthSession? session,
    WorkStyle? workStyle,
    String? inviteCode,
  }) => SignUpFlow(
    challenge: challenge ?? this.challenge,
    referralCode: referralCode,
    inviteCode: inviteCode ?? this.inviteCode,
    session: session ?? this.session,
    workStyle: workStyle ?? this.workStyle,
  );
}
