import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';

/// What sync keeps on the phone for one workspace, and the id the server
/// knows this install by.
class SyncStore {
  SyncStore(this._prefs, this._workspaceId);

  final SharedPreferences _prefs;
  final String _workspaceId;

  static const _deviceKey = 'sync/device_id';

  String get _key => 'sync/state/$_workspaceId';

  String get deviceId {
    final saved = _prefs.getString(_deviceKey);
    if (saved != null) return saved;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    _prefs.setString(_deviceKey, id);
    return id;
  }

  SyncSnapshot read() =>
      SyncSnapshot.fromJson(jsonMap(_prefs.getString(_key) ?? ''));

  Future<void> write(SyncSnapshot snapshot) =>
      _prefs.setString(_key, jsonEncode(snapshot.toJson()));

  /// Queues a write made while the server could not be reached.
  Future<void> enqueue(OutboxItem item) {
    final current = read();
    return write(current.copyWith(outbox: [...current.outbox, item]));
  }
}
