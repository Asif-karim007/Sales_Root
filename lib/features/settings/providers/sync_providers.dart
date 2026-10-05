import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/features/settings/data/settings_repositories.dart';
import 'package:salesroot/features/settings/data/sync_repository.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';

part 'sync_providers.g.dart';

@riverpod
class SyncNotifier extends _$SyncNotifier {
  @override
  Future<SyncSnapshot> build() => ref.watch(syncRepositoryProvider).snapshot();

  SyncRepository get _repo => ref.read(syncRepositoryProvider);

  Future<void> syncNow() async {
    final snapshot = await _repo.flush();
    if (!ref.mounted) return;
    state = AsyncData(snapshot);
  }

  Future<void> discard(String outboxId) async {
    await _repo.discard(outboxId);
    await _reload();
  }

  /// Reloads also when the server finds the record changed again, so the
  /// new conflict shows.
  Future<void> resolve(
    String conflictId,
    Map<String, ConflictSide> choices,
  ) async {
    try {
      await _repo.resolve(conflictId, choices);
    } finally {
      await _reload();
    }
  }

  Future<void> _reload() async {
    if (!ref.mounted) return;
    final snapshot = await _repo.snapshot();
    if (!ref.mounted) return;
    state = AsyncData(snapshot);
  }
}

@riverpod
Future<SyncConflict> syncConflict(Ref ref, String id) =>
    ref.watch(syncRepositoryProvider).conflict(id);

/// The side picked for each field of conflict [id], keyed by field.
@riverpod
class ConflictChoicesNotifier extends _$ConflictChoicesNotifier {
  @override
  Map<String, ConflictSide> build(String id) => const {};

  void choose(String field, ConflictSide side) =>
      state = {...state, field: side};
}

class SyncPrefs {
  const SyncPrefs({
    this.historyDays = 90,
    this.offlineMedia = false,
    this.mediaOnWifiOnly = true,
  });

  static const historyChoices = [30, 90, 365];

  final int historyDays;
  final bool offlineMedia;
  final bool mediaOnWifiOnly;

  SyncPrefs copyWith({
    int? historyDays,
    bool? offlineMedia,
    bool? mediaOnWifiOnly,
  }) => SyncPrefs(
    historyDays: historyDays ?? this.historyDays,
    offlineMedia: offlineMedia ?? this.offlineMedia,
    mediaOnWifiOnly: mediaOnWifiOnly ?? this.mediaOnWifiOnly,
  );
}

@Riverpod(keepAlive: true)
class SyncPrefsNotifier extends _$SyncPrefsNotifier {
  static const _historyKey = 'sync/history_days';
  static const _mediaKey = 'sync/offline_media';
  static const _wifiKey = 'sync/media_wifi_only';

  @override
  SyncPrefs build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SyncPrefs(
      historyDays: prefs.getInt(_historyKey) ?? 90,
      offlineMedia: prefs.getBool(_mediaKey) ?? false,
      mediaOnWifiOnly: prefs.getBool(_wifiKey) ?? true,
    );
  }

  void setHistoryDays(int days) {
    ref.read(sharedPreferencesProvider).setInt(_historyKey, days);
    state = state.copyWith(historyDays: days);
  }

  void setOfflineMedia(bool on) {
    ref.read(sharedPreferencesProvider).setBool(_mediaKey, on);
    state = state.copyWith(offlineMedia: on);
  }

  void setMediaOnWifiOnly(bool on) {
    ref.read(sharedPreferencesProvider).setBool(_wifiKey, on);
    state = state.copyWith(mediaOnWifiOnly: on);
  }
}

/// The phone's network links, now and as they change.
@riverpod
Stream<List<ConnectivityResult>> connectivity(Ref ref) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
}
