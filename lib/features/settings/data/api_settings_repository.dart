import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/settings/data/settings_api.dart';
import 'package:salesroot/features/settings/data/settings_repository.dart';
import 'package:salesroot/features/settings/models/device_session.dart';

class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository(this._api);

  final SettingsApi _api;

  @override
  Future<List<DeviceSession>> devices() async {
    final json = await apiRequest('Devices', () => _api.devices());
    return jsonList(json, DeviceSession.fromJson);
  }

  @override
  Future<void> registerPushToken(
    String token, {
    required String platform,
    required String deviceId,
  }) => apiRequest(
    'Push token',
    () => _api.registerDevice({
      'token': token,
      'platform': platform,
      'deviceId': deviceId,
    }),
  );

  @override
  Future<void> signOutEverywhere() =>
      apiRequest('Sign out everywhere', () => _api.logoutAll());

  @override
  Future<void> saveLanguage(String code) =>
      apiRequest('Language save', () => _api.updateMe({'language': code}));
}
