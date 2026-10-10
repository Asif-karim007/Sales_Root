import 'package:salesroot/features/settings/models/device_session.dart';

/// The signed-in user's account: devices and language.
abstract interface class SettingsRepository {
  Future<List<DeviceSession>> devices();

  /// Lets the server send push messages to this install.
  Future<void> registerPushToken(
    String token, {
    required String platform,
    required String deviceId,
  });

  /// Signs out every device, this one included.
  Future<void> signOutEverywhere();

  /// The language the server writes messages and SMS in: `bn` or `en`.
  Future<void> saveLanguage(String code);
}
