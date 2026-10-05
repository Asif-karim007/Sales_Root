import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/data/sync_store.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';
import 'package:salesroot/features/settings/providers/sync_providers.dart';

import '../../helpers/api_stub.dart';
import 'settings_test_setup.dart';

SyncStore _store(ProviderContainer container) => SyncStore(
  container.read(sharedPreferencesProvider),
  container.read(currentWorkspaceProvider)?.id ?? '',
);

const _edit = OutboxItem(
  id: 'local-1',
  table: 'tasks',
  operation: OutboxOperation.update,
  row: {'id': taskId, 'title': '[test] sync probe edited'},
);

const _rejected = OutboxItem(
  id: 'local-2',
  table: 'leads',
  operation: OutboxOperation.update,
  row: {'id': '00000000-0000-0000-0000-000000000000', 'title': 'x'},
);

void main() {
  test(
    'the first sync takes its cursor from the push, without a pull',
    () async {
      final stub = settingsStub();
      final container = await settingsContainer(stub);
      listenTo(container, syncProvider);
      await container.read(syncProvider.future);

      await container.read(syncProvider.notifier).syncNow();

      final snapshot = container.read(syncProvider).value;
      expect(snapshot?.cursor, 258);
      expect(
        snapshot?.lastSyncAt?.toUtc(),
        DateTime.utc(2026, 10, 5, 17, 26, 25, 195, 476),
      );
      expect(stub.last('GET', 'sync'), isNull);
      final push = stub.lastBody('POST', 'sync');
      expect(push['changes'], isEmpty);
      expect(push['deviceId'], isA<String>());
    },
  );

  test('later syncs pull since the cursor and count what came in', () async {
    final stub = settingsStub();
    final container = await settingsContainer(stub);
    listenTo(container, syncProvider);
    await _store(container).write(const SyncSnapshot(cursor: 120));

    await container.read(syncProvider.notifier).syncNow();

    expect(stub.last('GET', 'sync')?.queryParameters['since'], 120);
    final snapshot = container.read(syncProvider).value;
    expect(snapshot?.cursor, 360);
    expect(snapshot?.received, 17);
  });

  test('a sync sends the outbox; conflicts and rejections stay', () async {
    final stub = settingsStub()
      ..on('POST', 'sync', fixture('settings_sync_conflict'));
    final container = await settingsContainer(stub);
    listenTo(container, syncProvider);
    final store = _store(container);
    await store.enqueue(_edit);
    await store.enqueue(_rejected);

    await container.read(syncProvider.notifier).syncNow();

    final changes = stub.lastBody('POST', 'sync')['changes'] as List;
    expect(changes.first, {
      'table': 'tasks',
      'op': 'update',
      'row': {'id': taskId, 'title': '[test] sync probe edited'},
      'baseUpdatedAt': null,
    });
    final snapshot = container.read(syncProvider).value;
    expect(snapshot?.outbox.single.id, 'local-2');
    expect(snapshot?.outbox.single.error?.en, 'This table cannot be pushed');
    final conflict = snapshot?.conflicts.single;
    expect(conflict?.id, taskId);
    expect(conflict?.entity, SyncEntity.task);
    expect(conflict?.fields.single.field, 'title');
    expect(conflict?.fields.single.server.value, '[test] sync probe');
    expect(conflict?.fields.single.local.value, '[test] sync probe edited');
  });

  test('offline, a sync keeps the outbox as it was', () async {
    final stub = settingsStub();
    final container = await settingsContainer(stub);
    listenTo(container, syncProvider);
    await _store(container).enqueue(_edit);
    stub.offline = true;

    await expectLater(
      container.read(syncProvider.notifier).syncNow(),
      throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
    );
    expect(_store(container).read().outbox.single.id, 'local-1');
  });

  test('resolving pushes the chosen values on the server version', () async {
    final stub = settingsStub()
      ..on('POST', 'sync', fixture('settings_sync_conflict'));
    final container = await settingsContainer(stub);
    listenTo(container, syncProvider);
    await _store(container).enqueue(_edit);
    await container.read(syncProvider.notifier).syncNow();
    stub.on('POST', 'sync', fixture('settings_sync_applied'));

    await container.read(syncProvider.notifier).resolve(taskId, {
      'title': ConflictSide.server,
    });

    final change = (stub.lastBody('POST', 'sync')['changes'] as List).single;
    expect(change['row'], {'id': taskId, 'title': '[test] sync probe'});
    expect(change['baseUpdatedAt'], '2026-10-05T17:26:35.767995Z');
    final snapshot = container.read(syncProvider).value;
    expect(snapshot?.conflicts, isEmpty);
    expect(snapshot?.history.single.kept, '[test] sync probe');
    expect(snapshot?.history.single.discarded, '[test] sync probe edited');
  });

  test('a record changed again stays a conflict', () async {
    final stub = settingsStub()
      ..on('POST', 'sync', fixture('settings_sync_conflict'));
    final container = await settingsContainer(stub);
    listenTo(container, syncProvider);
    await _store(container).enqueue(_edit);
    await container.read(syncProvider.notifier).syncNow();

    await expectLater(
      container.read(syncProvider.notifier).resolve(taskId, {
        'title': ConflictSide.local,
      }),
      throwsA(isA<ApiFailure>().having((f) => f.isConflict, '409', isTrue)),
    );
    expect(container.read(syncProvider).value?.conflicts.single.id, taskId);
  });

  test('choices are kept per field until saved', () async {
    final container = await settingsContainer(settingsStub());
    listenTo(container, conflictChoicesProvider(taskId));

    container
        .read(conflictChoicesProvider(taskId).notifier)
        .choose('title', ConflictSide.local);
    container
        .read(conflictChoicesProvider(taskId).notifier)
        .choose('dueAt', ConflictSide.server);

    expect(container.read(conflictChoicesProvider(taskId)), {
      'title': ConflictSide.local,
      'dueAt': ConflictSide.server,
    });
  });

  test('a discarded write leaves the outbox', () async {
    final container = await settingsContainer(settingsStub());
    listenTo(container, syncProvider);
    await _store(container).enqueue(_edit);
    container.invalidate(syncProvider);
    await container.read(syncProvider.future);

    await container.read(syncProvider.notifier).discard('local-1');

    expect(container.read(syncProvider).value?.outbox, isEmpty);
  });
}
