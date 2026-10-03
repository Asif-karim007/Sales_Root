import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';

import 'field_force_harness.dart';

void main() {
  group('my attendance', () {
    late ProviderContainer container;

    setUp(() async {
      container = await fieldForceContainer();
      keepAlive(container, attendanceTodayProvider);
    });

    tearDown(() => container.dispose());

    test('check in, take a break, check out', () async {
      final notifier = container.read(attendanceTodayProvider.notifier);
      final before = await container.read(attendanceTodayProvider.future);
      expect(before.log, isNull);
      expect(before.week, hasLength(7));

      final log = await notifier.checkIn();
      expect(log.isCheckedIn, isTrue);
      expect(log.checkInPlace?.location, 'Gulshan-1, Dhaka');
      expect(log.checkInDistance, 0);

      final today = await container.read(attendanceTodayProvider.future);
      expect(today.log?.isCheckedIn, isTrue);
      expect(today.events.map((e) => e.kind), contains(DayEventKind.checkIn));

      await notifier.toggleBreak();
      expect(
        (await container.read(attendanceTodayProvider.future)).log?.onBreak,
        isTrue,
      );
      await notifier.toggleBreak();

      final out = await notifier.checkOut();
      expect(out.isCheckedOut, isTrue);
      expect(out.breaks.single.end, isNotNull);
      expect(out.workedMinutes, isNotNull);
    });

    test('a second check-in the same day is a conflict', () async {
      final notifier = container.read(attendanceTodayProvider.notifier);
      await notifier.checkIn();
      await expectLater(
        notifier.checkIn(),
        throwsA(isA<ApiFailure>().having((f) => f.isConflict, '409', true)),
      );
    });

    test('checking out before checking in is refused', () async {
      await expectLater(
        container.read(attendanceTodayProvider.notifier).checkOut(),
        throwsA(isA<ApiFailure>().having((f) => f.isConflict, '409', true)),
      );
    });

    test('the month lists every day with a summary', () async {
      keepAlive(container, attendanceMonthProvider);
      final cursor = container.read(attendanceMonthCursorProvider.notifier);
      cursor.previous();
      final month = await container.read(attendanceMonthProvider.future);
      final last = DateTime(month.month.year, month.month.month + 1, 0).day;
      expect(month.days, hasLength(last));
      expect(month.summary.workingDays, greaterThan(15));
      expect(
        month.summary.present + month.summary.leave + month.summary.absent,
        month.summary.workingDays,
      );
      expect(
        month.days.where((d) => d.date.weekday == DateTime.friday),
        everyElement(
          isA<AttendanceDay>().having(
            (d) => d.status,
            'status',
            AttendanceStatus.off,
          ),
        ),
      );
    });
  });

  group('team attendance', () {
    test('pages 20 members at a time', () async {
      final container = await fieldForceContainer(role: WorkspaceRole.teamLead);
      addTearDown(container.dispose);
      keepAlive(container, teamAttendanceProvider);
      final first = await container.read(teamAttendanceProvider.future);
      expect(first.items, hasLength(20));
      expect(first.hasMore, isTrue);

      await container.read(teamAttendanceProvider.notifier).loadMore();
      final all = container.read(teamAttendanceProvider).requireValue;
      expect(all.items.length, all.totalCount);
      expect(all.hasMore, isFalse);
      expect(
        all.items.map((r) => r.memberId).toSet(),
        hasLength(all.totalCount),
      );
    });

    test('is forbidden to a member', () async {
      final container = await fieldForceContainer(role: WorkspaceRole.member);
      addTearDown(container.dispose);
      await expectLater(
        container
            .read(attendanceRepositoryProvider)
            .team(const TeamAttendanceQuery()),
        throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
      );
    });
  });
}
