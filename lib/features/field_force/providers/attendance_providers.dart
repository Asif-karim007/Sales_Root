import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/field_force/data/api_attendance_repository.dart';
import 'package:salesroot/features/field_force/data/attendance_repository.dart';
import 'package:salesroot/features/field_force/data/field_api.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';
import 'package:salesroot/features/field_force/providers/location_providers.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';

part 'attendance_providers.g.dart';

@Riverpod(keepAlive: true)
FieldApi fieldApi(Ref ref) => FieldApi(ref.watch(dioProvider));

/// The user's membership id, rebuilding each repository on a workspace
/// switch.
String? fieldMember(Ref ref) => ref
    .watch(currentWorkspaceProvider.select((w) => (w?.id, w?.membershipId)))
    .$2;

@Riverpod(keepAlive: true)
AttendanceRepository attendanceRepository(Ref ref) =>
    ApiAttendanceRepository(ref.watch(fieldApiProvider), me: fieldMember(ref));

/// The user's attendance today: the punch, today's visits and route.
@riverpod
class AttendanceTodayNotifier extends _$AttendanceTodayNotifier {
  @override
  Future<AttendanceToday> build() =>
      ref.watch(attendanceRepositoryProvider).today();

  /// Checks in where the phone is. [selfiePath] is uploaded first; [reason]
  /// answers a server that asks why the check-in is outside the office.
  Future<AttendanceLog> checkIn({String? selfiePath, String? reason}) async {
    final repository = ref.read(attendanceRepositoryProvider);
    var punch = await _punch(needFix: true);
    if (selfiePath != null) {
      punch = punch.copyWith(
        photoKey: await repository.uploadSelfie(selfiePath),
      );
    }
    final log = await repository.checkIn(punch.copyWith(reason: reason));
    _refresh();
    return log;
  }

  Future<AttendanceLog> checkOut() async {
    final log = await ref
        .read(attendanceRepositoryProvider)
        .checkOut(await _punch(needFix: false));
    _refresh();
    return log;
  }

  void _refresh() {
    if (!ref.mounted) return;
    ref
      ..invalidate(attendanceWeekProvider)
      ..invalidate(attendanceThisMonthProvider)
      ..invalidateSelf();
  }

  /// Where the phone is. A check-in needs a fix; a check-out without one is
  /// still recorded.
  Future<AttendancePunch> _punch({required bool needFix}) async {
    final location = ref.read(locationSourceProvider);
    try {
      final fix = await location.current().timeout(const Duration(seconds: 25));
      return AttendancePunch(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracy: fix.accuracy,
        mock: fix.isMocked,
      );
    } on LocationFailure {
      if (needFix) rethrow;
      return const AttendancePunch();
    } on TimeoutException {
      if (needFix) throw const LocationFailure(LocationIssue.unavailable);
      return const AttendancePunch();
    }
  }
}

/// Saturday to Friday of this week, day by day.
@riverpod
Future<AttendanceMonth> attendanceWeek(Ref ref) {
  final (from, to) = weekAround(DateTime.now());
  return ref.watch(attendanceRepositoryProvider).days(from, to);
}

/// This calendar month's totals.
@riverpod
Future<AttendanceSummary> attendanceThisMonth(Ref ref) async {
  final now = DateTime.now();
  final month = await ref
      .watch(attendanceRepositoryProvider)
      .days(
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1, 0),
      );
  return month.summary;
}

@riverpod
class AttendanceMonthCursor extends _$AttendanceMonthCursor {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get canGoNext {
    final now = DateTime.now();
    return state.isBefore(DateTime(now.year, now.month));
  }

  void previous() => state = DateTime(state.year, state.month - 1);

  void next() {
    if (canGoNext) state = DateTime(state.year, state.month + 1);
  }
}

@riverpod
Future<AttendanceMonth> attendanceMonth(Ref ref) {
  final month = ref.watch(attendanceMonthCursorProvider);
  return ref
      .watch(attendanceRepositoryProvider)
      .days(month, DateTime(month.year, month.month + 1, 0));
}

@riverpod
class TeamAttendancePeriod extends _$TeamAttendancePeriod {
  @override
  TeamPeriod build() => TeamPeriod.today;

  void set(TeamPeriod period) => state = period;
}

/// The team's attendance for the chosen period.
@riverpod
Future<TeamAttendance> teamAttendance(Ref ref) => ref
    .watch(attendanceRepositoryProvider)
    .team(ref.watch(teamAttendancePeriodProvider));
