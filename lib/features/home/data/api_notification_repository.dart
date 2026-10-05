import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/home/data/home_api.dart';
import 'package:salesroot/features/home/data/notification_repository.dart';
import 'package:salesroot/features/home/models/app_notification.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._api);

  final HomeApi _api;

  @override
  Future<PageResult<AppNotification>> list({int page = 1}) async {
    final json = await apiRequest(
      'Notifications',
      () => _api.notifications(pageQuery(page)),
    );
    return PageResult.fromJson(jsonMap(json), AppNotification.fromJson);
  }

  @override
  Future<int> unreadCount() async {
    final json = await apiRequest(
      'Notification count',
      () => _api.notifications(pageQuery(1, size: 1)),
    );
    return jsonInt(jsonMap(json)['unread']) ?? 0;
  }

  @override
  Future<void> markRead(List<String> ids) =>
      apiRequest('Notifications read', () => _api.markRead(ids));
}
