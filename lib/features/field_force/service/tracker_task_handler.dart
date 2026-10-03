import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'package:salesroot/features/field_force/data/tracker_db.dart';
import 'package:salesroot/features/field_force/data/tracker_prefs.dart';
import 'package:salesroot/features/field_force/data/tracking_repository.dart';
import 'package:salesroot/features/field_force/models/tracker_config.dart';
import 'package:salesroot/features/field_force/models/tracker_ping.dart';
import 'package:salesroot/features/field_force/service/motion_detector.dart';
import 'package:salesroot/features/field_force/service/tracker_engine.dart';
import 'package:salesroot/features/field_force/service/tracker_messages.dart';

/// Entry point of the Android foreground-service isolate.
@pragma('vm:entry-point')
void startTrackerCallback() {
  FlutterForegroundTask.setTaskHandler(TrackerTaskHandler());
}

/// Hosts both loops inside the Android foreground service: a heartbeat on
/// every tick, movement points while the motion detector says moving, and a
/// flush after each capture. It owns the ping buffer while it runs.
class TrackerTaskHandler extends TaskHandler {
  static const tickInterval = Duration(minutes: 1);

  final _motion = MotionDetector();
  final _uploader = RelayPingUploader();
  TrackerEngine? _engine;
  TrackerConfig _config = TrackerConfig.disabled;
  StreamSubscription<bool>? _motionChanges;
  StreamSubscription<Position>? _positions;
  DateTime? _lastHeartbeatAt;
  bool _ticking = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    WidgetsFlutterBinding.ensureInitialized();
    _config = await TrackerPrefs.config();
    _lastHeartbeatAt = await TrackerPrefs.lastCaptureAt();
    final engine = TrackerEngine(uploader: _uploader, config: _config);
    _engine = engine;
    await TrackerPrefs.setWasActive(true);
    engine.resetMovementReference();
    _motionChanges = _motion.changes.listen((_) => _applyMode());
    _motion.start();
    await _applyMode();
    unawaited(_flush());
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    final engine = _engine;
    if (engine == null || _ticking) return;
    _ticking = true;
    try {
      final now = DateTime.now();
      await _applyMode();
      final last = _lastHeartbeatAt;
      final due =
          last == null ||
          now.difference(last) >= _config.interval - const Duration(seconds: 5);
      if (_config.isInsideWindow(now) && due) {
        final skip = await engine.captureHeartbeat(now);
        if (skip != CaptureSkip.outsideWindow) _lastHeartbeatAt = now;
      }
      await _flush();
      await _sendStatus();
    } finally {
      _ticking = false;
    }
  }

  Future<void> _applyMode() async {
    final stream = _config.isInsideWindow(DateTime.now()) && _motion.isMoving;
    if (stream && _positions == null) {
      _positions =
          Geolocator.getPositionStream(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: TrackerEngine.movementDistanceMeters.round(),
            ),
          ).listen(
            _onMovementFix,
            onError: (Object _) {
              _positions = null;
            },
          );
    } else if (!stream && _positions != null) {
      await _positions?.cancel();
      _positions = null;
    }
  }

  Future<void> _onMovementFix(Position fix) async {
    final engine = _engine;
    if (engine == null) return;
    if (await engine.captureMovement(fix) == CaptureSkip.none) {
      await _flush();
      await _sendStatus();
    }
  }

  Future<void> _flush({bool force = false}) async {
    await _engine?.flush(force: force);
  }

  Future<void> _sendStatus() async {
    FlutterForegroundTask.sendDataToMain(
      TrackerMessages.statusOf(
        buffered: await TrackerPrefs.bufferedCount(),
        insideWindow: _config.isInsideWindow(DateTime.now()),
        moving: _motion.isMoving,
        gpsOn: _positions != null,
        lastCaptureAt: _lastHeartbeatAt,
        lastUploadAt: await TrackerPrefs.lastUploadAt(),
      ),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    switch (data['command']) {
      case TrackerCommands.flushNow:
        unawaited(_flush(force: true).then((_) => _sendStatus()));
      case TrackerCommands.requestStatus:
        unawaited(_sendStatus());
      case TrackerCommands.uploadAck:
        _uploader.acknowledge(data);
      case TrackerCommands.config:
        final json = data['config'];
        if (json is Map) {
          _config = TrackerConfig.fromJson(Map<String, dynamic>.from(json));
          _engine?.config = _config;
          unawaited(_applyMode());
        }
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _motionChanges?.cancel();
    await _motion.dispose();
    await _positions?.cancel();
    _positions = null;
    _uploader.close();
    await TrackerDb.instance.close();
    FlutterForegroundTask.sendDataToMain(TrackerMessages.stoppedNow());
  }
}

/// Hands each batch to the UI isolate and waits for its acknowledgement.
/// With the app closed nothing answers, the batch times out and stays in the
/// buffer until the app is opened again.
class RelayPingUploader implements PingUploader {
  static const _timeout = Duration(seconds: 30);

  final _pending = <int, Completer<PingUploadResult?>>{};
  var _nextId = 1;

  @override
  Future<PingUploadResult?> upload(List<TrackerPing> batch) async {
    final id = _nextId++;
    final completer = Completer<PingUploadResult?>();
    _pending[id] = completer;
    FlutterForegroundTask.sendDataToMain(
      TrackerMessages.uploadRequest(id, [for (final p in batch) p.toDb()]),
    );
    try {
      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } finally {
      _pending.remove(id);
    }
  }

  void acknowledge(Map<Object?, Object?> data) {
    final completer = _pending[data.intOr('requestId', -1)];
    if (completer == null || completer.isCompleted) return;
    final delivered = data.boolOr('delivered', false);
    completer.complete(
      delivered
          ? PingUploadResult(accepted: 0, rejected: data.intOr('rejected', 0))
          : null,
    );
  }

  void close() {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.complete(null);
    }
    _pending.clear();
  }
}
