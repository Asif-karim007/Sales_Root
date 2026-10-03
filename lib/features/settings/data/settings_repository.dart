import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/settings/models/device_session.dart';
import 'package:salesroot/features/settings/models/notification_prefs.dart';

/// The signed-in user's own settings: notifications, devices and account.
abstract interface class SettingsRepository {
  Future<NotificationPrefs> notificationPrefs();

  Future<NotificationPrefs> saveNotificationPrefs(NotificationPrefs prefs);

  Future<List<DeviceSession>> devices();

  Future<void> removeDevice(int id);

  /// Signs out every device except this one.
  Future<void> signOutOtherDevices();

  Future<PageResult<LoginEvent>> loginHistory(int page);

  /// Schedules the account for deletion after a 30-day grace period.
  Future<void> requestAccountDeletion();
}
