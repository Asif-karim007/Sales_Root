import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:salesroot/features/field_force/models/tracker_config.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';

/// Tracker state that both the UI and the foreground-service isolate read.
/// `FlutterForegroundTask` data is shared across isolates, unlike
/// shared_preferences.
abstract final class TrackerPrefs {
  static const _state = 'tracker.state';
  static const _consentAt = 'tracker.consentAt';
  static const _wasActive = 'tracker.wasActive';
  static const _config = 'tracker.config';
  static const _lastUploadAt = 'tracker.lastUploadAt';
  static const _lastCaptureAt = 'tracker.lastCaptureAt';
  static const _bufferedCount = 'tracker.bufferedCount';
  static const _stoppedAt = 'tracker.stoppedAt';
  static const _pausedAt = 'tracker.pausedAt';

  static Future<TrackerState> state() async => TrackerState.fromWire(
    await FlutterForegroundTask.getData<String>(key: _state),
  );

  static Future<void> setState(TrackerState state) =>
      FlutterForegroundTask.saveData(key: _state, value: state.name);

  static Future<DateTime?> consentAt() => _readTime(_consentAt);

  static Future<void> setConsentAt(DateTime? at) => at == null
      ? FlutterForegroundTask.removeData(key: _consentAt)
      : _writeTime(_consentAt, at);

  static Future<bool> wasActive() async =>
      await FlutterForegroundTask.getData<bool>(key: _wasActive) ?? false;

  static Future<void> setWasActive(bool value) =>
      FlutterForegroundTask.saveData(key: _wasActive, value: value);

  static Future<TrackerConfig> config() async {
    final raw = await FlutterForegroundTask.getData<String>(key: _config);
    if (raw == null || raw.isEmpty) return TrackerConfig.disabled;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic>
        ? TrackerConfig.fromJson(decoded)
        : TrackerConfig.disabled;
  }

  static Future<void> setConfig(TrackerConfig config) =>
      FlutterForegroundTask.saveData(
        key: _config,
        value: jsonEncode(config.toJson()),
      );

  static Future<DateTime?> lastUploadAt() => _readTime(_lastUploadAt);
  static Future<void> setLastUploadAt(DateTime at) =>
      _writeTime(_lastUploadAt, at);

  static Future<DateTime?> lastCaptureAt() => _readTime(_lastCaptureAt);
  static Future<void> setLastCaptureAt(DateTime at) =>
      _writeTime(_lastCaptureAt, at);

  /// When tracking stopped without the member asking: the help screen
  /// says "stopped at 11:42".
  static Future<DateTime?> stoppedAt() => _readTime(_stoppedAt);
  static Future<void> setStoppedAt(DateTime? at) => at == null
      ? FlutterForegroundTask.removeData(key: _stoppedAt)
      : _writeTime(_stoppedAt, at);

  static Future<DateTime?> pausedAt() => _readTime(_pausedAt);
  static Future<void> setPausedAt(DateTime? at) => at == null
      ? FlutterForegroundTask.removeData(key: _pausedAt)
      : _writeTime(_pausedAt, at);

  static Future<int> bufferedCount() async =>
      await FlutterForegroundTask.getData<int>(key: _bufferedCount) ?? 0;

  static Future<void> setBufferedCount(int value) =>
      FlutterForegroundTask.saveData(key: _bufferedCount, value: value);

  static Future<DateTime?> _readTime(String key) async {
    final raw = await FlutterForegroundTask.getData<String>(key: key);
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  static Future<void> _writeTime(String key, DateTime value) =>
      FlutterForegroundTask.saveData(
        key: key,
        value: value.toUtc().toIso8601String(),
      );
}
