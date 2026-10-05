import 'package:salesroot/features/field_force/models/attendance.dart';

abstract interface class AttendanceRepository {
  /// The user's day: the punch, today's visits and route, and the field
  /// settings.
  Future<AttendanceToday> today();

  /// A 422 on `reason` when the server wants to know why the check-in is
  /// outside the office.
  Future<AttendanceLog> checkIn(AttendancePunch punch);

  Future<AttendanceLog> checkOut(AttendancePunch punch);

  /// Uploads a check-in selfie and returns its file key.
  Future<String> uploadSelfie(String path);

  /// The user's days from [from] to [to], each with its status, and their
  /// totals.
  Future<AttendanceMonth> days(DateTime from, DateTime to);

  /// The team's attendance today, or its totals this week or month.
  Future<TeamAttendance> team(TeamPeriod period);

  /// Every member's totals for [month], for the monthly report download.
  Future<List<AttendancePeriodRow>> teamMonth(DateTime month);
}
