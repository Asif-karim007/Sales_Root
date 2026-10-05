import 'package:salesroot/core/session/auth_session.dart';

/// A verified number: an existing account signs in with [session]; a new one
/// finishes sign-up with it first.
class PhoneVerification {
  const PhoneVerification({required this.session, required this.isNewUser});

  final AuthSession session;
  final bool isNewUser;

  /// The sign-in body: an account without a name has not finished sign-up.
  factory PhoneVerification.fromJson(Map<String, dynamic> json) {
    final session = AuthSession.fromTokens(json);
    return PhoneVerification(
      session: session,
      isNewUser: session.name.trim().isEmpty,
    );
  }
}
