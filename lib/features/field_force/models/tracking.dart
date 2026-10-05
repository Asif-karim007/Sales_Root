import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';

/// The workspace's field rules, from `attendance/today` → `settings`.
class TrackingSettings {
  const TrackingSettings({
    this.geofenceMetres = 200,
    this.trackIntervalSeconds = 600,
    this.selfieOnCheckIn = false,
  });

  static const radiusChoices = [100, 200, 300, 500];
  static const intervalChoices = [60, 300, 600, 900];

  /// Metres; further than this from the customer is a far check-in.
  final int geofenceMetres;

  /// Seconds between location updates; 0 turns live tracking off.
  final int trackIntervalSeconds;
  final bool selfieOnCheckIn;

  bool get liveTracking => trackIntervalSeconds > 0;

  double get heartbeatMinutes => trackIntervalSeconds / 60;

  factory TrackingSettings.fromJson(Map<String, dynamic> json) {
    const fallback = TrackingSettings();
    return TrackingSettings(
      geofenceMetres: jsonInt(json['geofenceM']) ?? fallback.geofenceMetres,
      trackIntervalSeconds:
          jsonInt(json['trackIntervalSec']) ?? fallback.trackIntervalSeconds,
      selfieOnCheckIn: jsonBool(json['selfieOnCheckIn']),
    );
  }

  Map<String, dynamic> toJson() => {
    'geofenceM': geofenceMetres,
    'trackIntervalSec': trackIntervalSeconds,
    'selfieOnCheckIn': selfieOnCheckIn,
  };

  TrackingSettings copyWith({
    int? geofenceMetres,
    int? trackIntervalSeconds,
    bool? selfieOnCheckIn,
  }) => TrackingSettings(
    geofenceMetres: geofenceMetres ?? this.geofenceMetres,
    trackIntervalSeconds: trackIntervalSeconds ?? this.trackIntervalSeconds,
    selfieOnCheckIn: selfieOnCheckIn ?? this.selfieOnCheckIn,
  );
}

/// The member's answer to the live-tracking consent screen, kept on this
/// phone.
class TrackingConsent {
  const TrackingConsent({this.at, this.workspaceName});

  final DateTime? at;
  final String? workspaceName;
}

enum LiveStatus {
  live,
  checkedOut,
  offDuty;

  bool get isLive => this == live;
}

/// Where one team member is, from today's row of `GET attendance`.
class LiveMember {
  const LiveMember({
    required this.memberId,
    required this.name,
    required this.status,
    this.latitude,
    this.longitude,
    this.lastSeenAt,
    this.battery,
    this.visits = 0,
    this.mockDetected = false,
  });

  final String memberId;
  final String name;
  final LiveStatus status;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeenAt;
  final int? battery;
  final int visits;
  final bool mockDetected;

  factory LiveMember.fromJson(Map<String, dynamic> json) {
    final battery = jsonInt(json['battery']);
    return LiveMember(
      memberId: jsonId(json['membershipId']) ?? '',
      name: json['name'] as String? ?? '',
      status: json['checkOutAt'] != null
          ? LiveStatus.checkedOut
          : json['checkInAt'] != null
          ? LiveStatus.live
          : LiveStatus.offDuty,
      latitude: jsonDouble(json['lat']),
      longitude: jsonDouble(json['lng']),
      lastSeenAt: jsonDate(json['lastSeenAt']),
      battery: battery == null || battery < 0 || battery > 100 ? null : battery,
      visits: jsonInt(json['visits']) ?? 0,
      mockDetected: jsonBool(json['mockDetected']),
    );
  }
}

/// One recorded location of a member's day.
class TrailPoint {
  const TrailPoint({
    required this.latitude,
    required this.longitude,
    this.time,
    this.battery,
  });

  final double latitude;
  final double longitude;
  final DateTime? time;

  /// Whole percent, when the phone reported it.
  final int? battery;

  /// A point of `GET team/map`, in the `LocationPoint` shape the app
  /// uploads.
  static TrailPoint? fromJson(Map<String, dynamic> json) {
    final lat = jsonDouble(json['lat']);
    final lng = jsonDouble(json['lng']);
    if (lat == null || lng == null) return null;
    final battery = jsonInt(json['battery']);
    return TrailPoint(
      latitude: lat,
      longitude: lng,
      time: jsonDate(json['at']),
      battery: battery == null || battery < 0 || battery > 100 ? null : battery,
    );
  }

  /// The points in a `GET team/map` answer for one member and day: a bare
  /// list, or a list under `points`.
  static List<TrailPoint> listOf(dynamic json) {
    final rows = json is List ? json : jsonMap(json)['points'];
    return [
      for (final point in jsonList(rows, TrailPoint.fromJson)) ?point,
    ]..sort((a, b) => (a.time ?? DateTime(0)).compareTo(b.time ?? DateTime(0)));
  }
}

/// A member's day: the recorded trail and what happened along it.
class MemberDay {
  const MemberDay({
    required this.memberId,
    required this.name,
    required this.date,
    required this.points,
    required this.events,
  });

  final String memberId;
  final String name;
  final DateTime date;
  final List<TrailPoint> points;
  final List<DayEvent> events;

  int get visitCount =>
      events.where((e) => e.kind == DayEventKind.visit).length;
}
