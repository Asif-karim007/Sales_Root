import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/settings/data/settings_api.dart';
import 'package:salesroot/features/settings/data/sync_repository.dart';
import 'package:salesroot/features/settings/data/sync_store.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';

class ApiSyncRepository implements SyncRepository {
  ApiSyncRepository(this._api, this._store, {required this.bangla});

  final SettingsApi _api;
  final SyncStore _store;

  /// Whether server messages are shown in Bangla.
  final bool Function() bangla;

  @override
  Future<SyncSnapshot> snapshot() async => _store.read();

  /// Before the first sync there is nothing to catch up on: the push answer
  /// gives the cursor to start from.
  @override
  Future<SyncSnapshot> flush() async {
    final before = _store.read();
    final pushed = await _push([for (final o in before.outbox) o.toChange()]);
    final since = before.cursor;
    final next = since == null
        ? before
              .afterPush(pushed)
              .copyWith(
                cursor: pushed.nextSince,
                lastSyncAt: pushed.serverTime,
                received: 0,
              )
        : await _pull(before.afterPush(pushed), since);
    await _store.write(next);
    return next;
  }

  @override
  Future<void> discard(String outboxId) {
    final current = _store.read();
    return _store.write(
      current.copyWith(
        outbox: [
          for (final item in current.outbox)
            if (item.id != outboxId) item,
        ],
      ),
    );
  }

  @override
  Future<SyncConflict> conflict(String id) async =>
      _store.read().conflict(id) ??
      (throw const ApiFailure(404, 'Conflict not found'));

  @override
  Future<void> resolve(
    String conflictId,
    Map<String, ConflictSide> choices,
  ) async {
    final conflict = await this.conflict(conflictId);
    final result = await _push([
      {
        'table': conflict.table,
        'op': OutboxOperation.update.wire,
        'row': conflict.merged(choices),
        'baseUpdatedAt': conflict.server['updatedAt'],
      },
    ]);
    final current = _store.read();
    if (result.conflicts.any((c) => c.id == conflictId)) {
      await _store.write(current.afterPush(result));
      throw const ApiFailure(409, '');
    }
    final error = result.errors[conflictId];
    if (error != null) throw ApiFailure(422, error.of(bangla()));
    await _store.write(
      current.copyWith(
        conflicts: [
          for (final c in current.conflicts)
            if (c.id != conflictId) c,
        ],
        history: [
          for (final field in conflict.fields)
            _resolved(conflict, field, choices[field.field], result.serverTime),
          ...current.history,
        ],
      ),
    );
  }

  static ResolvedField _resolved(
    SyncConflict conflict,
    ConflictField field,
    ConflictSide? side,
    DateTime? at,
  ) {
    final server = side == ConflictSide.server;
    return ResolvedField(
      title: conflict.title,
      field: field.field,
      kept: server ? field.server.value : field.local.value,
      discarded: server ? field.local.value : field.server.value,
      resolvedAt: at,
    );
  }

  Future<SyncPushResult> _push(List<Map<String, dynamic>> changes) async {
    final json = await apiRequest(
      'Sync push',
      () => _api.push({
        'deviceId': _store.deviceId,
        'changes': changes,
        'clientTime': jsonUtc(DateTime.now()),
      }),
    );
    return SyncPushResult.fromJson(jsonMap(json));
  }

  Future<SyncSnapshot> _pull(SyncSnapshot snapshot, int since) async {
    var cursor = since;
    var received = 0;
    DateTime? at;
    while (true) {
      final from = cursor;
      final json = jsonMap(
        await apiRequest(
          'Sync pull',
          () => _api.pull({'since': from, 'deviceId': _store.deviceId}),
        ),
      );
      for (final rows in jsonMap(json['tables']).values) {
        if (rows is List) received += rows.length;
      }
      cursor = jsonInt(json['nextSince']) ?? cursor;
      at = jsonDate(json['serverTime']) ?? at;
      if (!jsonBool(json['hasMore']) || cursor == from) break;
    }
    return snapshot.copyWith(
      cursor: cursor,
      lastSyncAt: at,
      received: received,
    );
  }
}
