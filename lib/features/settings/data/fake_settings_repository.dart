import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/settings/data/settings_fixtures.dart';
import 'package:salesroot/features/settings/data/settings_repository.dart';
import 'package:salesroot/features/settings/models/device_session.dart';
import 'package:salesroot/features/settings/models/notification_prefs.dart';

/// Devices and sign-ins belong to the account, so they live outside the
/// workspace tables. Notification choices are written through to
/// SharedPreferences so they survive a restart.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository(this._backend, this._prefs);

  final FakeBackend _backend;
  final SharedPreferences _prefs;

  String get _prefsKey =>
      'settings/notifications/${_backend.graph.workspaceId}';

  FakeTable get _devices => _backend.store.table(
    'global/settings/devices',
    () => deviceFixtures(_backend.graph),
    always: true,
  );

  FakeTable get _logins => _backend.store.table(
    'global/settings/logins',
    () => loginFixtures(_backend.graph),
    always: true,
  );

  @override
  Future<NotificationPrefs> notificationPrefs() =>
      _backend.run('Notification prefs', () {
        final saved = _prefs.getString(_prefsKey);
        return NotificationPrefs.fromJson(
          saved == null
              ? notificationPrefsSeed
              : jsonDecode(saved) as Map<String, dynamic>,
        );
      });

  @override
  Future<NotificationPrefs> saveNotificationPrefs(NotificationPrefs prefs) =>
      _backend.run('Notification prefs save', () async {
        final json = prefs.toJson();
        if (prefs.quietEnabled &&
            prefs.quietFromMinute == prefs.quietToMinute) {
          throw const ApiFailure(
            400,
            'Quiet hours must start and end at different times',
            fieldErrors: {'QuietToMinute': 'Pick a different end time'},
          );
        }
        await _prefs.setString(_prefsKey, jsonEncode(json));
        return NotificationPrefs.fromJson(json);
      });

  @override
  Future<List<DeviceSession>> devices() => _backend.run(
    'Devices',
    () => [for (final row in _devices.rows) DeviceSession.fromJson(row)],
  );

  @override
  Future<void> removeDevice(int id) => _backend.run('Device remove', () {
    if (_devices.byId(id)['IsCurrent'] == true) {
      throw const ApiFailure(400, 'Use Sign out to remove this device');
    }
    _devices.delete(id);
  });

  @override
  Future<void> signOutOtherDevices() => _backend.run('Devices sign out', () {
    _devices.replaceAll([
      for (final row in _devices.rows)
        if (row['IsCurrent'] == true) Map<String, dynamic>.of(row),
    ]);
  });

  @override
  Future<PageResult<LoginEvent>> loginHistory(int page) => _backend.run(
    'Login history',
    () => PageResult.fromJson(
      fakePage(_logins.rows, page: page),
      LoginEvent.fromJson,
    ),
  );

  @override
  Future<void> requestAccountDeletion() => _backend.run('Account delete', () {
    final ownsTeam =
        _backend.role == WorkspaceRole.owner &&
        _backend.graph.members.length > 1;
    if (ownsTeam) {
      throw const ApiFailure(
        409,
        'Hand this workspace to another owner before deleting your account.',
      );
    }
  });
}
