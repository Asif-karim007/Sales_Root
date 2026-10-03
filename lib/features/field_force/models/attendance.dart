import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';

enum AttendanceStatus {
  present('Present'),
  late('Late'),
  leave('Leave'),
  absent('Absent'),
  off('Off'),
  upcoming('Upcoming');

  const AttendanceStatus(this.wire);

  final String wire;

  static AttendanceStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => AttendanceStatus.upcoming,
  );

  /// Counts as a day the member showed up.
  bool get attended => this == present || this == late;
}

enum CorrectionStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const CorrectionStatus(this.wire);

  final String wire;

  static CorrectionStatus? fromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

class AttendancePlace {
  const AttendancePlace({this.latitude, this.longitude, this.location});

  final double? latitude;
  final double? longitude;
  final String? location;

  factory AttendancePlace.fromJson(Map<String, dynamic> json) =>
      AttendancePlace(
        latitude: jsonDouble(json['Latitude']),
        longitude: jsonDouble(json['Longitude']),
        location: json['Location'] as String?,
      );
}

class AttendanceBreak {
  const AttendanceBreak({required this.start, this.end});

  final DateTime start;

  /// Null while the break is running.
  final DateTime? end;

  int minutesUntil(DateTime now) =>
      (end ?? now).difference(start).inMinutes.clamp(0, 24 * 60);

  static AttendanceBreak? fromJson(Map<String, dynamic> json) {
    final start = jsonDate(json['Start']);
    if (start == null) return null;
    return AttendanceBreak(start: start, end: jsonDate(json['End']));
  }
}

/// One day's attendance for one member. The server stamps both times.
class AttendanceLog {
  const AttendanceLog({
    required this.date,
    this.id,
    this.employeeId,
    this.checkInAt,
    this.checkOutAt,
    this.workedMinutes,
    this.checkInPlace,
    this.checkOutPlace,
    this.checkInDistance,
    this.isLate = false,
    this.lateMinutes = 0,
    this.isEarlyOut = false,
    this.breaks = const [],
  });

  final int? id;
  final int? employeeId;
  final DateTime date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int? workedMinutes;
  final AttendancePlace? checkInPlace;
  final AttendancePlace? checkOutPlace;

  /// Metres from the office, when the check-in had a fix.
  final int? checkInDistance;
  final bool isLate;
  final int lateMinutes;
  final bool isEarlyOut;
  final List<AttendanceBreak> breaks;

  bool get isCheckedIn => checkInAt != null && checkOutAt == null;
  bool get isCheckedOut => checkOutAt != null;
  bool get onBreak => breaks.isNotEmpty && breaks.last.end == null;

  /// Minutes worked so far: check-in to check-out (or [now]) less breaks.
  int workedUntil(DateTime now) {
    final worked = workedMinutes;
    if (worked != null && checkOutAt != null) return worked;
    final start = checkInAt;
    if (start == null) return 0;
    final total = (checkOutAt ?? now).difference(start).inMinutes;
    final paused = breaks.fold<int>(0, (sum, b) => sum + b.minutesUntil(now));
    return (total - paused).clamp(0, 24 * 60);
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json) => AttendanceLog(
    id: jsonInt(json['Id']),
    employeeId: jsonInt(json['EmployeeId']),
    date: jsonDate(json['Date']) ?? DateTime(2000),
    checkInAt: jsonDate(json['CheckInAt']),
    checkOutAt: jsonDate(json['CheckOutAt']),
    workedMinutes: jsonInt(json['WorkedMinutes']),
    checkInPlace: jsonObject(json['CheckInPlace'], AttendancePlace.fromJson),
    checkOutPlace: jsonObject(json['CheckOutPlace'], AttendancePlace.fromJson),
    checkInDistance: jsonInt(json['CheckInDistance']),
    isLate: jsonBool(json['IsLate']),
    lateMinutes: jsonInt(json['LateMinutes']) ?? 0,
    isEarlyOut: jsonBool(json['IsEarlyOut']),
    breaks: [
      for (final row in jsonList(json['Breaks'], AttendanceBreak.fromJson))
        ?row,
    ],
  );
}

/// The check-in or check-out body. The member comes from the token.
class AttendancePunch {
  const AttendancePunch({
    this.latitude,
    this.longitude,
    this.location,
    this.note,
  });

