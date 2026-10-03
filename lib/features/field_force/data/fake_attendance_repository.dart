import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/data/attendance_fixtures.dart';
import 'package:salesroot/features/field_force/data/attendance_repository.dart';
import 'package:salesroot/features/field_force/data/fake_field_data.dart';
import 'package:salesroot/features/field_force/data/visit_fixtures.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/service/geo.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository(this._backend) : _data = FakeFieldData(_backend);

  final FakeBackend _backend;
  final FakeFieldData _data;

  FakeTable get _logs => _data.attendance;
  int get _me => _backend.meId;

  @override
  Future<AttendanceToday> today() => _backend.run('Attendance today', () {
    final now = DateTime.now();
    final today = AppDateUtils.dateOnly(now);
    final settings = _data.settings;
    final log = _data.logOf(_me, today);
    final saturday = today.subtract(Duration(days: (today.weekday + 1) % 7));
    return AttendanceToday.fromJson({
      'Date': jsonUtc(today),
      'ShiftStart': settings.dutyStart,
      'ShiftEnd': settings.dutyEnd,
      if (log != null && log['Kind'] == 'Log') 'Log': log,
      'Month': _data.summaryOf(
        _me,
        DateTime(today.year, today.month),
        today,
        now,
      ),
      'Week': [
        for (var i = 0; i < 7; i++)
          {
            'Date': jsonUtc(saturday.add(Duration(days: i))),
            'Status': _data
                .statusOf(_me, saturday.add(Duration(days: i)), now)
                .wire,
          },
      ],
      'Events': _data.events(_me, today, now),
    });
  }, module: AppModule.attendance);

  @override
  Future<AttendanceLog> checkIn(AttendancePunch punch) => _backend.run(
    'Attendance check-in',
    () {
      final now = DateTime.now();
      final today = AppDateUtils.dateOnly(now);
      final existing = _data.logOf(_me, today);
      if (existing != null && existing['Kind'] == 'Leave') {
        throw const ApiFailure(409, 'You are on approved leave today.');
      }
      if (existing != null) {
        throw const ApiFailure(409, 'You have already checked in today.');
      }
      final settings = _data.settings;
      final lateMinutes = now
          .difference(clockOn(today, settings.dutyStart))
          .inMinutes;
      final lat = punch.latitude;
      final lng = punch.longitude;
      final distance = lat == null || lng == null
          ? null
          : distanceMetres(lat, lng, officeLat, officeLng).round();
      final row = _logs.insert(
        {
          'EmployeeId': _me,
          'Date': jsonUtc(today),
          'Kind': 'Log',
          'CheckInAt': jsonUtc(now),
          'CheckInPlace': {
            'Latitude': lat,
            'Longitude': lng,
            'Location': punch.location ?? _placeName(lat, lng, distance),
          }..removeWhere((_, value) => value == null),
          'CheckInDistance': distance,
          'IsLate': lateMinutes > lateGraceMinutes,
          'LateMinutes': lateMinutes > 0 ? lateMinutes : 0,
          'Breaks': const <Map<String, dynamic>>[],
        }..removeWhere((_, value) => value == null),
      );
      return AttendanceLog.fromJson(row);
    },
    module: AppModule.attendance,
    right: ModuleRight.add,
  );

  @override
  Future<AttendanceLog> checkOut(AttendancePunch punch) => _backend.run(
    'Attendance check-out',
    () {
      final now = DateTime.now();
      final row = _openLog(now);
      final breaks = [
        for (final b in jsonList(row['Breaks'], (json) => json))
          {...b, 'End': b['End'] ?? jsonUtc(now)},
      ];
      final closed = {...row, 'Breaks': breaks, 'CheckOutAt': jsonUtc(now)};
      return AttendanceLog.fromJson(
        _logs.update(row['Id'] as int, {
          'Breaks': breaks,
          'CheckOutAt': jsonUtc(now),
          'CheckOutPlace': {
            'Latitude': punch.latitude,
            'Longitude': punch.longitude,
            'Location': punch.location,
          }..removeWhere((_, value) => value == null),
          'WorkedMinutes': AttendanceLog.fromJson(closed).workedUntil(now),
          'IsEarlyOut': now.isBefore(clockOn(now, _data.settings.dutyEnd)),
        }),
      );
    },
    module: AppModule.attendance,
    right: ModuleRight.add,
  );

  @override
  Future<AttendanceLog> startBreak() => _backend.run(
    'Attendance break start',
    () {
      final now = DateTime.now();
      final row = _openLog(now);
      final breaks = jsonList(row['Breaks'], (json) => json);
      if (breaks.isNotEmpty && breaks.last['End'] == null) {
        throw const ApiFailure(409, 'A break is already running.');
      }
      return AttendanceLog.fromJson(
        _logs.update(row['Id'] as int, {
          'Breaks': [
            ...breaks,
            {'Start': jsonUtc(now)},
          ],
        }),
      );
    },
    module: AppModule.attendance,
    right: ModuleRight.add,
  );

  @override
  Future<AttendanceLog> endBreak() => _backend.run(
    'Attendance break end',
    () {
      final now = DateTime.now();
      final row = _openLog(now);
      final breaks = jsonList(row['Breaks'], (json) => json);
      if (breaks.isEmpty || breaks.last['End'] != null) {
        throw const ApiFailure(409, 'No break is running.');
      }
      return AttendanceLog.fromJson(
        _logs.update(row['Id'] as int, {
          'Breaks': [
            ...breaks.take(breaks.length - 1),
            {...breaks.last, 'End': jsonUtc(now)},
          ],
        }),
      );
    },
    module: AppModule.attendance,
    right: ModuleRight.add,
  );

  @override
  Future<AttendanceMonth> month(DateTime month) =>
      _backend.run('Attendance month', () {
        final now = DateTime.now();
        final first = DateTime(month.year, month.month);
        final last = DateTime(month.year, month.month + 1, 0);
        final today = AppDateUtils.dateOnly(now);
        return AttendanceMonth.fromJson({
          'Month': jsonUtc(first),
          'Days': _data.monthDays(_me, first, now),
          'Summary': _data.summaryOf(
            _me,
            first,
            last.isAfter(today) ? today : last,
            now,
          ),
        });
      }, module: AppModule.attendance);

  @override
  Future<void> requestCorrection(DateTime date, String reason) => _backend.run(
    'Attendance correction',
    () {
      fakeRequire({'Reason': reason}, ['Reason']);
      final existing = _data.correctionOf(_me, date);
      if (existing != null && existing['Status'] == 'Pending') {
        throw const ApiFailure(409, 'A correction for this day is pending.');
      }
      _data.corrections.insert({
        'EmployeeId': _me,
        'Date': jsonUtc(AppDateUtils.dateOnly(date)),
        'Reason': reason.trim(),
        'Status': 'Pending',
      });
    },
    module: AppModule.attendance,
    right: ModuleRight.add,
  );

  @override
  Future<TeamAttendanceSummary> teamSummary(TeamPeriod period) =>
      _backend.run('Team attendance summary', () {
        final now = DateTime.now();
        final rows = [for (final m in _team()) _row(m, period, now)];
        int count(AttendanceStatus status) =>
            rows.where((r) => r['Status'] == status.wire).length;
        int sum(String key) => rows.fold(
          0,
          (total, r) =>
              total +
              (jsonInt((r['Summary'] as Map<String, dynamic>?)?[key]) ?? 0),
        );
        final today = period == TeamPeriod.today;
        return TeamAttendanceSummary.fromJson({
          'Present': today
              ? count(AttendanceStatus.present) + count(AttendanceStatus.late)
              : sum('Present'),
          'Late': today ? count(AttendanceStatus.late) : sum('Late'),
          'Leave': today ? count(AttendanceStatus.leave) : sum('Leave'),
          'Absent': today ? count(AttendanceStatus.absent) : sum('Absent'),
          'Corrections': rows.where((r) => r['Correction'] == 'Pending').length,
        });
      }, module: AppModule.teamAttendance);

  @override
  Future<PageResult<TeamAttendanceRow>> team(TeamAttendanceQuery query) =>
      _backend.run('Team attendance', () {
        final now = DateTime.now();
        final rows = [
          for (final member in _team())
            if (_row(member, query.period, now) case final row
                when !query.correctionsOnly || row['Correction'] == 'Pending')
              row,
        ];
        return PageResult.fromJson(
          fakePage(rows, page: query.page),
          TeamAttendanceRow.fromJson,
        );
      }, module: AppModule.teamAttendance);

  @override
  Future<void> resolveCorrection(
    int memberId,
    DateTime date, {
    required bool approve,
  }) => _backend.run(
    'Attendance correction resolve',
    () {
      final row = _data.correctionOf(memberId, date);
      if (row == null || row['Status'] != 'Pending') {
        throw const ApiFailure(409, 'This correction was already handled.');
      }
      _data.corrections.update(row['Id'] as int, {
        'Status': approve ? 'Approved' : 'Rejected',
      });
    },
    module: AppModule.teamAttendance,
    right: ModuleRight.approve,
  );

  @override
  Future<List<TeamAttendanceRow>> teamMonth(DateTime month) => _backend.run(
    'Team attendance month',
    () {
      final now = DateTime.now();
      final first = DateTime(month.year, month.month);
      final last = DateTime(month.year, month.month + 1, 0);
      final today = AppDateUtils.dateOnly(now);
      return [
        for (final member in _team())
          TeamAttendanceRow.fromJson({
            ...memberJson(member),
            'MemberId': member.id,
            'Status': AttendanceStatus.present.wire,
            'Summary': _data.summaryOf(
              member.id,
              first,
              last.isAfter(today) ? today : last,
              now,
            ),
          }),
      ];
    },
    module: AppModule.teamAttendance,
    right: ModuleRight.export,
  );

  List<SeedMember> _team() => [
    for (final member in fieldMembers(_backend.graph))
      if (member.id != _me) member,
  ];

  Map<String, dynamic> _row(
    SeedMember member,
    TeamPeriod period,
    DateTime now,
  ) {
    final today = AppDateUtils.dateOnly(now);
    final base = {...memberJson(member), 'MemberId': member.id};
    if (period == TeamPeriod.today) {
      final log = _data.logOf(member.id, today);
      final correction = _data.correctionOf(member.id, today);
      final place = log?['CheckInPlace'] as Map<String, dynamic>?;
      return {
        ...base,
        'Status': _data.statusOf(member.id, today, now).wire,
        'CheckInAt': log?['CheckInAt'],
        'Place': place?['Location'],
        'LateMinutes': log?['LateMinutes'],
        'Correction': correction?['Status'],
        'CorrectionDate': correction?['Date'],
        'CorrectionReason': correction?['Reason'],
      }..removeWhere((_, value) => value == null);
    }
    final from = period == TeamPeriod.week
        ? today.subtract(Duration(days: (today.weekday + 1) % 7))
        : DateTime(today.year, today.month);
    final summary = _data.summaryOf(member.id, from, today, now);
    final pending = _data.corrections.rows
        .where(
          (c) =>
              c['EmployeeId'] == member.id &&
              c['Status'] == 'Pending' &&
              !(jsonDate(c['Date']) ?? today).isBefore(from),
        )
        .firstOrNull;
    final status = (summary['Absent'] as int) > 0
        ? AttendanceStatus.absent
        : (summary['Late'] as int) > 0
        ? AttendanceStatus.late
        : AttendanceStatus.present;
    return {
      ...base,
      'Status': status.wire,
      'Summary': summary,
      if (pending != null) ...{
        'Correction': 'Pending',
        'CorrectionDate': pending['Date'],
        'CorrectionReason': pending['Reason'],
      },
    };
  }

  Map<String, dynamic> _openLog(DateTime now) {
    final row = _data.logOf(_me, now);
    if (row == null || row['Kind'] != 'Log' || row['CheckOutAt'] != null) {
      throw const ApiFailure(409, 'You are not checked in.');
    }
    return row;
  }

  String? _placeName(double? lat, double? lng, int? distance) {
    if (lat == null || lng == null || distance == null) return null;
    if (distance <= 300) return officeName;
    return '${_data.nearestArea(lat, lng).name}, Dhaka';
  }
}
