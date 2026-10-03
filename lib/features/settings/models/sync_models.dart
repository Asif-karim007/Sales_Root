import 'package:salesroot/core/utils/json_fields.dart';

const megabyte = 1024 * 1024;

enum OutboxOperation {
  create('Create'),
  update('Update'),
  delete('Delete');

  const OutboxOperation(this.wire);

  final String wire;

  static OutboxOperation fromWire(String? value) => values.firstWhere(
    (o) => o.wire == value,
    orElse: () => OutboxOperation.update,
  );
}

enum SyncEntity {
  lead('Lead'),
  contact('Contact'),
  task('Task'),
  callLog('CallLog'),
  note('Note'),
  visit('Visit'),
  expense('Expense');

  const SyncEntity(this.wire);

  final String wire;

  static SyncEntity fromWire(String? value) =>
      values.firstWhere((e) => e.wire == value, orElse: () => SyncEntity.lead);
}

/// A write saved on the phone that the server hasn't accepted yet.
class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.entity,
    required this.title,
    required this.operation,
    this.createdAt,
    this.error,
  });

  final int id;
  final SyncEntity entity;
  final String title;
  final OutboxOperation operation;
  final DateTime? createdAt;

  /// The server's reason when the last attempt was rejected.
  final String? error;

  bool get failed => error != null;

  factory OutboxItem.fromJson(Map<String, dynamic> json) => OutboxItem(
    id: jsonInt(json['Id']) ?? 0,
    entity: SyncEntity.fromWire(json['Entity'] as String?),
    title: json['Title'] as String? ?? '',
    operation: OutboxOperation.fromWire(json['Operation'] as String?),
    createdAt: jsonDate(json['CreatedAt']),
    error: json['Error'] as String?,
  );
}

enum ConflictValueKind {
  money('Money'),
  text('Text'),
  stage('Stage'),
  date('Date');

  const ConflictValueKind(this.wire);

  final String wire;

  static ConflictValueKind fromWire(String? value) => values.firstWhere(
    (k) => k.wire == value,
    orElse: () => ConflictValueKind.text,
  );
}

/// One version of a field: the value, when it was set and by whom. Values
/// that are ids, like a stage, come with their [label].
class ConflictVersion {
  const ConflictVersion({
    required this.value,
    required this.by,
    this.at,
    this.label,
  });

  final String value;
  final String by;
  final DateTime? at;
  final LocalizedName? label;

  factory ConflictVersion.fromJson(Map<String, dynamic> json) =>
      ConflictVersion(
        value: '${json['Value'] ?? ''}',
        by: json['By'] as String? ?? '',
        at: jsonDate(json['At']),
        label: json['Name'] == null ? null : LocalizedName.fromJson(json),
      );

  Map<String, dynamic> toJson() => {
    'Value': value,
    'By': by,
    'At': jsonUtc(at),
    'Name': label?.en,
    'NameBn': label?.bn,
  }..removeWhere((_, v) => v == null);
}

class ConflictField {
  const ConflictField({
    required this.field,
    required this.label,
    required this.kind,
    required this.local,
    required this.server,
  });

  final String field;
  final LocalizedName label;
  final ConflictValueKind kind;
  final ConflictVersion local;
  final ConflictVersion server;

  factory ConflictField.fromJson(Map<String, dynamic> json) => ConflictField(
    field: json['Field'] as String? ?? '',
    label: LocalizedName.fromJson(json),
    kind: ConflictValueKind.fromWire(json['Kind'] as String?),
    local: jsonObject(json['Local'], ConflictVersion.fromJson) ?? _blank,
    server: jsonObject(json['Server'], ConflictVersion.fromJson) ?? _blank,
  );

  static const _blank = ConflictVersion(value: '', by: '');
}

/// A record changed on the phone and on the server since the last sync.
class SyncConflict {
  const SyncConflict({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.title,
    required this.fields,
  });

  final int id;
  final SyncEntity entity;
  final int entityId;
  final String title;
  final List<ConflictField> fields;

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
    id: jsonInt(json['Id']) ?? 0,
    entity: SyncEntity.fromWire(json['Entity'] as String?),
    entityId: jsonInt(json['EntityId']) ?? 0,
    title: json['Title'] as String? ?? '',
    fields: jsonList(json['Fields'], ConflictField.fromJson),
  );
}

enum ConflictSide {
  local('Local'),
  server('Server');

  const ConflictSide(this.wire);

  final String wire;
}

/// A resolved field: what was kept, and what went to the timeline.
class ResolvedField {
  const ResolvedField({
    required this.id,
    required this.title,
    required this.label,
    required this.kind,
    required this.kept,
    required this.discarded,
    this.resolvedAt,
  });

  final int id;
  final String title;
  final LocalizedName label;
  final ConflictValueKind kind;
  final ConflictVersion kept;
  final ConflictVersion discarded;
  final DateTime? resolvedAt;

  factory ResolvedField.fromJson(Map<String, dynamic> json) => ResolvedField(
    id: jsonInt(json['Id']) ?? 0,
    title: json['Title'] as String? ?? '',
    label: LocalizedName.fromJson(json),
    kind: ConflictValueKind.fromWire(json['Kind'] as String?),
    kept:
        jsonObject(json['Kept'], ConflictVersion.fromJson) ??
        ConflictField._blank,
    discarded:
        jsonObject(json['Discarded'], ConflictVersion.fromJson) ??
        ConflictField._blank,
    resolvedAt: jsonDate(json['ResolvedAt']),
  );
}

/// Everything the sync screen shows.
class SyncSnapshot {
  const SyncSnapshot({
    required this.outbox,
    required this.conflicts,
    required this.history,
    required this.dataBytes,
    required this.cacheBytes,
    this.lastSyncAt,
  });

  final List<OutboxItem> outbox;
  final List<SyncConflict> conflicts;
  final List<ResolvedField> history;
  final int dataBytes;
  final int cacheBytes;
  final DateTime? lastSyncAt;

  int get pendingCount => outbox.length;
  int get failedCount => outbox.where((o) => o.failed).length;

  factory SyncSnapshot.fromJson(Map<String, dynamic> json) => SyncSnapshot(
    outbox: jsonList(json['Outbox'], OutboxItem.fromJson),
    conflicts: jsonList(json['Conflicts'], SyncConflict.fromJson),
    history: jsonList(json['History'], ResolvedField.fromJson),
    dataBytes: jsonInt(json['DataBytes']) ?? 0,
    cacheBytes: jsonInt(json['CacheBytes']) ?? 0,
    lastSyncAt: jsonDate(json['LastSyncAt']),
  );
}
