import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';

/// The owner's live-tracking and duty rules for the workspace.
class TrackingSettings {
  const TrackingSettings({
    this.dutyStart = '09:00',
    this.dutyEnd = '18:00',
    this.workDays = const [6, 7, 1, 2, 3, 4],
    this.checkInRadius = 300,
    this.updateMinutes = 0,
    this.retentionDays = 90,
    this.liveTracking = true,
    this.offOutsideDuty = true,
    this.allowPauses = true,
    this.flagMockLocations = true,
    this.teamLeadSeesOwn = true,
    this.managerSeesDepartment = true,
    this.ownerSeesEveryone = true,
  });

  static const radiusChoices = [100, 200, 300, 500];
  static const updateChoices = [0, 1, 5, 10];
  static const retentionChoices = [30, 60, 90, 180];

  /// "09:00", local wall-clock time.
  final String dutyStart;
  final String dutyEnd;

  /// `DateTime.weekday` values; Friday (5) is the usual day off.
  final List<int> workDays;

  /// Metres; further than this is a far check-in.
  final int checkInRadius;

  /// Minutes between location updates; 0 adapts between 2 and 5.
  final int updateMinutes;
  final int retentionDays;
  final bool liveTracking;
  final bool offOutsideDuty;
  final bool allowPauses;
  final bool flagMockLocations;
  final bool teamLeadSeesOwn;
  final bool managerSeesDepartment;
  final bool ownerSeesEveryone;

  /// The heartbeat the tracker uses.
  double get heartbeatMinutes => updateMinutes == 0 ? 5 : updateMinutes * 1.0;

  bool isWorkDay(DateTime day) => workDays.contains(day.weekday);

  factory TrackingSettings.fromJson(Map<String, dynamic> json) {
    const fallback = TrackingSettings();
    final days = jsonInts(json['WorkDays']);
    return TrackingSettings(
      dutyStart: json['DutyStart'] as String? ?? fallback.dutyStart,
      dutyEnd: json['DutyEnd'] as String? ?? fallback.dutyEnd,
      workDays: days.isEmpty ? fallback.workDays : days,
      checkInRadius: jsonInt(json['CheckInRadius']) ?? fallback.checkInRadius,
      updateMinutes: jsonInt(json['UpdateMinutes']) ?? fallback.updateMinutes,
      retentionDays: jsonInt(json['RetentionDays']) ?? fallback.retentionDays,
      liveTracking: json['LiveTracking'] as bool? ?? fallback.liveTracking,
      offOutsideDuty:
          json['OffOutsideDuty'] as bool? ?? fallback.offOutsideDuty,
      allowPauses: json['AllowPauses'] as bool? ?? fallback.allowPauses,
      flagMockLocations:
          json['FlagMockLocations'] as bool? ?? fallback.flagMockLocations,
      teamLeadSeesOwn:
          json['TeamLeadSeesOwn'] as bool? ?? fallback.teamLeadSeesOwn,
      managerSeesDepartment:
          json['ManagerSeesDepartment'] as bool? ??
          fallback.managerSeesDepartment,
      ownerSeesEveryone:
          json['OwnerSeesEveryone'] as bool? ?? fallback.ownerSeesEveryone,
    );
  }

  Map<String, dynamic> toJson() => {
    'DutyStart': dutyStart,
    'DutyEnd': dutyEnd,
    'WorkDays': workDays,
    'CheckInRadius': checkInRadius,
    'UpdateMinutes': updateMinutes,
    'RetentionDays': retentionDays,
    'LiveTracking': liveTracking,
    'OffOutsideDuty': offOutsideDuty,
    'AllowPauses': allowPauses,
    'FlagMockLocations': flagMockLocations,
    'TeamLeadSeesOwn': teamLeadSeesOwn,
    'ManagerSeesDepartment': managerSeesDepartment,
    'OwnerSeesEveryone': ownerSeesEveryone,
  };

