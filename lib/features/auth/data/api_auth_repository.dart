import 'dart:io';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/auth/data/auth_api.dart';
import 'package:salesroot/features/auth/data/auth_repository.dart';
import 'package:salesroot/features/auth/models/invitation.dart';
import 'package:salesroot/features/auth/models/otp_challenge.dart';
import 'package:salesroot/features/auth/models/phone_verification.dart';
import 'package:salesroot/features/auth/models/referral.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/models/team_setup.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(
    this._api, {
    required this.token,
    required this.language,
    required this.appVersion,
  });

  final AuthApi _api;

  /// The signed-in session's token, or else the pending sign-up's.
  final String? Function() token;
  final String Function() language;
  final Future<String> Function() appVersion;

  String get _bearer {
    final value = token();
    if (value == null) throw const ApiFailure(401, '');
    return 'Bearer $value';
  }

  @override
  Future<OtpChallenge> requestCode(
    String phone, {
    String? referralCode,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    final json = await apiRequest(
      'OTP request',
      () => _api.requestCode({'phone': phone, 'purpose': 'login'}),
    );
    return OtpChallenge.fromJson({
      'phone': phone,
      ...jsonMap(json),
    }, channel: channel);
  }

  @override
  Future<PhoneVerification> verifyCode(
    String phone,
    String code, {
    String? referralCode,
  }) async {
    final version = await appVersion();
    final body = {
      'phone': phone,
      'code': code,
      'name': null,
      'language': language(),
      'deviceName': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'platform': Platform.operatingSystem,
      'appVersion': version,
      'referralCode': referralCode,
    };
    final json = await apiRequest('OTP verify', () => _api.verifyCode(body));
    return PhoneVerification.fromJson(jsonMap(json));
  }

  @override
  Future<AuthSession> completeProfile(
    AuthSession pending,
    SignUpProfile profile,
  ) async {
    await apiRequest(
      'Profile',
      () => _api.updateMe('Bearer ${pending.token}', profile.toJson()),
    );
    return pending.copyWith(name: profile.name.trim());
  }

  @override
  Future<void> setPin(AuthSession session, String pin) => apiRequest(
    'PIN set',
    () => _api.setPin('Bearer ${session.token}', {'pin': pin}),
  );

  @override
  Future<AuthSession> applyIndustryTemplate(
    AuthSession pending,
    IndustryTemplate template,
  ) async {
    final bearer = 'Bearer ${pending.token}';
    if (pending.workspaceId != null) {
      await apiRequest(
        'Industry pack',
        () => _api.updateWorkspace(bearer, {'industryPack': template.wire}),
      );
      return pending;
    }
    final created = jsonMap(
      await apiRequest(
        'Personal workspace',
        () => _api.createWorkspace(bearer, {
          'name': pending.name,
          'type': 'personal',
          'industryPack': template.wire,
          'loadSampleData': false,
        }),
      ),
    );
    final id = jsonId(created['id']) ?? jsonId(created['workspaceId']);
    if (id == null) return pending;
    final json = await apiRequest(
      'Workspace switch',
      () => _api.switchWorkspace(bearer, id),
    );
    return AuthSession.fromTokens(jsonMap(json));
  }

  @override
  Future<Referral> referral(String code) async {
    final clean = code.trim().toUpperCase();
    final json = await apiRequest('Referral', () => _api.referral(clean));
    return Referral.fromJson(clean, jsonMap(json));
  }

  @override
  Future<Invitation> invitation(String code) async {
    final me = jsonMap(await apiRequest('Invitations', () => _api.me(_bearer)));
    final invites = jsonList(me['invites'], Invitation.fromJson);
    for (final invite in invites) {
      if (invite.code == code) return invite;
    }
    throw const ApiFailure(404, 'This invitation is no longer available.');
  }

  @override
  Future<Workspace> acceptInvitation(String code) async {
    final bearer = _bearer;
    final invite = await invitation(code);
    await apiRequest('Invite accept', () => _api.acceptInvite(bearer, code));
    final me = jsonMap(await apiRequest('Workspaces', () => _api.me(bearer)));
    final workspaces = jsonList(me['workspaces'], Workspace.fromJson);
    for (final workspace in workspaces) {
      if (workspace.id == invite.workspaceId) return workspace;
    }
    throw const ApiFailure(404, 'This invitation is no longer available.');
  }

  @override
  Future<void> declineInvitation(String code) =>
      apiRequest('Invite decline', () => _api.declineInvite(_bearer, code));

  @override
  Future<void> setUpTeam(TeamSetup setup) => apiRequest(
    'Team setup',
    () => _api.updateWorkspace(_bearer, setup.toJson()),
  );
}
