/// What the UI isolate and the Android foreground service say to each other.
/// Maps only: they cross an isolate boundary.
abstract final class TrackerCommands {
  static const flushNow = 'flushNow';
  static const requestStatus = 'requestStatus';
  static const uploadAck = 'uploadAck';
  static const config = 'config';

  static Map<String, Object?> flush() => {'command': flushNow};

  static Map<String, Object?> status() => {'command': requestStatus};

  static Map<String, Object?> ack(
    int requestId, {
    required bool delivered,
    int rejected = 0,
  }) => {
    'command': uploadAck,
    'requestId': requestId,
    'delivered': delivered,
    'rejected': rejected,
  };

  static Map<String, Object?> newConfig(Map<String, dynamic> json) => {
    'command': config,
    'config': json,
  };
}

abstract final class TrackerMessages {
  static const status = 'status';
  static const upload = 'upload';
  static const stopped = 'stopped';

  static Map<String, Object?> statusOf({
    required int buffered,
    required bool insideWindow,
    required bool moving,
    required bool gpsOn,
    DateTime? lastCaptureAt,
    DateTime? lastUploadAt,
  }) => {
    'type': status,
    'buffered': buffered,
    'insideWindow': insideWindow,
    'moving': moving,
    'gpsOn': gpsOn,
    'lastCaptureAt': lastCaptureAt?.toUtc().toIso8601String(),
    'lastUploadAt': lastUploadAt?.toUtc().toIso8601String(),
  };

  /// The service asks the UI isolate to deliver a batch, because the
  /// session and its token refresh live there.
  static Map<String, Object?> uploadRequest(
    int requestId,
    List<Map<String, Object?>> pings,
  ) => {'type': upload, 'requestId': requestId, 'pings': pings};

  static Map<String, Object?> stoppedNow() => {'type': stopped};
}

extension TrackerMessageRead on Map<Object?, Object?> {
  int intOr(String key, int fallback) => switch (this[key]) {
    final num value => value.toInt(),
    _ => fallback,
  };

  bool boolOr(String key, bool fallback) => switch (this[key]) {
    final bool value => value,
    _ => fallback,
  };

  DateTime? timeOrNull(String key) => switch (this[key]) {
    final String value => DateTime.tryParse(value)?.toLocal(),
    _ => null,
  };
}
