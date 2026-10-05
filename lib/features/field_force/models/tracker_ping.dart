enum TrackerPingKind { movement, heartbeat }

/// One buffered location, waiting in the tracker's own database for upload.
class TrackerPing {
  const TrackerPing({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.locationTimeUtc,
    required this.createdAt,
    this.battery,
    this.accuracy,
    this.speed,
    this.mock = false,
    this.kind = TrackerPingKind.heartbeat,
  });

  static const table = 'tracker_pings';

  final int? id;
  final double latitude;
  final double longitude;
  final DateTime locationTimeUtc;
  final DateTime createdAt;

  /// Whole percent.
  final int? battery;

  /// Metres.
  final double? accuracy;

  /// Metres per second.
  final double? speed;

  /// The phone reported the fix as coming from a mock-location app.
  final bool mock;

  /// Stored locally only: the upload contract has no field for it.
  final TrackerPingKind kind;

  factory TrackerPing.fromDb(Map<String, Object?> row) => TrackerPing(
    id: row['id'] as int?,
    latitude: (row['lat'] as num? ?? 0).toDouble(),
    longitude: (row['lng'] as num? ?? 0).toDouble(),
    locationTimeUtc:
        DateTime.tryParse('${row['locationTimeUtc']}')?.toUtc() ??
        DateTime.utc(2000),
    battery: row['battery'] as int?,
    accuracy: (row['accuracy'] as num?)?.toDouble(),
    speed: (row['speed'] as num?)?.toDouble(),
    mock: row['mock'] == 1,
    createdAt:
        DateTime.tryParse('${row['createdAt']}')?.toUtc() ?? DateTime.utc(2000),
    kind: TrackerPingKind.values.firstWhere(
      (kind) => kind.name == row['kind'],
      orElse: () => TrackerPingKind.heartbeat,
    ),
  );

  Map<String, Object?> toDb() => {
    'id': ?id,
    'lat': latitude,
    'lng': longitude,
    'locationTimeUtc': isoUtc(locationTimeUtc),
    'battery': battery,
    'accuracy': accuracy,
    'speed': speed,
    'mock': mock ? 1 : 0,
    'createdAt': isoUtc(createdAt),
    'kind': kind.name,
  };

  /// One `LocationPoint` of `POST locations`, timed in ISO-8601 UTC.
  Map<String, dynamic> toApiJson() => {
    'at': isoUtc(locationTimeUtc),
    'lat': latitude,
    'lng': longitude,
    'accuracy': ?accuracy,
    'speed': ?speed,
    'battery': ?battery,
    'mock': mock,
  };

  static String isoUtc(DateTime value) {
    final utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
        '${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:'
        '${two(utc.second)}Z';
  }

  static bool isValidCoordinate(double latitude, double longitude) {
    if (latitude == 0 && longitude == 0) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    return latitude.abs() <= 90 && longitude.abs() <= 180;
  }
}
