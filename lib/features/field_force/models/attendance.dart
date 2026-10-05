import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/models/visit.dart';

enum AttendanceStatus {
  present('present'),
  late('late'),
  halfDay('half_day'),
  leave('leave'),
  absent('absent'),
  off('off'),
  none('none'),
  upcoming('upcoming');

  const AttendanceStatus(this.wire);

  final String wire;

  static AttendanceStatus? fromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }

  /// Counts as a day the member showed up.
  bool get attended => this == present || this == late || this == halfDay;
}

/// One day's attendance for one member, as `attendance/today` returns it.
/// The check-in and check-out responses carry a subset of the same keys.
class AttendanceLog {
  const AttendanceLog({
    this.id,
    this.checkInAt,
    this.checkOutAt,
    this.status,
    this.inOffice,
    this.reason,
    this.distanceKm,
  });

  final String? id;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final AttendanceStatus? status;

  /// Whether the check-in was inside the office geofence.
  final bool? inOffice;
  final String? reason;

  /// Distance travelled today, from the uploaded locations.
  final double? distanceKm;

  bool get isCheckedIn => checkInAt != null && checkOutAt == null;
  bool get isCheckedOut => checkOutAt != null;

  /// Minutes from check-in to check-out, or to [now] while still in.
  int workedUntil(DateTime now) {
    final start = checkInAt;
    if (start == null) return 0;
    return (checkOutAt ?? now).difference(start).inMinutes.clamp(0, 24 * 60);
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    final late = json['late'];
    return AttendanceLog(
      id: jsonId(json['id']),
      checkInAt: jsonDate(json['checkInAt']),
      checkOutAt: jsonDate(json['checkOutAt']),
      status:
          AttendanceStatus.fromWire(json['status'] as String?) ??
          switch (late) {
            true => AttendanceStatus.late,
            false => AttendanceStatus.present,
            _ => null,
          },
      inOffice: switch (json['checkInInOffice'] ?? json['inOffice']) {
        final bool value => value,
        _ => null,
      },
      reason: json['checkInReason'] as String?,
      distanceKm: jsonDouble(json['distanceKm']),
    );
  }
}

/// The check-in or check-out body. The member comes from the token.
class AttendancePunch {
  const AttendancePunch({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.mock = false,
    this.reason,
    this.photoKey,
  });

  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final bool mock;
  final String? reason;
  final String? photoKey;

  AttendancePunch copyWith({String? reason, String? photoKey}) =>
      AttendancePunch(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        mock: mock,
        reason: reason ?? this.reason,
        photoKey: photoKey ?? this.photoKey,
      );

  Map<String, dynamic> toCheckInJson() => {
    'lat': latitude,
    'lng': longitude,
    'accuracy': accuracy,
    'mock': mock,
    'reason': _blankToNull(reason),
    'photoKey': photoKey,
  }..removeWhere((_, value) => value == null);

  Map<String, dynamic> toCheckOutJson() => {
    'lat': latitude,
    'lng': longitude,
    'manual': false,
    'note': _blankToNull(reason),
  }..removeWhere((_, value) => value == null);
}

class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.status,
    this.workedMinutes = 0,
  });

  final DateTime date;
  final AttendanceStatus status;
  final int workedMinutes;
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
}

/// One day's bucket of `GET reports/field`, read for a single member.
class FieldReportBucket {
  const FieldReportBucket({
    required this.day,
    this.present = 0,
    this.late = 0,
    this.leave = 0,
    this.absent = 0,
    this.avgHours = 0,
    this.visits = 0,
    this.productiveVisits = 0,
    this.locationMismatch = 0,
  });

  final DateTime day;
  final int present;
  final int late;
  final int leave;
  final int absent;
  final double avgHours;
  final int visits;
  final int productiveVisits;
  final int locationMismatch;

