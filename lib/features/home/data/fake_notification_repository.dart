import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/home/data/notification_fixtures.dart';
import 'package:salesroot/features/home/data/notification_repository.dart';
import 'package:salesroot/features/home/models/app_notification.dart';

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _table => _backend.table('notifications', notificationFixtures);

  @override
  Future<PageResult<AppNotification>> list({
    NotificationCategory? category,
    int page = 1,
  }) => _backend.run('Notification list', () {
    final rows = _table.rows
        .where(
          (row) =>
              category == null ||
              NotificationKind.fromWire(row['Kind'] as String?).category ==
                  category,
        )
        .toList();
    return PageResult.fromJson(
      fakePage(rows, page: page),
      AppNotification.fromJson,
    );
  });

  @override
  Future<int> unreadCount() => _backend.run(
    'Notification unread count',
    () => _table.rows.where((row) => row['IsRead'] != true).length,
  );

  @override
  Future<void> markRead(int id) => _backend.run('Notification read', () {
    _table.update(id, {'IsRead': true});
  });

  @override
  Future<void> markAllRead() => _backend.run('Notification read all', () {
    for (final row in _table.rows) {
      if (row['IsRead'] != true) {
        _table.update(row['Id'] as int, {'IsRead': true});
      }
    }
  });
}