  TrackingSettings copyWith({
    String? dutyStart,
    String? dutyEnd,
    List<int>? workDays,
    int? checkInRadius,
    int? updateMinutes,
    int? retentionDays,
    bool? liveTracking,
    bool? offOutsideDuty,
    bool? allowPauses,
    bool? flagMockLocations,
    bool? teamLeadSeesOwn,
    bool? managerSeesDepartment,
    bool? ownerSeesEveryone,
  }) => TrackingSettings(
    dutyStart: dutyStart ?? this.dutyStart,
    dutyEnd: dutyEnd ?? this.dutyEnd,
    workDays: workDays ?? this.workDays,
    checkInRadius: checkInRadius ?? this.checkInRadius,
    updateMinutes: updateMinutes ?? this.updateMinutes,
    retentionDays: retentionDays ?? this.retentionDays,
    liveTracking: liveTracking ?? this.liveTracking,
    offOutsideDuty: offOutsideDuty ?? this.offOutsideDuty,
    allowPauses: allowPauses ?? this.allowPauses,
    flagMockLocations: flagMockLocations ?? this.flagMockLocations,
    teamLeadSeesOwn: teamLeadSeesOwn ?? this.teamLeadSeesOwn,
    managerSeesDepartment: managerSeesDepartment ?? this.managerSeesDepartment,
    ownerSeesEveryone: ownerSeesEveryone ?? this.ownerSeesEveryone,
  );
}

/// The member's answer to the live-tracking consent screen.
class TrackingConsent {
  const TrackingConsent({required this.given, this.at, this.workspaceName});

  final bool given;
  final DateTime? at;
  final String? workspaceName;

  factory TrackingConsent.fromJson(Map<String, dynamic> json) =>
      TrackingConsent(
        given: jsonBool(json['Given']),
        at: jsonDate(json['At']),
        workspaceName: json['WorkspaceName'] as String?,
      );
}

enum LiveStatus {
  onVisit('OnVisit'),
  moving('Moving'),
  idle('Idle'),
  notTracking('NotTracking'),
  offDuty('OffDuty');

  const LiveStatus(this.wire);

  final String wire;

  static LiveStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => LiveStatus.offDuty,
  );

  bool get isLive => this == onVisit || this == moving || this == idle;
}

/// Where one team member is right now.
class LiveMember {
  const LiveMember({
    required this.memberId,
    required this.name,
    required this.status,
    this.checkedIn = false,
    this.latitude,
    this.longitude,
    this.area,
    this.visitCompany,
    this.lastSeenAt,
    this.lastSeenMinutes,
    this.battery,
  });

  final int memberId;
  final LocalizedName name;
  final LiveStatus status;
  final bool checkedIn;
  final double? latitude;
  final double? longitude;
  final LocalizedName? area;
  final String? visitCompany;
  final DateTime? lastSeenAt;

  /// How long ago the last ping arrived, by the server's clock.
  final int? lastSeenMinutes;
  final int? battery;

  factory LiveMember.fromJson(Map<String, dynamic> json) => LiveMember(
    memberId: jsonInt(json['MemberId']) ?? 0,
    name: LocalizedName.fromJson(json),
    status: LiveStatus.fromWire(json['Status'] as String?),
    checkedIn: jsonBool(json['CheckedIn']),
    latitude: jsonDouble(json['Latitude']),
    longitude: jsonDouble(json['Longitude']),
    area: jsonObject(json['Area'], LocalizedName.fromJson),
    visitCompany: json['VisitCompany'] as String?,
    lastSeenAt: jsonDate(json['LastSeenAt']),
    lastSeenMinutes: jsonInt(json['LastSeenMinutes']),
    battery: jsonInt(json['Battery']),
  );
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

  static TrailPoint? fromJson(Map<String, dynamic> json) {
    final lat = jsonDouble(json['Latitude']);
    final lng = jsonDouble(json['Longitude']);
    if (lat == null || lng == null) return null;
    final battery = jsonInt(json['Battery']);
    return TrailPoint(
      latitude: lat,
      longitude: lng,
      time: jsonDate(json['LocationTime']),
      battery: battery == null || battery < 0 || battery > 100 ? null : battery,
    );
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
    this.heartbeatMinutes = 5,
  });

  final int memberId;
  final LocalizedName name;
  final DateTime date;
  final List<TrailPoint> points;
  final List<DayEvent> events;
  final double heartbeatMinutes;

  int get visitCount =>
      events.where((e) => e.kind == DayEventKind.visit).length;

  factory MemberDay.fromJson(Map<String, dynamic> json) {
    final points = [
      for (final point in jsonList(json['Points'], TrailPoint.fromJson)) ?point,
    ]..sort((a, b) => (a.time ?? DateTime(0)).compareTo(b.time ?? DateTime(0)));
    return MemberDay(
      memberId: jsonInt(json['MemberId']) ?? 0,
      name: LocalizedName.fromJson(json),
      date: jsonDate(json['Date']) ?? DateTime(2000),
      points: points,
      events: dayEventsFromJson(json['Events']),
      heartbeatMinutes: jsonDouble(json['HeartbeatMinutes']) ?? 5,
    );
  }
}
