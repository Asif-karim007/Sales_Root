import 'dart:math';

import 'package:collection/collection.dart';

import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_repository.dart';
import 'package:salesroot/features/auth/data/auth_fixtures.dart';
import 'package:salesroot/features/auth/data/auth_repository.dart';
import 'package:salesroot/features/auth/models/bd_phone.dart';
import 'package:salesroot/features/auth/models/invitation.dart';
import 'package:salesroot/features/auth/models/otp_challenge.dart';
import 'package:salesroot/features/auth/models/phone_verification.dart';
import 'package:salesroot/features/auth/models/referral.dart';
import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/features/auth/models/team_setup.dart';

/// Accounts are global, not per workspace, so the tables live outside the
/// workspace namespace and survive the empty-workspace dev switch.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._network, this._store, this._workspaces);

  final FakeNetwork _network;
  final FakeStore _store;
  final WorkspaceRepository _workspaces;
  final Random _random = Random();

  static const _resendAfterSeconds = 60;

  FakeTable get _users =>
      _store.table('global/auth_users', authUserFixtures, always: true);
  FakeTable get _codes =>
      _store.table('global/auth_codes', () => [], always: true);
  FakeTable get _invites =>
      _store.table('global/auth_invites', authInviteFixtures, always: true);
  FakeTable get _referrals =>
      _store.table('global/auth_referrals', authReferralFixtures, always: true);
  FakeTable get _teamSetups =>
      _store.table('global/auth_team_setups', () => [], always: true);

  @override
  Future<OtpChallenge> requestCode(
    String phone, {
    String? referralCode,
    OtpChannel channel = OtpChannel.sms,
  }) => _network('Auth request code', () {
    final number = _validPhone(phone);
    final code = _cleanCode(referralCode);
    if (code != null) _checkReferral(code, number);
    final row = {
      'Phone': number,
      'ReferralCode': code,
      'Channel': channel.wire,
      'ResendAfterSeconds': _resendAfterSeconds,
    };
    final pending = _codeFor(number);
    if (pending == null) {
      _codes.insert(row);
    } else {
      _codes.update(pending['Id'] as int, row);
    }
    return OtpChallenge.fromJson(row);
  });

  @override
  Future<PhoneVerification> verifyCode(String phone, String code) =>
      _network('Auth verify code', () {
        final number = BdPhone.e164(phone);
        fakeRequire({'Code': code}, ['Code']);
        final pending = _codeFor(number);
        if (pending == null) {
          throw const ApiFailure(
            400,
            'This code has expired. Ask for a new one.',
            fieldErrors: {'Code': 'Expired'},
          );
        }
        if (code.trim() != demoSmsCode) {
          throw const ApiFailure(
            400,
            'The code is not correct.',
            fieldErrors: {'Code': 'Wrong code'},
          );
        }
        _codes.delete(pending['Id'] as int);
        final user =
            _userByPhone(number) ??
            _users.insert({
              'Id': _users.nextId(),
              'Phone': number,
              'Name': '',
              'ReferralCode': pending['ReferralCode'],
            }, first: false);
        final isNew = (user['Name'] as String? ?? '').isEmpty;
        return PhoneVerification.fromJson({
          'Session': _issue(user),
          'IsNewUser': isNew,
        });
      });

  @override
  Future<AuthSession> completeProfile(String token, SignUpProfile profile) =>
      _network('Auth complete profile', () {
        final body = profile.toJson();
        fakeRequire(body, ['Name']);
        final user = _userByToken(token);
        _users.update(user['Id'] as int, body);
        return AuthSession.fromJson(_sessionOf(user));
      });

  @override
  Future<void> applyIndustryTemplate(String token, IndustryTemplate template) =>
      _network('Auth industry template', () {
        final user = _userByToken(token);
        _users.update(user['Id'] as int, {'IndustryTemplate': template.wire});
      });

  @override
  Future<AuthSession> signInWithEmail(
    String email,
    String password, {
    bool remember = true,
  }) => _network('Auth email sign-in', () {
    fakeRequire({'Email': email, 'Password': password}, ['Email', 'Password']);
    final address = email.trim().toLowerCase();
    final user = _users.rows.firstWhereOrNull(
      (row) => (row['Email'] as String?)?.toLowerCase() == address,
    );
    if (user == null || user['Password'] != password) {
      throw const ApiFailure(
        400,
        'The email or password is wrong.',
        fieldErrors: {'Password': 'Wrong email or password'},
      );
    }
    return AuthSession.fromJson(_issue(user, remember: remember));
  });

  @override
  Future<void> requestPasswordReset(String email) =>
      _network('Auth password reset', () {
        fakeRequire({'Email': email}, ['Email']);
        if (!email.contains('@')) {
          throw const ApiFailure(
            400,
            'Enter a valid email address.',
            fieldErrors: {'Email': 'Invalid email'},
          );
        }
      });

  @override
  Future<Referral> referral(String code) => _network(
    'Auth referral',
    () => Referral.fromJson(_referralByCode(code) ?? _notFound('Referral')),
  );

  @override
  Future<Invitation> invitation(String code) => _network(
    'Auth invitation',
    () => Invitation.fromJson(_pendingInvite(code)),
  );

  @override
  Future<Workspace> acceptInvitation(String code) async {
    final workspaces = await _seededWorkspaces();
    return _network('Auth accept invitation', () {
      final invite = _pendingInvite(code);
      final id = invite['WorkspaceId'] as int;
      final row =
          workspaces.byIdOrNull(id) ??
          workspaces.insert({
            'Id': id,
            'Name': invite['WorkspaceName'],
            'Kind': 'Team',
            'Role': invite['Role'],
            'MemberCount': (invite['MemberCount'] as int? ?? 0) + 1,
            'LeadCount': invite['LeadCount'],
            'OwnerName': invite['InviterName'],
          }, first: false);
      _invites.update(invite['Id'] as int, {'Status': 'Accepted'});
      return Workspace.fromJson(row);
    });
  }

  @override
  Future<void> declineInvitation(String code) =>
      _network('Auth decline invitation', () {
        final invite = _pendingInvite(code);
        _invites.update(invite['Id'] as int, {'Status': 'Declined'});
      });

  @override
  Future<void> setUpTeam(int workspaceId, TeamSetup setup) =>
      _network('Auth team setup', () {
        final row = {'Id': workspaceId, ...setup.toJson()};
        if (_teamSetups.byIdOrNull(workspaceId) == null) {
          _teamSetups.insert(row);
        } else {
          _teamSetups.update(workspaceId, row);
        }
      });

  String _validPhone(String phone) {
    fakeRequire({'Phone': phone}, ['Phone']);
    if (!BdPhone.isValid(phone)) {
      throw const ApiFailure(
        400,
        'Enter a valid Bangladeshi mobile number.',
        fieldErrors: {'Phone': 'Invalid number'},
      );
    }
    return BdPhone.e164(phone);
  }

  void _checkReferral(String code, String number) {
    if (_referralByCode(code) == null) {
      throw const ApiFailure(
        400,
        'This referral code is not valid.',
        fieldErrors: {'ReferralCode': 'Invalid code'},
      );
    }
    if (_userByPhone(number) case final user?
        when (user['Name'] as String? ?? '').isNotEmpty) {
      throw const ApiFailure(
        409,
        'This number already has an account, so it cannot be referred.',
        fieldErrors: {'ReferralCode': 'Already registered'},
      );
    }
  }

  Map<String, dynamic> _issue(
    Map<String, dynamic> user, {
    bool remember = true,
  }) {
    final userId = user['UserId'] as int? ?? user['Id'] as int;
    final token = 'fake.$userId.${_random.nextInt(1 << 32)}';
    final expiresAt = DateTime.now().add(
      remember ? const Duration(days: 30) : const Duration(hours: 12),
    );
    _users.update(user['Id'] as int, {
      'UserId': userId,
      'Token': token,
      'ExpiresAt': jsonUtc(expiresAt),
    });
    return _sessionOf(user);
  }

  Map<String, dynamic> _sessionOf(Map<String, dynamic> user) => {
    'Token': user['Token'],
    'UserId': user['UserId'],
    'Name': user['Name'],
    'Phone': user['Phone'],
    'Email': user['Email'],
    'ExpiresAt': user['ExpiresAt'],
  }..removeWhere((_, value) => value == null);

  Map<String, dynamic>? _codeFor(String number) =>
      _codes.rows.firstWhereOrNull((row) => row['Phone'] == number);

  Map<String, dynamic>? _userByPhone(String number) =>
      _users.rows.firstWhereOrNull((row) => row['Phone'] == number);

  Map<String, dynamic> _userByToken(String token) =>
      _users.rows.firstWhereOrNull((row) => row['Token'] == token) ??
      (throw const ApiFailure(401, 'Your session has expired.'));

  Map<String, dynamic>? _referralByCode(String code) {
    final clean = _cleanCode(code);
    return _referrals.rows.firstWhereOrNull((row) => row['Code'] == clean);
  }

  Map<String, dynamic> _pendingInvite(String code) {
    final clean = _cleanCode(code);
    return _invites.rows.firstWhereOrNull(
          (row) => row['Code'] == clean && row['Status'] == 'Pending',
        ) ??
        _notFound('Invitation');
  }

  Future<FakeTable> _seededWorkspaces() async {
    await _workspaces.list();
    return _store.table('global/workspaces', () => [], always: true);
  }

  static String? _cleanCode(String? code) {
    final clean = code?.trim().toUpperCase() ?? '';
    return clean.isEmpty ? null : clean;
  }

  static Never _notFound(String what) =>
      throw ApiFailure(404, '$what not found or no longer valid.');
}
