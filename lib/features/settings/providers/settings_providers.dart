import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/data/config_repository.dart';
import 'package:salesroot/features/settings/data/settings_repositories.dart';
import 'package:salesroot/features/settings/models/device_session.dart';
import 'package:salesroot/features/settings/models/form_field_config.dart';
import 'package:salesroot/features/settings/models/notification_prefs.dart';
import 'package:salesroot/features/settings/models/pipeline.dart';

part 'settings_providers.g.dart';

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

/// The notification choices for the current workspace, kept on the phone.
@riverpod
class NotificationPrefsNotifier extends _$NotificationPrefsNotifier {
  String get _key =>
      'settings/notifications/${ref.read(currentWorkspaceProvider)?.id ?? ''}';

  @override
  NotificationPrefs build() {
    ref.watch(currentWorkspaceProvider.select((w) => w?.id));
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return saved == null
        ? NotificationPrefs.defaults
        : NotificationPrefs.fromJson(jsonMap(saved));
  }

  void save(NotificationPrefs next) {
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(next.toJson()));
    state = next;
  }
}

@riverpod
Future<List<DeviceSession>> devices(Ref ref) =>
    ref.watch(settingsRepositoryProvider).devices();

@riverpod
class PipelinesNotifier extends _$PipelinesNotifier {
  @override
  Future<List<Pipeline>> build() =>
      ref.watch(configRepositoryProvider).pipelines();

  ConfigRepository get _repo => ref.read(configRepositoryProvider);

  Future<void> addStage(String pipelineId, StageInput input) async {
    await _repo.addStage(pipelineId, input);
    await _reload();
  }

  Future<void> editStage(String stageId, StageInput input) async {
    await _repo.editStage(stageId, input);
    await _reload();
  }

  /// Moves the open stage at [from] to [to] at once, and rolls back if the
  /// server refuses.
  Future<void> moveStage(String pipelineId, int from, int to) async {
    final pipelines = state.value;
    if (pipelines == null) return;
    final pipeline = pipelines.firstWhere((p) => p.id == pipelineId);
    final open = [...pipeline.openStages];
    open.insert(to, open.removeAt(from));
    final moved = pipeline.withOpenOrder(open);
    _put(moved);
    try {
      await _repo.reorderStages([for (final s in moved.stages) s.id]);
    } on ApiFailure {
      if (ref.mounted) _put(pipeline);
      rethrow;
    }
  }

  Future<void> _reload() async {
    if (!ref.mounted) return;
    final pipelines = await _repo.pipelines();
    if (!ref.mounted) return;
    state = AsyncData(pipelines);
  }

  void _put(Pipeline pipeline) {
    final current = state.value ?? const <Pipeline>[];
    state = AsyncData([
      for (final p in current) p.id == pipeline.id ? pipeline : p,
    ]);
  }
}

@riverpod
Future<List<FormFieldConfig>> formFields(Ref ref, FormKind form) =>
    ref.watch(configRepositoryProvider).formFields(form);