  final double? latitude;
  final double? longitude;
  final String? location;
  final String? note;

  Map<String, dynamic> toJson() => {
    'Latitude': latitude,
    'Longitude': longitude,
    'Location': location,
    'Note': note,
  }..removeWhere((_, value) => value == null);
}

class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.status,
    this.correction,
  });

  final DateTime date;
  final AttendanceStatus status;
  final CorrectionStatus? correction;

  factory AttendanceDay.fromJson(Map<String, dynamic> json) => AttendanceDay(
    date: jsonDate(json['Date']) ?? DateTime(2000),
    status: AttendanceStatus.fromWire(json['Status'] as String?),
    correction: CorrectionStatus.fromWire(json['Correction'] as String?),
  );
}

class AttendanceSummary {
  const AttendanceSummary({
    this.workingDays = 0,
    this.present = 0,
    this.late = 0,
    this.leave = 0,
    this.absent = 0,
    this.workedMinutes = 0,
  });

  final int workingDays;

  /// Days attended, on time or late.
  final int present;
  final int late;
  final int leave;
  final int absent;
  final int workedMinutes;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceSummary(
        workingDays: jsonInt(json['WorkingDays']) ?? 0,
        present: jsonInt(json['Present']) ?? 0,
        late: jsonInt(json['Late']) ?? 0,
        leave: jsonInt(json['Leave']) ?? 0,
        absent: jsonInt(json['Absent']) ?? 0,
        workedMinutes: jsonInt(json['WorkedMinutes']) ?? 0,
      );
}

/// A day on the attendance timeline: check-in, visits, breaks, check-out.
enum DayEventKind { checkIn, visit, pause, breakTime, checkOut }

class DayEvent {
  const DayEvent({
    required this.kind,
    required this.time,
    this.title,
    this.area,
    this.minutes,
    this.visitId,
    this.inProgress = false,
    this.distance,
    this.detail,
  });

  final DayEventKind kind;
  final DateTime time;

  /// The company for a visit.
  final String? title;
  final LocalizedName? area;
  final int? minutes;
  final int? visitId;
  final bool inProgress;

  /// Metres from the expected place, for check-ins.
  final int? distance;

  /// Free text the member typed, such as what was shown on a visit.
  final String? detail;

  static DayEvent? fromJson(Map<String, dynamic> json) {
    final time = jsonDate(json['Time']);
    final kind = switch (json['Kind']) {
      'CheckIn' => DayEventKind.checkIn,
      'Visit' => DayEventKind.visit,
      'Pause' => DayEventKind.pause,
      'Break' => DayEventKind.breakTime,
      'CheckOut' => DayEventKind.checkOut,
      _ => null,
    };
    if (time == null || kind == null) return null;
    return DayEvent(
      kind: kind,
      time: time,
      title: json['Title'] as String?,
      area: jsonObject(json['Area'], LocalizedName.fromJson),
      minutes: jsonInt(json['Minutes']),
      visitId: jsonInt(json['VisitId']),
      inProgress: jsonBool(json['InProgress']),
      distance: jsonInt(json['Distance']),
      detail: json['Detail'] as String?,
    );
  }
}

List<DayEvent> dayEventsFromJson(dynamic value) => [
  for (final event in jsonList(value, DayEvent.fromJson)) ?event,
];

/// Everything the attendance screen shows for today.
class AttendanceToday {
  const AttendanceToday({
    required this.date,
    required this.shiftStart,
    required this.shiftEnd,
    required this.month,
    required this.week,
    required this.events,
    this.log,
  });

  final DateTime date;

  /// "09:00", local wall-clock time.
  final String shiftStart;
  final String shiftEnd;
  final AttendanceLog? log;
  final AttendanceSummary month;

  /// Saturday to Friday of this week.
  final List<AttendanceDay> week;
  final List<DayEvent> events;

  factory AttendanceToday.fromJson(Map<String, dynamic> json) =>
      AttendanceToday(
        date: jsonDate(json['Date']) ?? DateTime(2000),
        shiftStart: json['ShiftStart'] as String? ?? '09:00',
        shiftEnd: json['ShiftEnd'] as String? ?? '18:00',
        log: jsonObject(json['Log'], AttendanceLog.fromJson),
        month:
            jsonObject(json['Month'], AttendanceSummary.fromJson) ??
            const AttendanceSummary(),
        week: jsonList(json['Week'], AttendanceDay.fromJson),
        events: dayEventsFromJson(json['Events']),
      );

