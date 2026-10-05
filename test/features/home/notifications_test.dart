import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/home/models/app_notification.dart';
import 'package:salesroot/features/home/providers/notification_providers.dart';

import '../../helpers/api_stub.dart';
import 'home_test_setup.dart';

/// The server has sent no notification to the test user yet, so pages are
/// built on the recorded empty list with items in the expected shape.
Map<String, dynamic> _page(int offset, {int total = 25, int unread = 3}) => {
  ...fixtureMap('home_notifications'),
  'items': [
    for (var i = offset; i < total && i < offset + 20; i++)
      {
        'id': 'n$i',
        'type': i == 0 ? 'new_lead' : 'task_due',
        'titleEn': 'Notification $i',
        'titleBn': 'নোটিফিকেশন $i',
        'createdAt': '2026-10-05T${(23 - i).toString().padLeft(2, '0')}:00:00Z',
        'readAt': i < unread ? null : '2026-10-05T00:00:00Z',
      },
  ],
  'total': total,
  'unread': unread,
  'offset': offset,
  'limit': 20,
};

ApiStub _stub() => homeStub()
  ..on(
    'GET',
    'notifications',
    (RequestOptions r) =>
        _page(int.tryParse('${r.queryParameters['offset']}') ?? 0),
  )
  ..on('POST', 'notifications/read', null);

void main() {
  test('the recorded empty list parses as empty', () async {
    final container = await homeContainer(homeStub());
    container.listen(notificationsProvider, (_, _) {});

    final page = await container.read(notificationsProvider.future);
    expect(page.isEmpty, isTrue);
    expect(await container.read(unreadNotificationCountProvider.future), 0);
  });

  test('parses kinds, both languages and read state', () {
    final item = AppNotification.fromJson(
      (_page(0)['items'] as List).first as Map<String, dynamic>,
    );
    expect(item.id, 'n0');
    expect(item.kind, NotificationKind.newLead);
    expect(item.title.of(true), 'নোটিফিকেশন 0');
    expect(item.isRead, isFalse);
    expect(
      AppNotification.fromJson({
        'id': 'x',
        'type': 'billing',
        'title': {'en': 'Plan renewed', 'bn': 'প্ল্যান নবায়ন'},
        'readAt': '2026-10-05T00:00:00Z',
      }),
      isA<AppNotification>()
          .having((n) => n.kind, 'kind', NotificationKind.billing)
          .having((n) => n.title.en, 'title', 'Plan renewed')
          .having((n) => n.isRead, 'read', true),
    );
  });

  test('pages 20 at a time by offset', () async {
    final stub = _stub();
    final container = await homeContainer(stub);
    container.listen(notificationsProvider, (_, _) {});

    final first = await container.read(notificationsProvider.future);
    expect(first.items, hasLength(20));
    expect(first.hasMore, isTrue);

    await container.read(notificationsProvider.notifier).loadMore();
    expect(stub.last('GET', 'notifications')?.queryParameters['offset'], 20);
    expect(container.read(notificationsProvider).value?.items, hasLength(25));
  });

  test('the badge asks for one item and reads unread', () async {
    final stub = _stub();
    final container = await homeContainer(stub);
    container.listen(unreadNotificationCountProvider, (_, _) {});

    expect(await container.read(unreadNotificationCountProvider.future), 3);
    expect(stub.last('GET', 'notifications')?.queryParameters['limit'], 1);
  });

  test('marking one read sends its id', () async {
    final stub = _stub();
    final container = await homeContainer(stub);
    container.listen(notificationsProvider, (_, _) {});
    await container.read(notificationsProvider.future);

    await container.read(notificationsProvider.notifier).markRead('n1');

    expect(stub.last('POST', 'notifications/read')?.data, ['n1']);
    final item = container
        .read(notificationsProvider)
        .value
        ?.items
        .firstWhere((n) => n.id == 'n1');
    expect(item?.isRead, isTrue);
  });

  test('mark all read sends every unread id loaded', () async {
    final stub = _stub();
    final container = await homeContainer(stub);
    container.listen(notificationsProvider, (_, _) {});
    await container.read(notificationsProvider.future);

    await container.read(notificationsProvider.notifier).markAllRead();

    expect(stub.last('POST', 'notifications/read')?.data, ['n0', 'n1', 'n2']);
    expect(
      container.read(notificationsProvider).value?.items.every((n) => n.isRead),
      isTrue,
    );
  });

  test('a failed mark-all restores the list and reports it', () async {
    final stub = _stub();
    final container = await homeContainer(stub);
    container.listen(notificationsProvider, (_, _) {});
    await container.read(notificationsProvider.future);
    stub.offline = true;

    await expectLater(
      container.read(notificationsProvider.notifier).markAllRead(),
      throwsA(isA<ApiFailure>()),
    );
    final after = container.read(notificationsProvider).value;
    expect(after?.items.where((n) => !n.isRead), hasLength(3));
  });
}