  static FieldReportBucket? fromJson(Map<String, dynamic> json) {
    final day = _day(json['bucket']);
    if (day == null) return null;
    return FieldReportBucket(
      day: day,
      present: jsonInt(json['present']) ?? 0,
      late: jsonInt(json['late']) ?? 0,
      leave: jsonInt(json['leave']) ?? 0,
      absent: jsonInt(json['absent']) ?? 0,
      avgHours: jsonDouble(json['avgHours']) ?? 0,
      visits: jsonInt(json['visits']) ?? 0,
      productiveVisits: jsonInt(json['productiveVisits']) ?? 0,
      locationMismatch: jsonInt(json['locationMismatch']) ?? 0,
    );
  }
}

/// One person's row of `GET reports/field` → `breakdowns.byPerson`.
class FieldReportPerson {
  const FieldReportPerson({
    required this.memberId,
    required this.name,
    this.daysPresent = 0,
    this.late = 0,
    this.absent = 0,
    this.avgHours = 0,
    this.visits = 0,
    this.productiveVisits = 0,
  });

  final String memberId;
  final String name;
  final int daysPresent;
  final int late;
  final int absent;
  final double avgHours;
  final int visits;
  final int productiveVisits;

  factory FieldReportPerson.fromJson(Map<String, dynamic> json) =>
      FieldReportPerson(
        memberId: jsonId(json['id']) ?? '',
        name: json['key'] as String? ?? '',
        daysPresent: jsonInt(json['daysPresent']) ?? 0,
        late: jsonInt(json['late']) ?? 0,
        absent: jsonInt(json['absent']) ?? 0,
        avgHours: jsonDouble(json['avgHours']) ?? 0,
        visits: jsonInt(json['visits']) ?? 0,
        productiveVisits: jsonInt(json['productiveVisits']) ?? 0,
      );
}

/// `GET reports/field`: the range's totals, its days and its people.
class FieldReport {
  const FieldReport({
    required this.days,
    required this.people,
    this.daysPresent = 0,
    this.late = 0,
    this.absent = 0,
    this.visits = 0,
    this.productiveVisits = 0,
  });

  final List<FieldReportBucket> days;
  final List<FieldReportPerson> people;
  final int daysPresent;
  final int late;
  final int absent;
  final int visits;
  final int productiveVisits;

  int get leave => days.fold(0, (sum, day) => sum + day.leave);
  int get locationMismatch =>
      days.fold(0, (sum, day) => sum + day.locationMismatch);

  factory FieldReport.fromJson(Map<String, dynamic> json) {
    final summary = jsonMap(json['summary']);
    return FieldReport(
      days: [
        for (final day in jsonList(json['trend'], FieldReportBucket.fromJson))
          ?day,
      ],
      people: jsonList(
        jsonMap(json['breakdowns'])['byPerson'],
        FieldReportPerson.fromJson,
      ),
      daysPresent: jsonInt(summary['daysPresent']) ?? 0,
      late: jsonInt(summary['late']) ?? 0,
      absent: jsonInt(summary['absent']) ?? 0,
      visits: jsonInt(summary['visits']) ?? 0,
      productiveVisits: jsonInt(summary['productiveVisits']) ?? 0,
    );
  }
}

/// A day's attendance on a timeline: check-in, visits, check-out.
enum DayEventKind { checkIn, visit, checkOut }

class DayEvent {
  const DayEvent({
    required this.kind,
    required this.time,
    this.title,
    this.minutes,
    this.visitId,
    this.inProgress = false,
    this.inOffice,
    this.detail,
  });

  final DayEventKind kind;
  final DateTime time;

  /// The company for a visit.
  final String? title;
  final int? minutes;
  final String? visitId;
  final bool inProgress;

  /// For a check-in: inside the office geofence or not.
  final bool? inOffice;

  /// Free text the member typed, such as a visit's note.
  final String? detail;
}

