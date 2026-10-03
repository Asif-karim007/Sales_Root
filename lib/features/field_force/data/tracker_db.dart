import 'package:sqflite/sqflite.dart';

import 'package:salesroot/features/field_force/models/tracker_ping.dart';

/// The tracker's ping buffer. Plain sqflite, owned by exactly one isolate at
/// a time: the foreground service while it runs on Android, the UI otherwise.
class TrackerDb {
  TrackerDb._();

  static final instance = TrackerDb._();

  static const _name = 'salesroot_tracker.db';
  static const _version = 1;

  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;
    final directory = await getDatabasesPath();
    final opened = await openDatabase(
      '$directory/$_name',
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${TrackerPing.table} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            locationTimeUtc TEXT NOT NULL,
            locationText TEXT,
            battery INTEGER,
            createdAt TEXT NOT NULL,
            kind TEXT NOT NULL DEFAULT 'heartbeat'
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_tracker_pings_time '
          'ON ${TrackerPing.table} (locationTimeUtc)',
        );
      },
    );
    return _db = opened;
  }

  Future<void> close() async {
    final existing = _db;
    _db = null;
    if (existing != null && existing.isOpen) await existing.close();
  }

  Future<int> insert(TrackerPing ping) async =>
      (await _database).insert(TrackerPing.table, ping.toDb());

  Future<List<TrackerPing>> oldest({int limit = 500}) async {
    final rows = await (await _database).query(
      TrackerPing.table,
      orderBy: 'locationTimeUtc ASC, id ASC',
      limit: limit,
    );
    return [for (final row in rows) TrackerPing.fromDb(row)];
  }

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final marks = List.filled(ids.length, '?').join(',');
    await (await _database).delete(
      TrackerPing.table,
      where: 'id IN ($marks)',
      whereArgs: ids,
    );
  }

  Future<int> count() async {
    final rows = await (await _database).rawQuery(
      'SELECT COUNT(*) AS c FROM ${TrackerPing.table}',
    );
    if (rows.isEmpty) return 0;
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }
}
