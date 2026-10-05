import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/growth/models/notice.dart';
import 'package:salesroot/features/growth/providers/notice_providers.dart';

import 'growth_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('opening marks it read and acknowledging counts once', () async {
    final container = await growthContainer();
    final repository = container.read(noticeRepositoryProvider);
    final before = await repository.get('1');
    expect(before.requiresAck, isTrue);
    expect(before.myState, NoticeState.unread);

    final sub = container.listen(noticeDetailProvider('1'), (_, _) {});
    addTearDown(sub.close);
    final opened = await container.read(noticeDetailProvider('1').future);
    expect(opened.myState, NoticeState.read);
    expect(opened.readCount, before.readCount + 1);
    expect(opened.needsMyAck, isTrue);

    final acknowledged = await container
        .read(noticeDetailProvider('1').notifier)
        .acknowledge();
    expect(acknowledged.myState, NoticeState.acknowledged);
    expect(acknowledged.ackCount, before.ackCount + 1);
    expect(acknowledged.needsMyAck, isFalse);

    final again = await repository.acknowledge('1');
    expect(again.ackCount, acknowledged.ackCount);
    expect(
      again.recipients.where((r) => r.hasAcknowledged).length,
      again.ackCount,
    );
    expect(again.unreadCount, again.audienceCount - again.readCount);
  });

  test('reminders go only to people who still have to act', () async {
    final container = await growthContainer();
    final notice = await container.read(noticeRepositoryProvider).get('1');
    final pending = [
      for (final r in notice.recipients)
        if (!r.hasAcknowledged) r.memberId,
    ];
    final everyone = [for (final r in notice.recipients) r.memberId];

    final sub = container.listen(noticeDetailProvider('1'), (_, _) {});
    addTearDown(sub.close);
    await container.read(noticeDetailProvider('1').future);
    final reminded = await container
        .read(noticeDetailProvider('1').notifier)
        .remind(everyone);
    expect(reminded, pending.length);
  });

  test('publishing needs a title and reaches the whole audience', () async {
    final container = await growthContainer();
    final repository = container.read(noticeRepositoryProvider);
    const blank = NoticeInput(
      title: ' ',
      body: 'Office closed tomorrow.',
      audience: NoticeAudience.everyone,
      requiresAck: true,
      push: true,
      sms: false,
      pinDays: 7,
    );
    await expectLater(
      repository.create(blank),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.fieldError('Title'),
          'title',
          isNotNull,
        ),
      ),
    );

    final counts = await repository.audienceCounts();
    final sub = container.listen(noticeSubmitProvider, (_, _) {});
    addTearDown(sub.close);
    await container
        .read(noticeSubmitProvider.notifier)
        .submit(
          const NoticeInput(
            title: 'Office closed tomorrow',
            body: 'Hartal: the office stays closed. Work from the field.',
            audience: NoticeAudience.everyone,
            requiresAck: true,
            push: true,
            sms: false,
            pinDays: 7,
          ),
        );
    final created = container.read(noticeSubmitProvider).requireValue;
    expect(created?.audienceCount, counts[NoticeAudience.everyone]);
    expect(created?.ackCount, 0);
    expect(created?.pinned, isTrue);

    final list = await container.read(noticeListProvider.future);
    expect(list.items.first.pinned, isTrue);
    expect(list.items.map((n) => n.id), contains(created?.id));
  });

  test('a member sees the notice but not who read it', () async {
    final container = await growthContainer(role: 'executive');
    final notice = await container.read(noticeRepositoryProvider).get('1');
    expect(notice.recipients, isEmpty);
    expect(notice.canEdit, isFalse);
    await expectLater(
      container.read(noticeRepositoryProvider).remind('1', const ['2']),
      throwsA(
        isA<ApiFailure>().having((f) => f.isForbidden, 'forbidden', true),
      ),
    );
  });
}
