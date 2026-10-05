import 'package:salesroot/features/settings/models/device_session.dart';

/// The signed-in user's account: devices and language.
abstract interface class SettingsRepository {
  Future<List<DeviceSession>> devices();

  /// Signs out every device, this one included.
  Future<void> signOutEverywhere();

  /// The language the server writes messages and SMS in: `bn` or `en`.
  Future<void> saveLanguage(String code);
}
