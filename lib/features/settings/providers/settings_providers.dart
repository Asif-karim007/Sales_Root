import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/features/settings/data/config_repository.dart';
import 'package:salesroot/features/settings/data/fake_config_repository.dart';
import 'package:salesroot/features/settings/data/fake_settings_repository.dart';
import 'package:salesroot/features/settings/data/settings_repository.dart';
import 'package:salesroot/features/settings/models/device_session.dart';
import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/models/notification_prefs.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => FakeSettingsRepository(
  ref.watch(fakeBackendProvider),
  ref.watch(sharedPreferencesProvider),
);

@Riverpod(keepAlive: true)
ConfigRepository configRepository(Ref ref) =>
    FakeConfigRepository(ref.watch(fakeBackendProvider));

/// `2.0.0 (12)`.
@riverpod
Future<String> appVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}

/// Choices that stay on this phone.
class DevicePrefs {
  const DevicePrefs({
    this.readAloud = false,
    this.biometric = false,
    this.pinChangedAt,
  });

  final bool readAloud;
  final bool biometric;
  final DateTime? pinChangedAt;
}

@Riverpod(keepAlive: true)
class DevicePrefsNotifier extends _$DevicePrefsNotifier {
  static const _readAloudKey = 'settings/read_aloud';
  static const _biometricKey = 'settings/biometric';
  static const _pinChangedKey = 'settings/pin_changed_at';

  @override
  DevicePrefs build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return DevicePrefs(
      readAloud: prefs.getBool(_readAloudKey) ?? false,
      biometric: prefs.getBool(_biometricKey) ?? false,
      pinChangedAt: DateTime.tryParse(prefs.getString(_pinChangedKey) ?? ''),
    );
  }

  void setReadAloud(bool on) {
    ref.read(sharedPreferencesProvider).setBool(_readAloudKey, on);
    state = DevicePrefs(
      readAloud: on,
      biometric: state.biometric,
      pinChangedAt: state.pinChangedAt,
    );
  }

  void setBiometric(bool on) {
    ref.read(sharedPreferencesProvider).setBool(_biometricKey, on);
    state = DevicePrefs(
      readAloud: state.readAloud,
      biometric: on,
      pinChangedAt: state.pinChangedAt,
    );
  }

  void pinChanged(DateTime at) {
    ref
        .read(sharedPreferencesProvider)
        .setString(_pinChangedKey, at.toIso8601String());
    state = DevicePrefs(
      readAloud: state.readAloud,
      biometric: state.biometric,
      pinChangedAt: at,
    );
  }
}

@riverpod
class NotificationPrefsNotifier extends _$NotificationPrefsNotifier {
  @override
  Future<NotificationPrefs> build() =>
      ref.watch(settingsRepositoryProvider).notificationPrefs();

  /// Shows [next] at once and rolls back if the server refuses it.
  Future<void> save(NotificationPrefs next) async {
    final previous = state.value;
    state = AsyncData(next);
    try {
      final saved = await ref
          .read(settingsRepositoryProvider)
          .saveNotificationPrefs(next);
      if (!ref.mounted) return;
      state = AsyncData(saved);
    } on ApiFailure {
      if (ref.mounted && previous != null) state = AsyncData(previous);
      rethrow;
    }
  }
}

@riverpod
class DevicesNotifier extends _$DevicesNotifier {
  @override
  Future<List<DeviceSession>> build() =>
      ref.watch(settingsRepositoryProvider).devices();

  Future<void> remove(int id) async {
    await ref.read(settingsRepositoryProvider).removeDevice(id);
    if (!ref.mounted) return;
    final current = state.value ?? const <DeviceSession>[];
    state = AsyncData([
      for (final d in current)
        if (d.id != id) d,
    ]);
  }

  Future<void> signOutOthers() async {
    await ref.read(settingsRepositoryProvider).signOutOtherDevices();
    if (!ref.mounted) return;
    final current = state.value ?? const <DeviceSession>[];
    state = AsyncData([
      for (final d in current)
        if (d.isCurrent) d,
    ]);
  }
}

@riverpod
class LoginHistoryNotifier extends _$LoginHistoryNotifier {
  @override
  Future<Paged<LoginEvent>> build() async =>
      Paged.first(await ref.watch(settingsRepositoryProvider).loginHistory(1));

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(settingsRepositoryProvider)
          .loginHistory(current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }
}

@riverpod
class PipelinesNotifier extends _$PipelinesNotifier {
  @override
  Future<List<Pipeline>> build() =>
      ref.watch(configRepositoryProvider).pipelines();

  ConfigRepository get _repo => ref.read(configRepositoryProvider);

  Future<void> addStage(int pipelineId, StageInput input) =>
      _apply(_repo.addStage(pipelineId, input));

  Future<void> editStage(int pipelineId, int stageId, StageInput input) =>
      _apply(_repo.editStage(pipelineId, stageId, input));

  Future<void> deleteStage(int pipelineId, int stageId) =>
      _apply(_repo.deleteStage(pipelineId, stageId));

  /// Moves the open stage at [from] to [to] at once, and rolls back if the
  /// server refuses.
  Future<void> moveStage(int pipelineId, int from, int to) async {
    final pipelines = state.value;
    if (pipelines == null) return;
    final pipeline = pipelines.firstWhere((p) => p.id == pipelineId);
    final open = [...pipeline.openStages];
    final moved = open.removeAt(from);
    open.insert(to, moved);
    _put(
      Pipeline(
        id: pipeline.id,
        name: pipeline.name,
        isDefault: pipeline.isDefault,
        stages: [...open, ...pipeline.stages.where((s) => !s.isOpen)],
      ),
    );
    try {
      await _apply(
        _repo.reorderStages(pipelineId, [for (final s in open) s.id]),
      );
    } on ApiFailure {
      if (ref.mounted) _put(pipeline);
      rethrow;
    }
  }

  Future<void> _apply(Future<Pipeline> request) async {
    final pipeline = await request;
    if (!ref.mounted) return;
    _put(pipeline);
  }

  void _put(Pipeline pipeline) {
    final current = state.value ?? const <Pipeline>[];
    state = AsyncData([
      for (final p in current) p.id == pipeline.id ? pipeline : p,
    ]);
  }
}

@riverpod
class FormFieldsNotifier extends _$FormFieldsNotifier {
  @override
  Future<List<FormFieldConfig>> build(FormKind form) =>
      ref.watch(configRepositoryProvider).formFields(form);

  Future<void> save(int id, FormFieldInput input) async {
    final saved = await ref
        .read(configRepositoryProvider)
        .saveFormField(id, input);
    if (!ref.mounted) return;
    final current = state.value ?? const <FormFieldConfig>[];
    state = AsyncData([for (final f in current) f.id == id ? saved : f]);
  }
}
