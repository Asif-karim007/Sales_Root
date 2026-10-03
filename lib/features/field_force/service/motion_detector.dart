import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import 'package:salesroot/core/utils/debug_log.dart';

/// Decides from the accelerometer whether GPS may run at all: listening costs
/// almost nothing, GPS costs a great deal. Movement is reported at once;
/// stillness must last [stillnessHold], so a van at a light stays on the map.
/// Without a usable sensor it fails open and reports moving.
class MotionDetector {
  MotionDetector({
    this.movementThreshold = 0.6,
    this.stillnessHold = const Duration(minutes: 2),
    this.samplingPeriod = const Duration(milliseconds: 200),
  });

  final double movementThreshold;
  final Duration stillnessHold;
  final Duration samplingPeriod;

  final _changes = StreamController<bool>.broadcast();
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  Timer? _stillness;
  bool _moving = false;
  bool _started = false;

  bool get isMoving => _moving;

  /// Emits on every transition, never on every sample.
  Stream<bool> get changes => _changes.stream;

  void start() {
    if (_started) return;
    _started = true;
    try {
      _subscription = userAccelerometerEventStream(
        samplingPeriod: samplingPeriod,
      ).listen(_onSample, onError: (Object error) => _failOpen('$error'));
    } on Exception catch (error) {
      _failOpen('$error');
    }
  }

  Future<void> stop() async {
    _started = false;
    _stillness?.cancel();
    _stillness = null;
    await _subscription?.cancel();
    _subscription = null;
    _set(false);
  }

  Future<void> dispose() async {
    await stop();
    await _changes.close();
  }

  void _onSample(UserAccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude >= movementThreshold) {
      _stillness?.cancel();
      _stillness = null;
      _set(true);
      return;
    }
    if (_moving && _stillness == null) {
      _stillness = Timer(stillnessHold, () {
        _stillness = null;
        _set(false);
      });
    }
  }

  void _failOpen(String reason) {
    logDebug('Tracker: no motion sensor ($reason), treating as moving');
    _set(true);
  }

  void _set(bool moving) {
    if (_moving == moving) return;
    _moving = moving;
    if (!_changes.isClosed) _changes.add(moving);
  }
}
