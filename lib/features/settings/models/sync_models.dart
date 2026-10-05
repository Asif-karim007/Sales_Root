import 'package:salesroot/core/utils/json_fields.dart';

/// A server table the phone can push changes to.
enum SyncEntity {
  lead('leads'),
  contact('contacts'),
  company('companies'),
  task('tasks'),
  activity('activities'),
  visit('visits'),
  expense('expenses'),
  other('');

  const SyncEntity(this.table);

  final String table;

  static SyncEntity fromTable(String? value) =>
      values.firstWhere((e) => e.table == value, orElse: () => other);
}

enum OutboxOperation {
  create('insert'),
  update('update'),
  delete('delete');

  const OutboxOperation(this.wire);

  final String wire;

  static OutboxOperation fromWire(String? value) => values.firstWhere(
    (o) => o.wire == value,
    orElse: () => OutboxOperation.update,
  );
}

/// The title a row shows by, whichever of its fields carries one.
String _titleOf(Map<String, dynamic> row) =>
    '${row['title'] ?? row['name'] ?? row['note'] ?? ''}';

/// A write saved on the phone that the server hasn't accepted yet: one
/// `SyncChange`.
class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.table,
    required this.operation,
    required this.row,
    this.baseUpdatedAt,
    this.createdAt,
    this.error,
  });

  final String id;
  final String table;
  final OutboxOperation operation;
  final Map<String, dynamic> row;

  /// The record's `updatedAt` as the server sent it before this edit; kept
  /// verbatim since the server compares it to the microsecond.
  final String? baseUpdatedAt;
  final DateTime? createdAt;

  /// The server's reason when the last attempt was rejected.
  final LocalizedName? error;

  SyncEntity get entity => SyncEntity.fromTable(table);
  String get title => _titleOf(row);
  String? get recordId => jsonId(row['id']);
  bool get failed => error != null;

  OutboxItem failedWith(LocalizedName reason) => OutboxItem(
    id: id,
    table: table,
    operation: operation,
    row: row,
    baseUpdatedAt: baseUpdatedAt,
    createdAt: createdAt,
    error: reason,
  );

  Map<String, dynamic> toChange() => {
    'table': table,
    'op': operation.wire,
    'row': row,
    'baseUpdatedAt': baseUpdatedAt,
  };

  factory OutboxItem.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    return OutboxItem(
      id: jsonId(json['id']) ?? '',
      table: json['table'] as String? ?? '',
      operation: OutboxOperation.fromWire(json['op'] as String?),
      row: jsonMap(json['row']),
      baseUpdatedAt: json['baseUpdatedAt'] as String?,
      createdAt: jsonDate(json['createdAt']),
      error: error == null ? null : LocalizedName.of(error),
    );
  }

  Map<String, dynamic> toJson() => {
    ...toChange(),
    'id': id,
    'createdAt': jsonUtc(createdAt),
    if (error case final error?) 'error': {'en': error.en, 'bn': error.bn},
  };
}

enum ConflictValueKind { money, date, text }

/// One version of a field: the value, and when it was set when known.
class ConflictVersion {
  const ConflictVersion({required this.value, this.at});

  final String value;
  final DateTime? at;
}

class ConflictField {
  const ConflictField({
    required this.field,
    required this.kind,
    required this.local,
    required this.server,
  });

  final String field;
  final ConflictValueKind kind;
  final ConflictVersion local;
  final ConflictVersion server;

  static const _money = {'amount', 'total', 'price', 'creditLimit', 'value'};

  static ConflictValueKind kindOf(String field) => _money.contains(field)
      ? ConflictValueKind.money
      : field.endsWith('At') || field.endsWith('Date') || field == 'birthday'
      ? ConflictValueKind.date
      : ConflictValueKind.text;
}

/// A record changed on the phone and on the server since the phone's copy:
/// the push answer's `{id, table, server, client}`.
class SyncConflict {
  const SyncConflict({
    required this.id,
    required this.table,
    required this.server,
    required this.client,
  });

  /// The record's id.
  final String id;
  final String table;

  /// The record as the server has it now.
  final Map<String, dynamic> server;

  /// The fields the phone sent.
  final Map<String, dynamic> client;

  SyncEntity get entity => SyncEntity.fromTable(table);
  String get title => _titleOf({...server, ...client});
  DateTime? get serverUpdatedAt => jsonDate(server['updatedAt']);

  /// The fields whose phone value differs from the server's.
  List<ConflictField> get fields => [
    for (final entry in client.entries)
      if (entry.key != 'id' && '${entry.value}' != '${server[entry.key]}')
        ConflictField(
          field: entry.key,
          kind: ConflictField.kindOf(entry.key),
          local: ConflictVersion(value: '${entry.value ?? ''}'),
          server: ConflictVersion(
            value: '${server[entry.key] ?? ''}',
            at: serverUpdatedAt,
          ),
        ),
  ];

