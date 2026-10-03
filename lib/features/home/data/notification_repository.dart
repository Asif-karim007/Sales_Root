import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/home/models/app_notification.dart';

abstract interface class NotificationRepository {
  /// Newest first, 20 per page; [category] null lists everything.
  Future<PageResult<AppNotification>> list({
    NotificationCategory? category,
    int page = 1,
  });

  Future<int> unreadCount();

  Future<void> markRead(int id);

  Future<void> markAllRead();
}