/// A member's day as events: the punch from [log] and each of [visits].
List<DayEvent> dayEvents(AttendanceLog? log, List<Visit> visits) {
  final checkIn = log?.checkInAt;
  final checkOut = log?.checkOutAt;
  return [
    if (checkIn != null)
      DayEvent(
        kind: DayEventKind.checkIn,
        time: checkIn,
        inOffice: log?.inOffice,
        detail: log?.reason,
      ),
    for (final visit in visits)
      if (visit.startedAt case final started?)
        DayEvent(
          kind: DayEventKind.visit,
          time: started,
          title: visit.title,
          minutes: visit.durationMinutes,
          visitId: visit.id,
          inProgress: visit.isOpen,
          detail: visit.note,
        ),
    if (checkOut != null) DayEvent(kind: DayEventKind.checkOut, time: checkOut),
  ]..sort((a, b) => a.time.compareTo(b.time));
}

/// Everything `attendance/today` says about the user's day.
class AttendanceToday {
  const AttendanceToday({
    required this.date,
    required this.visits,
    required this.stops,
    required this.settings,
    this.log,
  });

  final DateTime date;
  final AttendanceLog? log;

  /// Today's visits, open and finished.
  final List<Visit> visits;

  /// Today's route (beat) plan.
  final List<RouteStop> stops;
  final TrackingSettings settings;

  List<DayEvent> get events => dayEvents(log, visits);

  factory AttendanceToday.fromJson(Map<String, dynamic> json) =>
      AttendanceToday(
        date: _day(json['day']) ?? AppDateUtils.dateOnly(DateTime.now()),
        log: jsonObject(json['attendance'], AttendanceLog.fromJson),
        visits: jsonList(json['visits'], Visit.fromJson),
        stops: [
          for (final stop in jsonList(
            jsonMap(json['route'])['stops'],
            RouteStop.fromJson,
          ))
            ?stop,
        ]..sort((a, b) => a.order.compareTo(b.order)),
        settings: TrackingSettings.fromJson(jsonMap(json['settings'])),
      );
}

class AttendanceMonth {
  const AttendanceMonth({
    required this.from,
    required this.days,
    required this.summary,
  });

  final DateTime from;
  final List<AttendanceDay> days;
  final AttendanceSummary summary;

  List<AttendanceDay> get absences =>
      days.where((d) => d.status == AttendanceStatus.absent).toList();

  /// [report] for one member over [from]…[to], each day given its status.
  /// [weekend] holds `DateTime.weekday` values; [today] splits past from
  /// upcoming.
  factory AttendanceMonth.fromReport(
    FieldReport report, {
    required DateTime from,
    required DateTime to,
    required Set<int> weekend,
    required DateTime today,
  }) {
    final byDay = {
      for (final bucket in report.days)
        AppDateUtils.toApiDateOnly(bucket.day): bucket,
    };
    final last = AppDateUtils.dateOnly(today);
    final days = <AttendanceDay>[];
    var workingDays = 0;
    for (
      var day = AppDateUtils.dateOnly(from);
      !day.isAfter(to);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final bucket = byDay[AppDateUtils.toApiDateOnly(day)];
      final restDay = weekend.contains(day.weekday);
      if (!restDay && !day.isAfter(last)) workingDays++;
      days.add(
        AttendanceDay(
          date: day,
          status: _statusOf(
            bucket,
            restDay: restDay,
            future: day.isAfter(last),
          ),
          workedMinutes: ((bucket?.avgHours ?? 0) * 60).round(),
        ),
      );
    }
    return AttendanceMonth(
      from: AppDateUtils.dateOnly(from),
      days: days,
      summary: AttendanceSummary(
        workingDays: workingDays,
        present: report.daysPresent,
        late: report.late,
        leave: report.leave,
        absent: report.absent,
        workedMinutes: days.fold(0, (sum, d) => sum + d.workedMinutes),
      ),
    );
  }

