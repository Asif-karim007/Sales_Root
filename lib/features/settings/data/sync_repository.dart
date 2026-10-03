import 'package:salesroot/features/settings/models/sync_models.dart';

/// The phone's outbox of unsent writes, the conflicts the server found and
/// the offline cache.
abstract interface class SyncRepository {
  Future<SyncSnapshot> snapshot();

  /// Sends the outbox in order. Items the server rejects stay, with the
  /// reason.
  Future<SyncSnapshot> flush();

  /// Drops an unsent write.
  Future<void> discard(int outboxId);

  Future<SyncConflict> conflict(int id);

  /// Keeps one side per field; the other goes to the record's timeline.
  Future<void> resolve(int conflictId, Map<String, ConflictSide> choices);

  Future<void> clearCache();
}
