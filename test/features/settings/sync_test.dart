import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';
import 'package:salesroot/features/settings/providers/sync_providers.dart';

import 'settings_test_utils.dart';

void main() {
  test(
    'keeping the phone value resolves the conflict and files the server one',
    () async {
      final container = await signedInContainer();
      addTearDown(container.dispose);
      keepAlive(container, syncProvider);

      final before = await container.read(syncProvider.future);
      final conflict = before.conflicts.firstWhere((c) => c.fields.length == 1);
      final field = conflict.fields.single;

      await container.read(syncProvider.notifier).resolve(conflict.id, {
        field.field: ConflictSide.local,
      });
      final after = container.read(syncProvider).requireValue;

      expect(after.conflicts.map((c) => c.id), isNot(contains(conflict.id)));
      expect(after.conflicts, hasLength(before.conflicts.length - 1));
      final filed = after.history.single;
      expect(filed.kept.value, field.local.value);
      expect(filed.discarded.value, field.server.value);
      expect(filed.discarded.by, field.server.by);
    },
  );

  test('every field of a conflict needs a choice', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, syncProvider);

    final snapshot = await container.read(syncProvider.future);
    final conflict = snapshot.conflicts.firstWhere((c) => c.fields.length > 1);

    await expectLater(
      container.read(syncProvider.notifier).resolve(conflict.id, {
        conflict.fields.first.field: ConflictSide.server,
      }),
      throwsA(isA<ApiFailure>().having((f) => f.statusCode, 'status', 400)),
    );
    expect(container.read(syncProvider).requireValue.conflicts, hasLength(2));
  });

  test('choices are kept per field until saved', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    final choices = conflictChoicesProvider(2);
    keepAlive(container, choices);

    container.read(choices.notifier)
      ..choose('StageId', ConflictSide.server)
      ..choose('Note', ConflictSide.local)
      ..choose('StageId', ConflictSide.local);

    expect(container.read(choices), {
      'StageId': ConflictSide.local,
      'Note': ConflictSide.local,
    });
  });

  test('offline, a sync keeps the outbox as it was', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, syncProvider);
    final before = await container.read(syncProvider.future);
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: true));

    await expectLater(
      container.read(syncProvider.notifier).syncNow(),
      throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', isTrue)),
    );
    final after = await container.read(syncProvider.future);
    expect(after.pendingCount, before.pendingCount);
  });

  test('a sync sends the outbox and keeps what the server rejects', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, syncProvider);
    final before = await container.read(syncProvider.future);
    expect(before.pendingCount, 3);

    await container.read(syncProvider.notifier).syncNow();
    final after = container.read(syncProvider).requireValue;

    expect(after.outbox.single.failed, isTrue);
    expect(after.outbox.single.error, isNotEmpty);

    await container.read(syncProvider.notifier).discard(after.outbox.single.id);
    expect(container.read(syncProvider).requireValue.pendingCount, 0);
  });

  test('clearing the cache empties it and keeps the data', () async {
    final container = await signedInContainer();
    addTearDown(container.dispose);
    keepAlive(container, syncProvider);
    final before = await container.read(syncProvider.future);

    await container.read(syncProvider.notifier).clearCache();
    final after = container.read(syncProvider).requireValue;

    expect(after.cacheBytes, 0);
    expect(after.dataBytes, before.dataBytes);
  });
}
