import 'package:salesroot/features/settings/models/sync_models.dart';

/// The phone's outbox of unsent writes, the conflicts the server found and
/// the pull cursor.
abstract interface class SyncRepository {
  Future<SyncSnapshot> snapshot();

  /// Sends the outbox in order and pulls what changed elsewhere. Items the
  /// server rejects stay, with the reason.
  Future<SyncSnapshot> flush();

  /// Drops an unsent write.
  Future<void> discard(String outboxId);

  Future<SyncConflict> conflict(String id);

  /// Pushes the record again with one side kept per field.
  Future<void> resolve(String conflictId, Map<String, ConflictSide> choices);
}
