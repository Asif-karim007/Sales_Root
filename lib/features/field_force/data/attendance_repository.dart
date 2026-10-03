import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';

abstract interface class AttendanceRepository {
  /// The user's day: punch, shift, this week, this month and the timeline.
  Future<AttendanceToday> today();

  /// 409 when already checked in today.
  Future<AttendanceLog> checkIn(AttendancePunch punch);

  /// 409 when not checked in.
  Future<AttendanceLog> checkOut(AttendancePunch punch);

  Future<AttendanceLog> startBreak();

  Future<AttendanceLog> endBreak();

  Future<AttendanceMonth> month(DateTime month);

  Future<void> requestCorrection(DateTime date, String reason);

  Future<TeamAttendanceSummary> teamSummary(TeamPeriod period);

  Future<PageResult<TeamAttendanceRow>> team(TeamAttendanceQuery query);

  Future<void> resolveCorrection(
    int memberId,
    DateTime date, {
    required bool approve,
  });

  /// Every member's totals for [month], for the monthly report download.
  Future<List<TeamAttendanceRow>> teamMonth(DateTime month);
}
