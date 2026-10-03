import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/field_force/data/attendance_repository.dart';
import 'package:salesroot/features/field_force/data/fake_attendance_repository.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/location_providers.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';

part 'attendance_providers.g.dart';

@Riverpod(keepAlive: true)
AttendanceRepository attendanceRepository(Ref ref) =>
    FakeAttendanceRepository(ref.watch(fakeBackendProvider));

/// The user's attendance today: punch in and out, and breaks.
@riverpod
class AttendanceTodayNotifier extends _$AttendanceTodayNotifier {
  @override
  Future<AttendanceToday> build() =>
      ref.watch(attendanceRepositoryProvider).today();

  Future<AttendanceLog> checkIn() async {
    final log = await ref
        .read(attendanceRepositoryProvider)
        .checkIn(await _punch());
    if (ref.mounted) ref.invalidateSelf();
    return log;
  }

  Future<AttendanceLog> checkOut() async {
    final log = await ref
        .read(attendanceRepositoryProvider)
        .checkOut(await _punch());
    if (ref.mounted) ref.invalidateSelf();
    return log;
  }

  Future<void> toggleBreak() async {
    final repository = ref.read(attendanceRepositoryProvider);
    final onBreak = state.value?.log?.onBreak ?? false;
    await (onBreak ? repository.endBreak() : repository.startBreak());
    if (ref.mounted) ref.invalidateSelf();
  }

  /// Where the phone is; a punch without a fix is still recorded.
  Future<AttendancePunch> _punch() async {
    final location = ref.read(locationSourceProvider);
    try {
      final fix = await location.current().timeout(const Duration(seconds: 25));
      return AttendancePunch(
        latitude: fix.latitude,
        longitude: fix.longitude,
        location: await location.placeName(fix.latitude, fix.longitude),
      );
    } on LocationFailure {
      return const AttendancePunch();
    } on TimeoutException {
      return const AttendancePunch();
    }
  }
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
class AttendanceMonthNotifier extends _$AttendanceMonthNotifier {
  @override
  Future<AttendanceMonth> build() => ref
      .watch(attendanceRepositoryProvider)
      .month(ref.watch(attendanceMonthCursorProvider));

  Future<void> requestCorrection(DateTime date, String reason) async {
    await ref
        .read(attendanceRepositoryProvider)
        .requestCorrection(date, reason);
    if (ref.mounted) ref.invalidateSelf();
  }
}

@riverpod
class TeamAttendanceFilter extends _$TeamAttendanceFilter {
  @override
  TeamAttendanceQuery build() => const TeamAttendanceQuery();

  void setPeriod(TeamPeriod period) =>
      state = state.copyWith(period: period, correctionsOnly: false);

  void toggleCorrections() =>
      state = state.copyWith(correctionsOnly: !state.correctionsOnly);
}

@riverpod
Future<TeamAttendanceSummary> teamAttendanceSummary(Ref ref) => ref
    .watch(attendanceRepositoryProvider)
    .teamSummary(
      ref.watch(teamAttendanceFilterProvider.select((q) => q.period)),
    );

/// The team's attendance, 20 members at a time.
@riverpod
class TeamAttendanceNotifier extends _$TeamAttendanceNotifier {
  @override
  Future<Paged<TeamAttendanceRow>> build() async => Paged.first(
    await ref
        .watch(attendanceRepositoryProvider)
        .team(ref.watch(teamAttendanceFilterProvider)),
  );

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(attendanceRepositoryProvider)
          .team(
            ref
                .read(teamAttendanceFilterProvider)
                .copyWith(page: current.page + 1),
          );
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> resolve(TeamAttendanceRow row, {required bool approve}) async {
    await ref
        .read(attendanceRepositoryProvider)
        .resolveCorrection(
          row.memberId,
          row.correctionDate ?? DateTime.now(),
          approve: approve,
        );
    if (!ref.mounted) return;
    ref.invalidateSelf();
    ref.invalidate(teamAttendanceSummaryProvider);
  }
}
