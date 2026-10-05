import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/home/models/app_notification.dart';

abstract interface class NotificationRepository {
  /// Newest first, 20 per page.
  Future<PageResult<AppNotification>> list({int page = 1});

  Future<int> unreadCount();

  Future<void> markRead(List<String> ids);
}
