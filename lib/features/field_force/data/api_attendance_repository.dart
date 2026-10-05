import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/data/attendance_repository.dart';
import 'package:salesroot/features/field_force/data/field_api.dart';
import 'package:salesroot/features/field_force/data/field_sources.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';

/// Attendance over `/attendance` and the per-day trend of `reports/field`.
class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository(this._api, {this.me, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      _workspace = FieldWorkspaceSource(_api);

  final FieldApi _api;

  /// The user's membership id in the current workspace.
  final String? me;
  final DateTime Function() _clock;
  final FieldWorkspaceSource _workspace;

  @override
  Future<AttendanceToday> today() async => AttendanceToday.fromJson(
    jsonMap(await apiRequest('Attendance today', _api.today)),
  );

  @override
  Future<AttendanceLog> checkIn(AttendancePunch punch) async =>
      AttendanceLog.fromJson(
        jsonMap(
          await apiRequest(
            'Check-in',
            () => _api.checkIn(punch.toCheckInJson()),
          ),
        ),
      );

  @override
  Future<AttendanceLog> checkOut(AttendancePunch punch) async =>
      AttendanceLog.fromJson(
        jsonMap(
          await apiRequest(
            'Check-out',
            () => _api.checkOut(punch.toCheckOutJson()),
          ),
        ),
      );

  @override
  Future<String> uploadSelfie(String path) => uploadPhoto(
    _api,
    entityType: 'attendance',
    entityId: me ?? '',
    path: path,
  );

  @override
  Future<AttendanceMonth> days(DateTime from, DateTime to) async {
    final report = _report(from, to, member: me);
    final workspace = _workspace.get();
    await Future.wait([report, workspace]);
    return AttendanceMonth.fromReport(
      await report,
      from: from,
      to: to,
      weekend: (await workspace).weekend,
      today: _clock(),
    );
  }

  @override
  Future<TeamAttendance> team(TeamPeriod period) async {
    final today = AppDateUtils.dateOnly(_clock());
    if (period == TeamPeriod.today) {
      final json = await apiRequest(
        'Team attendance',
        () => _api.attendance({'day': AppDateUtils.toApiDateOnly(today)}),
      );
      final rows = json is List ? json : const [];
      return TeamAttendance.ofDay([
        for (final row in rows)
          if (row is Map<String, dynamic>) TeamAttendanceRow.fromDay(row),
      ]);
    }
    final (from, to) = period == TeamPeriod.week
        ? weekAround(today)
        : (DateTime(today.year, today.month), today);
    final loading = _report(from, to);
    final workspace = _workspace.get();
    await Future.wait([loading, workspace]);
    final report = await loading;
    final month = AttendanceMonth.fromReport(
      report,
      from: from,
      to: to,
      weekend: (await workspace).weekend,
      today: today,
    );
    return TeamAttendance(
      rows: [
        for (final person in report.people)
          TeamAttendanceRow.fromPerson(
            person,
            workingDays: month.summary.workingDays,
          ),
      ],
      summary: TeamAttendanceSummary(
        present: report.daysPresent,
        late: report.late,
        leave: report.leave,
        absent: report.absent,
      ),
    );
  }

  @override
  Future<List<AttendancePeriodRow>> teamMonth(DateTime month) async {
    final period = AppDateUtils.toApiDateOnly(month).substring(0, 7);
    final json = await apiRequest(
      'Team attendance $period',
      () => _api.attendance({'period': period}),
    );
    return json is List
        ? [
            for (final row in json)
              if (row is Map<String, dynamic>)
                AttendancePeriodRow.fromJson(row),
          ]
        : const [];
  }

  Future<FieldReport> _report(
    DateTime from,
    DateTime to, {
    String? member,
  }) async {
    final json = await apiRequest(
      'Field report',
      () => _api.report({
        'from': AppDateUtils.toApiDateOnly(from),
        'to': AppDateUtils.toApiDateOnly(to),
        'group': 'day',
        'ownerId': member,
      }),
    );
    return FieldReport.fromJson(jsonMap(json));
  }
}
