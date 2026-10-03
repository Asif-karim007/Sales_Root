import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/home/models/app_notification.dart';
import 'package:salesroot/features/home/providers/notification_providers.dart';

import 'home_test_setup.dart';

void main() {
  test('lists 20 newest first and loads more on scroll', () async {
    final container = await homeContainer();
    container.listen(notificationsProvider, (_, _) {});

    final first = await container.read(notificationsProvider.future);
    expect(first.items, hasLength(20));
    expect(first.hasMore, isTrue);
    for (var i = 1; i < first.items.length; i++) {
      expect(
        first.items[i - 1].createdAt.isAfter(first.items[i].createdAt),
        isTrue,
      );
    }

    await container.read(notificationsProvider.notifier).loadMore();
    expect(container.read(notificationsProvider).value?.items, hasLength(40));
  });

  test('marking one read lowers the unread count', () async {
    final container = await homeContainer();
    container
      ..listen(notificationsProvider, (_, _) {})
      ..listen(unreadNotificationCountProvider, (_, _) {});
    final list = await container.read(notificationsProvider.future);
    final before = await container.read(unreadNotificationCountProvider.future);
    final unread = list.items.firstWhere((n) => !n.isRead);

    await container.read(notificationsProvider.notifier).markRead(unread.id);

    final after = await container.read(unreadNotificationCountProvider.future);
    expect(after, before - 1);
    final updated = container
        .read(notificationsProvider)
        .value
        ?.items
        .firstWhere((n) => n.id == unread.id);
    expect(updated?.isRead, isTrue);
  });

  test('mark all read clears the badge', () async {
    final container = await homeContainer();
    container
      ..listen(notificationsProvider, (_, _) {})
      ..listen(unreadNotificationCountProvider, (_, _) {});
    await container.read(notificationsProvider.future);

    await container.read(notificationsProvider.notifier).markAllRead();

    expect(await container.read(unreadNotificationCountProvider.future), 0);
    expect(
      container.read(notificationsProvider).value?.items.every((n) => n.isRead),
      isTrue,
    );
  });

  test('a failed mark-all restores the list and reports it', () async {
    final container = await homeContainer();
    container.listen(notificationsProvider, (_, _) {});
    final before = await container.read(notificationsProvider.future);
    goOffline(container);

    await expectLater(
      container.read(notificationsProvider.notifier).markAllRead(),
      throwsA(isA<ApiFailure>()),
    );
    final after = container.read(notificationsProvider).value;
    expect(
      after?.items.where((n) => !n.isRead).length,
      before.items.where((n) => !n.isRead).length,
    );
  });

  test('the filter keeps one category', () async {
    final container = await homeContainer();
    container.listen(notificationsProvider, (_, _) {});
    container
        .read(notificationFilterProvider.notifier)
        .select(NotificationCategory.billing);

    final page = await container.read(notificationsProvider.future);
    expect(page.items, isNotEmpty);
    expect(
      page.items.every((n) => n.kind.category == NotificationCategory.billing),
      isTrue,
    );
  });

  test('an empty workspace has no notifications', () async {
    final container = await homeContainer(empty: true);
    container.listen(notificationsProvider, (_, _) {});

    expect(
      (await container.read(notificationsProvider.future)).isEmpty,
      isTrue,
    );
  });
}
