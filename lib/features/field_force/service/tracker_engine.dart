import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:salesroot/core/utils/debug_log.dart';
import 'package:salesroot/features/field_force/data/tracker_db.dart';
import 'package:salesroot/features/field_force/data/tracker_prefs.dart';
import 'package:salesroot/features/field_force/data/tracking_repository.dart';
import 'package:salesroot/features/field_force/models/tracker_config.dart';
import 'package:salesroot/features/field_force/models/tracker_ping.dart';
import 'package:salesroot/features/field_force/service/geo.dart';

/// Delivers a batch of buffered pings. Returns null when the batch could not
/// be delivered now; the buffer is then kept for a later flush.
abstract interface class PingUploader {
  Future<PingUploadResult?> upload(List<TrackerPing> batch);
}

enum CaptureSkip {
  none,
  outsideWindow,
  noFix,
  invalidCoordinate,
  poorAccuracy,
  tooClose,
}

enum FlushOutcome { idle, uploaded, retryLater }

/// The capture and flush loops, with no dependency on the UI or Riverpod, so
/// the foreground-service isolate can run them too.
///
/// Capture is gated by the duty window; flush never is. Every capture lands
/// in [TrackerDb] first and never fails; uploading is best-effort on top.
class TrackerEngine {
  TrackerEngine({required this.uploader, required this.config, TrackerDb? db})
    : db = db ?? TrackerDb.instance;

  final PingUploader uploader;
  final TrackerDb db;
  TrackerConfig config;

  /// A movement fix worse than this puts the member on the wrong street.
  static const double movementAccuracyMeters = 40;
  static const double movementDistanceMeters = 15;

  /// A heartbeat only answers "alive and roughly where".
  static const double heartbeatAccuracyMeters = 100;
  static const int maxBatch = 500;
  static const _minBackoff = Duration(seconds: 30);
  static const _maxBackoff = Duration(minutes: 5);

  final _battery = Battery();
  bool _flushing = false;
  Duration _backoff = _minBackoff;
  DateTime? _notBefore;
  double? _lastLat;
  double? _lastLng;

  void resetMovementReference() {
    _lastLat = null;
    _lastLng = null;
  }

  Future<CaptureSkip> captureMovement(Position fix) => _capture(
    latitude: fix.latitude,
    longitude: fix.longitude,
    accuracy: fix.accuracy,
    fixTime: fix.timestamp,
    kind: TrackerPingKind.movement,
  );

  /// One fix every `DurationInMinute`, moving or not, so the server can
  /// tell "parked" from "the app was killed".
  Future<CaptureSkip> captureHeartbeat(DateTime now) async {
    if (!config.isInsideWindow(now)) return CaptureSkip.outsideWindow;
    final fix = await _bestFix();
    if (fix == null) return CaptureSkip.noFix;
    return _capture(
      latitude: fix.latitude,
      longitude: fix.longitude,
      accuracy: fix.accuracy,
      fixTime: fix.timestamp,
      kind: TrackerPingKind.heartbeat,
    );
  }

  Future<CaptureSkip> _capture({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime fixTime,
    required TrackerPingKind kind,
  }) async {
    final now = DateTime.now();
    if (!config.isInsideWindow(now)) return CaptureSkip.outsideWindow;
    if (!TrackerPing.isValidCoordinate(latitude, longitude)) {
      return CaptureSkip.invalidCoordinate;
    }
    final movement = kind == TrackerPingKind.movement;
    final limit = movement ? movementAccuracyMeters : heartbeatAccuracyMeters;
    if (accuracy <= 0 || accuracy > limit) return CaptureSkip.poorAccuracy;
    final lastLat = _lastLat;
    final lastLng = _lastLng;
    if (movement &&
        lastLat != null &&
        lastLng != null &&
        distanceMetres(lastLat, lastLng, latitude, longitude) <
            movementDistanceMeters) {
      return CaptureSkip.tooClose;
    }
    await db.insert(
      TrackerPing(
        latitude: latitude,
        longitude: longitude,
        locationTimeUtc: _validTime(fixTime, now).toUtc(),
        createdAt: now.toUtc(),
        battery: await _batteryLevel(),
        locationText: movement ? null : await _placeName(latitude, longitude),
        kind: kind,
      ),
    );
    _lastLat = latitude;
    _lastLng = longitude;
    await TrackerPrefs.setLastCaptureAt(now);
    await publishCount();
    return CaptureSkip.none;
  }

  Future<Position?> _bestFix() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } on TimeoutException {
      return Geolocator.getLastKnownPosition();
    } on Exception catch (error) {
      logDebug('Tracker: no fix ($error)');
      return null;
    }
  }

  DateTime _validTime(DateTime fixTime, DateTime now) {
    if (fixTime.year < 2015) return now;
    if (fixTime.isAfter(now.add(const Duration(minutes: 5)))) return now;
    return fixTime;
  }

  Future<int?> _batteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } on Exception {
      return null;
    }
  }

  /// Heartbeats only: one lookup per 15 m would rate-limit the geocoder.
  Future<String?> _placeName(double latitude, double longitude) async {
    try {
      final places = await Geocoding()
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 8));
      if (places.isEmpty) return null;
      final place = places.first;
      final text = [
        for (final part in [place.street, place.subLocality, place.locality])
          if (part != null && part.isNotEmpty) part,
      ].join(', ');
      if (text.isEmpty) return null;
      return text.length > 250 ? text.substring(0, 250) : text;
    } on Exception {
      return null;
    }
  }

  /// Uploads the buffer oldest first, in batches of [maxBatch]. A failed
  /// batch backs off from 30 s, doubling to 5 min; the buffer is kept.
  Future<FlushOutcome> flush({bool force = false}) async {
    if (_flushing) return FlushOutcome.idle;
    final notBefore = _notBefore;
    if (!force && notBefore != null && DateTime.now().isBefore(notBefore)) {
      return FlushOutcome.idle;
    }
    _flushing = true;
    var uploaded = 0;
    try {
      while (true) {
        final batch = await db.oldest(limit: maxBatch);
        if (batch.isEmpty) break;
        final result = await uploader.upload(batch);
        if (result == null) {
          _scheduleBackoff();
          return FlushOutcome.retryLater;
        }
        await db.deleteByIds([for (final ping in batch) ?ping.id]);
        uploaded += batch.length;
        await TrackerPrefs.setLastUploadAt(DateTime.now());
      }
      if (uploaded > 0) {
        _backoff = _minBackoff;
        _notBefore = null;
      }
      return uploaded > 0 ? FlushOutcome.uploaded : FlushOutcome.idle;
    } on Exception catch (error) {
      logDebug('Tracker: flush failed ($error)');
      _scheduleBackoff();
      return FlushOutcome.retryLater;
    } finally {
      _flushing = false;
      await publishCount();
    }
  }

  void _scheduleBackoff() {
    _notBefore = DateTime.now().add(_backoff);
    final doubled = _backoff * 2;
    _backoff = doubled > _maxBackoff ? _maxBackoff : doubled;
  }

  Future<int> publishCount() async {
    final count = await db.count();
    await TrackerPrefs.setBufferedCount(count);
    return count;
  }
}