  /// When the shift ends today, in local time.
  DateTime get shiftEndsAt => clockOn(date, shiftEnd);
}

class AttendanceMonth {
  const AttendanceMonth({
    required this.month,
    required this.days,
    required this.summary,
  });

  final DateTime month;
  final List<AttendanceDay> days;
  final AttendanceSummary summary;

  List<AttendanceDay> get absences =>
      days.where((d) => d.status == AttendanceStatus.absent).toList();

  factory AttendanceMonth.fromJson(Map<String, dynamic> json) =>
      AttendanceMonth(
        month: jsonDate(json['Month']) ?? DateTime(2000),
        days: jsonList(json['Days'], AttendanceDay.fromJson),
        summary:
            jsonObject(json['Summary'], AttendanceSummary.fromJson) ??
            const AttendanceSummary(),
      );
}

enum TeamPeriod { today, week, month }

/// One member's row on the team attendance list: today's punch, or the
/// period's totals for a week or a month.
class TeamAttendanceRow {
  const TeamAttendanceRow({
    required this.memberId,
    required this.name,
    required this.status,
    this.checkInAt,
    this.place,
    this.lateMinutes = 0,
    this.correction,
    this.correctionDate,
    this.correctionReason,
    this.summary,
  });

  final int memberId;
  final LocalizedName name;

  /// Today's status, or the worst status in the period.
  final AttendanceStatus status;
  final DateTime? checkInAt;
  final String? place;
  final int lateMinutes;
  final CorrectionStatus? correction;
  final DateTime? correctionDate;
  final String? correctionReason;
  final AttendanceSummary? summary;

  bool get needsCorrection => correction == CorrectionStatus.pending;

  factory TeamAttendanceRow.fromJson(Map<String, dynamic> json) =>
      TeamAttendanceRow(
        memberId: jsonInt(json['MemberId']) ?? 0,
        name: LocalizedName.fromJson(json),
        status: AttendanceStatus.fromWire(json['Status'] as String?),
        checkInAt: jsonDate(json['CheckInAt']),
        place: json['Place'] as String?,
        lateMinutes: jsonInt(json['LateMinutes']) ?? 0,
        correction: CorrectionStatus.fromWire(json['Correction'] as String?),
        correctionDate: jsonDate(json['CorrectionDate']),
        correctionReason: json['CorrectionReason'] as String?,
        summary: jsonObject(json['Summary'], AttendanceSummary.fromJson),
      );
}

class TeamAttendanceSummary {
  const TeamAttendanceSummary({
    this.present = 0,
    this.late = 0,
    this.leave = 0,
    this.absent = 0,
    this.corrections = 0,
  });

  final int present;
  final int late;
  final int leave;
  final int absent;
  final int corrections;

  factory TeamAttendanceSummary.fromJson(Map<String, dynamic> json) =>
      TeamAttendanceSummary(
        present: jsonInt(json['Present']) ?? 0,
        late: jsonInt(json['Late']) ?? 0,
        leave: jsonInt(json['Leave']) ?? 0,
        absent: jsonInt(json['Absent']) ?? 0,
        corrections: jsonInt(json['Corrections']) ?? 0,
      );
}

class TeamAttendanceQuery {
  const TeamAttendanceQuery({
    this.period = TeamPeriod.today,
    this.correctionsOnly = false,
    this.page = 1,
  });

  final TeamPeriod period;
  final bool correctionsOnly;
  final int page;

  TeamAttendanceQuery copyWith({
    TeamPeriod? period,
    bool? correctionsOnly,
    int? page,
  }) => TeamAttendanceQuery(
    period: period ?? this.period,
    correctionsOnly: correctionsOnly ?? this.correctionsOnly,
    page: page ?? this.page,
  );

  Map<String, dynamic> toQuery() => {
    'period': period.name,
    'corrections': correctionsOnly,
    'page': page,
    'pageSize': 20,
  };
}

/// [clock] ("09:30") on the day of [day], in local time.
DateTime clockOn(DateTime day, String clock) {
  final parts = clock.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final date = AppDateUtils.dateOnly(day);
  return DateTime(date.year, date.month, date.day, hour, minute);
}
