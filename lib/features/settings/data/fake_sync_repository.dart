import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/settings/data/sync_fixtures.dart';
import 'package:salesroot/features/settings/data/sync_repository.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';

/// The outbox, conflicts and cache live on the phone, so reading them works
/// offline; only [flush] and [resolve] reach the server. Outbox rows may
/// carry `Rejects`: the reason the fake server turns that write down.
class FakeSyncRepository implements SyncRepository {
  FakeSyncRepository(this._backend);

  final FakeBackend _backend;

  FakeTable get _meta => _backend.store.table(
    '${_backend.graph.workspaceId}/sync/meta',
    () => syncMetaFixtures(_backend.graph),
    always: true,
  );

  FakeTable get _outbox => _backend.table('sync/outbox', outboxFixtures);

  FakeTable get _conflicts =>
      _backend.table('sync/conflicts', conflictFixtures);

  FakeTable get _history => _backend.table('sync/history', (_) => const []);

  @override
  Future<SyncSnapshot> snapshot() =>
      Future(() => SyncSnapshot.fromJson(_snapshot()));

  @override
  Future<SyncSnapshot> flush() => _backend.run('Sync flush', () {
    final queue = [..._outbox.rows]
      ..sort((a, b) => '${a['CreatedAt']}'.compareTo('${b['CreatedAt']}'));
    for (final row in queue) {
      final id = row['Id'] as int;
      final rejects = row['Rejects'];
      if (rejects == null) {
        _outbox.delete(id);
      } else {
        _outbox.update(id, {'Error': rejects});
      }
    }
    _meta.update(1, {'LastSyncAt': AppDateUtils.toApiUtc(DateTime.now())});
    return SyncSnapshot.fromJson(_snapshot());
  });

  @override
  Future<void> discard(int outboxId) => Future(() => _outbox.delete(outboxId));

  @override
  Future<SyncConflict> conflict(int id) =>
      Future(() => SyncConflict.fromJson(_conflicts.byId(id)));

  @override
  Future<void> resolve(int conflictId, Map<String, ConflictSide> choices) =>
      _backend.run('Sync resolve', () {
        final row = _conflicts.byId(conflictId);
        final fields = [
          for (final f in row['Fields'] as List) f as Map<String, dynamic>,
        ];
        final missing = fields.where((f) => choices[f['Field']] == null);
        if (missing.isNotEmpty) {
          throw ApiFailure(
            400,
            'Choose a value for every field',
            fieldErrors: {
              for (final f in missing) '${f['Field']}': 'Choose one',
            },
          );
        }
        final now = AppDateUtils.toApiUtc(DateTime.now());
        for (final field in fields) {
          final keepLocal = choices[field['Field']] == ConflictSide.local;
          _history.insert({
            'Id': _history.nextId(),
            'Title': row['Title'],
            'Name': field['Name'],
            'NameBn': field['NameBn'],
            'Kind': field['Kind'],
            'Kept': keepLocal ? field['Local'] : field['Server'],
            'Discarded': keepLocal ? field['Server'] : field['Local'],
            'ResolvedAt': now,
          });
        }
        _conflicts.delete(conflictId);
      });

  @override
  Future<void> clearCache() => Future(() => _meta.update(1, {'CacheBytes': 0}));

  Map<String, dynamic> _snapshot() {
    final meta = _meta.byIdOrNull(1) ?? const <String, dynamic>{};
    return {
      'Outbox': _outbox.rows,
      'Conflicts': _conflicts.rows,
      'History': _history.rows,
      'DataBytes': meta['DataBytes'],
      'CacheBytes': meta['CacheBytes'],
      'LastSyncAt': meta['LastSyncAt'],
    };
  }
}