  /// The row to push: the phone's fields, with each conflicting field's
  /// value taken from the side chosen for it.
  Map<String, dynamic> merged(Map<String, ConflictSide> choices) => {
    ...client,
    for (final field in fields)
      if (choices[field.field] == ConflictSide.server)
        field.field: server[field.field],
  };

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
    id: jsonId(json['id']) ?? '',
    table: json['table'] as String? ?? '',
    server: jsonMap(json['server']),
    client: jsonMap(json['client']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'server': server,
    'client': client,
  };
}

enum ConflictSide { local, server }

/// A resolved field: what was kept and what was dropped.
class ResolvedField {
  const ResolvedField({
    required this.title,
    required this.field,
    required this.kept,
    required this.discarded,
    this.resolvedAt,
  });

  final String title;
  final String field;
  final String kept;
  final String discarded;
  final DateTime? resolvedAt;

  ConflictValueKind get kind => ConflictField.kindOf(field);

  factory ResolvedField.fromJson(Map<String, dynamic> json) => ResolvedField(
    title: json['title'] as String? ?? '',
    field: json['field'] as String? ?? '',
    kept: '${json['kept'] ?? ''}',
    discarded: '${json['discarded'] ?? ''}',
    resolvedAt: jsonDate(json['resolvedAt']),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'field': field,
    'kept': kept,
    'discarded': discarded,
    'resolvedAt': jsonUtc(resolvedAt),
  };
}

/// The answer to `POST sync`: ids applied, conflicts and rejected rows.
class SyncPushResult {
  const SyncPushResult({
    required this.applied,
    required this.conflicts,
    required this.errors,
    this.nextSince,
    this.serverTime,
  });

  final Set<String> applied;
  final List<SyncConflict> conflicts;

  /// The reason each rejected record was turned down, by record id.
  final Map<String, LocalizedName> errors;
  final int? nextSince;
  final DateTime? serverTime;

  factory SyncPushResult.fromJson(Map<String, dynamic> json) => SyncPushResult(
    applied: jsonIds(json['applied']).toSet(),
    conflicts: jsonList(json['conflicts'], SyncConflict.fromJson),
    errors: {
      for (final e in jsonList(json['errors'], (e) => e))
        jsonId(e['id']) ?? '': LocalizedName.of(jsonMap(e['error'])['message']),
    },
    nextSince: jsonInt(json['nextSince']),
    serverTime: jsonDate(json['serverTime']),
  );
}

/// Everything the sync screen shows, as kept on the phone between syncs.
class SyncSnapshot {
  const SyncSnapshot({
    this.outbox = const [],
    this.conflicts = const [],
    this.history = const [],
    this.cursor,
    this.lastSyncAt,
    this.received = 0,
  });

  final List<OutboxItem> outbox;
  final List<SyncConflict> conflicts;
  final List<ResolvedField> history;

  /// The server version the phone has caught up to; null before the first
  /// sync.
  final int? cursor;
  final DateTime? lastSyncAt;

  /// Records changed elsewhere that the last sync brought in.
  final int received;

  int get pendingCount => outbox.length;
  int get failedCount => outbox.where((o) => o.failed).length;

  SyncConflict? conflict(String id) =>
      conflicts.where((c) => c.id == id).firstOrNull;

  /// Applies a push answer: applied writes leave the outbox, conflicting ones
  /// move to [conflicts] and rejected ones stay with the reason.
  SyncSnapshot afterPush(SyncPushResult result) {
    final conflicting = {for (final c in result.conflicts) c.id};
    return copyWith(
      outbox: [
        for (final item in outbox)
          if (!result.applied.contains(item.recordId) &&
              !conflicting.contains(item.recordId))
            switch (result.errors[item.recordId]) {
              final LocalizedName reason => item.failedWith(reason),
              null => item,
            },
      ],
      conflicts: [
        for (final c in conflicts)
          if (!conflicting.contains(c.id)) c,
        ...result.conflicts,
      ],
    );
  }

  SyncSnapshot copyWith({
    List<OutboxItem>? outbox,
    List<SyncConflict>? conflicts,
    List<ResolvedField>? history,
    int? cursor,
    DateTime? lastSyncAt,
    int? received,
  }) => SyncSnapshot(
    outbox: outbox ?? this.outbox,
    conflicts: conflicts ?? this.conflicts,
    history: history ?? this.history,
    cursor: cursor ?? this.cursor,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    received: received ?? this.received,
  );

  factory SyncSnapshot.fromJson(Map<String, dynamic> json) => SyncSnapshot(
    outbox: jsonList(json['outbox'], OutboxItem.fromJson),
    conflicts: jsonList(json['conflicts'], SyncConflict.fromJson),
    history: jsonList(json['history'], ResolvedField.fromJson),
    cursor: jsonInt(json['cursor']),
    lastSyncAt: jsonDate(json['lastSyncAt']),
    received: jsonInt(json['received']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'outbox': [for (final o in outbox) o.toJson()],
    'conflicts': [for (final c in conflicts) c.toJson()],
    'history': [for (final h in history) h.toJson()],
    'cursor': cursor,
    'lastSyncAt': jsonUtc(lastSyncAt),
    'received': received,
  };
}
