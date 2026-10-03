import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// A verified number: an existing account signs in with [session]; a new one
/// finishes sign-up with it first.
class PhoneVerification {
  const PhoneVerification({required this.session, required this.isNewUser});

  final AuthSession session;
  final bool isNewUser;

  factory PhoneVerification.fromJson(Map<String, dynamic> json) =>
      PhoneVerification(
        session:
            jsonObject(json['Session'], AuthSession.fromJson) ??
            const AuthSession(token: '', userId: 0, name: ''),
        isNewUser: jsonBool(json['IsNewUser']),
      );
}
