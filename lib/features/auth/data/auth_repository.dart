import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/auth/models/invitation.dart';
import 'package:salesroot/features/auth/models/otp_challenge.dart';
import 'package:salesroot/features/auth/models/phone_verification.dart';
import 'package:salesroot/features/auth/models/referral.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/models/team_setup.dart';

abstract interface class AuthRepository {
  Future<OtpChallenge> requestCode(
    String phone, {
    String? referralCode,
    OtpChannel channel = OtpChannel.sms,
  });

  Future<PhoneVerification> verifyCode(String phone, String code);

  /// Names a new account; [token] is the pending session's.
  Future<AuthSession> completeProfile(String token, SignUpProfile profile);

  Future<void> applyIndustryTemplate(String token, IndustryTemplate template);

  Future<AuthSession> signInWithEmail(
    String email,
    String password, {
    bool remember = true,
  });

  Future<void> requestPasswordReset(String email);

  Future<Referral> referral(String code);

  Future<Invitation> invitation(String code);

  /// Joins the invitation's workspace and returns it.
  Future<Workspace> acceptInvitation(String code);

  Future<void> declineInvitation(String code);

  Future<void> setUpTeam(int workspaceId, TeamSetup setup);
}