  static AttendanceStatus _statusOf(
    FieldReportBucket? bucket, {
    required bool restDay,
    required bool future,
  }) {
    if (bucket != null) {
      if (bucket.late > 0) return AttendanceStatus.late;
      if (bucket.present > 0) return AttendanceStatus.present;
      if (bucket.leave > 0) return AttendanceStatus.leave;
      if (bucket.absent > 0) return AttendanceStatus.absent;
    }
    if (future) return AttendanceStatus.upcoming;
    return restDay ? AttendanceStatus.off : AttendanceStatus.none;
  }
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
    this.inOffice,
    this.summary,
  });

  final String memberId;
  final String name;

  /// Today's status, or the worst status in the period.
  final AttendanceStatus status;
  final DateTime? checkInAt;
  final bool? inOffice;
  final AttendanceSummary? summary;

  /// A row of `GET attendance` for one day.
  factory TeamAttendanceRow.fromDay(Map<String, dynamic> json) {
    final log = AttendanceLog.fromJson(json);
    return TeamAttendanceRow(
      memberId: jsonId(json['membershipId']) ?? '',
      name: json['name'] as String? ?? '',
      status: log.status ?? AttendanceStatus.upcoming,
      checkInAt: log.checkInAt,
      inOffice: log.inOffice,
    );
  }

  /// A person's totals over a period of [workingDays].
  factory TeamAttendanceRow.fromPerson(
    FieldReportPerson person, {
    required int workingDays,
  }) => TeamAttendanceRow(
    memberId: person.memberId,
    name: person.name,
    status: person.absent > 0
        ? AttendanceStatus.absent
        : person.late > 0
        ? AttendanceStatus.late
        : person.daysPresent > 0
        ? AttendanceStatus.present
        : AttendanceStatus.none,
    summary: AttendanceSummary(
      workingDays: workingDays,
      present: person.daysPresent,
      late: person.late,
      absent: person.absent,
    ),
  );
}

/// One member's month from `GET attendance?period=yyyy-MM`.
class AttendancePeriodRow {
  const AttendancePeriodRow({
    required this.memberId,
    required this.name,
    this.present = 0,
    this.late = 0,
    this.halfDays = 0,
    this.absent = 0,
    this.leave = 0,
    this.distanceKm = 0,
  });

  final String memberId;
  final String name;
  final int present;
  final int late;
  final int halfDays;
  final int absent;
  final int leave;
  final double distanceKm;

  factory AttendancePeriodRow.fromJson(Map<String, dynamic> json) =>
      AttendancePeriodRow(
        memberId: jsonId(json['membershipId']) ?? '',
        name: json['name'] as String? ?? '',
        present: jsonInt(json['presentDays']) ?? 0,
        late: jsonInt(json['lateDays']) ?? 0,
        halfDays: jsonInt(json['halfDays']) ?? 0,
        absent: jsonInt(json['absentDays']) ?? 0,
        leave: jsonInt(json['leaveDays']) ?? 0,
        distanceKm: jsonDouble(json['distanceKm']) ?? 0,
      );
}

class TeamAttendanceSummary {
  const TeamAttendanceSummary({
    this.present = 0,
    this.late = 0,
    this.leave = 0,
    this.absent = 0,
  });

  final int present;
  final int late;
  final int leave;
  final int absent;
}

/// The team list for one period, with its totals.
class TeamAttendance {
  const TeamAttendance({required this.rows, required this.summary});

  final List<TeamAttendanceRow> rows;
  final TeamAttendanceSummary summary;

  /// Today's rows, counted by status.
  factory TeamAttendance.ofDay(List<TeamAttendanceRow> rows) {
    int count(bool Function(AttendanceStatus s) test) =>
        rows.where((row) => test(row.status)).length;
    return TeamAttendance(
      rows: rows,
      summary: TeamAttendanceSummary(
        present: count((s) => s.attended),
        late: count((s) => s == AttendanceStatus.late),
        leave: count((s) => s == AttendanceStatus.leave),
        absent: count((s) => s == AttendanceStatus.absent),
      ),
    );
  }
}

/// The server's dates are calendar days ("2026-10-05" or
/// "2026-10-05T00:00:00"), read as local days.
DateTime? _day(dynamic value) {
  if (value is! String || value.length < 10) return null;
  final parsed = DateTime.tryParse(value.substring(0, 10));
  return parsed == null ? null : AppDateUtils.dateOnly(parsed);
}

String? _blankToNull(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}
