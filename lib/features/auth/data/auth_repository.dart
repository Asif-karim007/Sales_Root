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

  Future<PhoneVerification> verifyCode(
    String phone,
    String code, {
    String? referralCode,
  });

  /// Names a new account; [pending] is the verified, not yet signed-in
  /// session.
  Future<AuthSession> completeProfile(
    AuthSession pending,
    SignUpProfile profile,
  );

  /// Stores the PIN on the account so another device can unlock with it.
  Future<void> setPin(AuthSession session, String pin);

  /// Gives the account's workspace the template's pack, creating a personal
  /// workspace first when it has none. Returns the session to continue with.
  Future<AuthSession> applyIndustryTemplate(
    AuthSession pending,
    IndustryTemplate template,
  );

  Future<Referral> referral(String code);

  Future<Invitation> invitation(String code);

  /// Joins the invitation's workspace and returns it.
  Future<Workspace> acceptInvitation(String code);

  Future<void> declineInvitation(String code);

  /// Applies #9's choices to the current workspace.
  Future<void> setUpTeam(TeamSetup setup);
}
