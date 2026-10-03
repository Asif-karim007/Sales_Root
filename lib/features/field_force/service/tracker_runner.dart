import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/debug_log.dart';
import 'package:salesroot/features/field_force/data/tracking_repository.dart';
import 'package:salesroot/features/field_force/models/tracker_ping.dart';
import 'package:salesroot/features/field_force/service/tracker_engine.dart';

/// Uploads straight to the repository, from the UI isolate.
class RepositoryPingUploader implements PingUploader {
  const RepositoryPingUploader(this._repository);

  final TrackingRepository _repository;

  @override
  Future<PingUploadResult?> upload(List<TrackerPing> batch) async {
    try {
      return await _repository.uploadPings(batch);
    } on ApiFailure catch (failure) {
      logDebug('Tracker: upload failed (${failure.statusCode})');
      return null;
    }
  }
}

/// Runs the capture loop in the UI isolate on iOS, where there is no
/// foreground service: a background-enabled location stream keeps the app
/// alive inside the window, and a timer takes the heartbeat.
///
/// What SaleBee's native plugin adds and this does not: relaunch after iOS
/// terminates the app (significant-change monitoring) and the cheap idle
/// profile between heartbeats.
class IosTrackerRunner {
  IosTrackerRunner({required this.engine, this.onChanged});

  TrackerEngine engine;
  final VoidCallback? onChanged;

  StreamSubscription<Position>? _positions;
  Timer? _timer;
  DateTime? _lastHeartbeat;

  bool get isRunning => _timer != null;
  bool get gpsOn => _positions != null;

  Future<void> start() async {
    if (isRunning) return;
    engine.resetMovementReference();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    await _tick();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _positions?.cancel();
    _positions = null;
  }

  Future<void> _tick() async {
    final now = DateTime.now();
    final inside = engine.config.isInsideWindow(now);
    if (inside && _positions == null) {
      _positions =
          Geolocator.getPositionStream(
            locationSettings: AppleSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: TrackerEngine.movementDistanceMeters.round(),
              pauseLocationUpdatesAutomatically: false,
              showBackgroundLocationIndicator: true,
              allowBackgroundLocationUpdates: true,
            ),
          ).listen((fix) async {
            if (await engine.captureMovement(fix) == CaptureSkip.none) {
              await engine.flush();
              onChanged?.call();
            }
          }, onError: (Object _) => _positions = null);
    } else if (!inside && _positions != null) {
      await _positions?.cancel();
      _positions = null;
    }
    final last = _lastHeartbeat;
    final due =
        last == null ||
        now.difference(last) >=
            engine.config.interval - const Duration(seconds: 5);
    if (inside && due) {
      await engine.captureHeartbeat(now);
      _lastHeartbeat = now;
    }
    await engine.flush();
    onChanged?.call();
  }
}
