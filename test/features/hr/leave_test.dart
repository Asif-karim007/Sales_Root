import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/leave_fixtures.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/providers/leave_providers.dart';

import 'hr_test_utils.dart';

void main() {
  group('leaveDays', () {
    final saturday = DateTime(2026, 10, 3);

    test('counts both ends and skips the Friday off', () {
      expect(leaveDays(saturday, DateTime(2026, 10, 4)), 2);
      expect(leaveDays(saturday, DateTime(2026, 10, 10)), 7);
    });

    test('a half day takes half of the last day', () {
      expect(leaveDays(saturday, saturday, halfDay: true), 0.5);
      expect(leaveDays(saturday, DateTime(2026, 10, 4), halfDay: true), 1.5);
    });

    test('an end before the start is no days', () {
      expect(leaveDays(DateTime(2026, 10, 4), saturday), 0);
    });
  });

  group('leave balance', () {
    test('a request ties up days, half days included', () async {
      final container = await hrContainer();
      final repository = container.read(leaveRepositoryProvider);
      double free(List<LeaveBalance> list) => list
          .firstWhere((b) => b.leaveTypeId == casualLeaveId)
          .remainingAfterPending;

      final before = free(await repository.balances());
      final start = _nextSaturday(DateTime.now().add(const Duration(days: 40)));
      await repository.create(
        LeaveInput(
          leaveTypeId: casualLeaveId,
          startDate: start,
          endDate: start.add(const Duration(days: 1)),
          noOfDays: leaveDays(
            start,
            start.add(const Duration(days: 1)),
            halfDay: true,
          ),
          reason: 'Family event',
        ),
      );

      expect(free(await repository.balances()), before - 1.5);
    });

    test('more days than the balance is refused', () async {
      final container = await hrContainer();
      final repository = container.read(leaveRepositoryProvider);
      final start = _nextSaturday(DateTime.now().add(const Duration(days: 60)));

      await expectLater(
        repository.create(
          LeaveInput(
            leaveTypeId: sickLeaveId,
            startDate: start,
            endDate: start.add(const Duration(days: 20)),
            noOfDays: 18,
          ),
        ),
        throwsA(isA<ApiFailure>().having((f) => f.statusCode, 'status', 400)),
      );
    });

    test('the draft flags a request over the balance', () {
      const types = [LeaveType(id: 1, name: _casual, entitlement: 10)];
      const balances = [
        LeaveBalance(
          leaveTypeId: 1,
          leaveType: _casual,
          entitlement: 10,
          remainingAfterPending: 1,
        ),
      ];
      final saturday = DateTime(2026, 10, 3);
      final draft = LeaveDraft(
        leaveTypeId: 1,
        start: saturday,
        end: DateTime(2026, 10, 4),
      );

      expect(draft.errors(types, balances), {LeaveField.balance});
      expect(draft.copyWith(halfDay: true).errors(types, balances), {
        LeaveField.balance,
      });
      expect(
        draft.copyWith(end: saturday, halfDay: true).errors(types, balances),
        isEmpty,
      );
    });
  });

  group('leave form', () {
    test('submitting adds the request to the list', () async {
      final container = await hrContainer();
      keep(container, leaveListProvider);
      final form = leaveFormProvider;
      keep(container, form);
      await container.read(form.future);
      final before = (await container.read(
        leaveListProvider.future,
      )).totalCount;
      final start = _nextSaturday(DateTime.now().add(const Duration(days: 50)));

      container
          .read(form.notifier)
          .edit(
            (d) => d.copyWith(
              leaveTypeId: casualLeaveId,
              start: start,
              end: start,
              reason: 'Bank-e kaj',
            ),
          );
      await container.read(form.notifier).submit();

      expect(container.read(form).value?.submission.value?.noOfDays, 1);
      expect(
        (await container.read(leaveListProvider.future)).totalCount,
        before + 1,
      );
    });

    test('a form without dates shows its errors and sends nothing', () async {
      final container = await hrContainer();
      keep(container, leaveFormProvider);
      await container.read(leaveFormProvider.future);

      await container.read(leaveFormProvider.notifier).submit();

      final state = container.read(leaveFormProvider).value;
      expect(state?.showErrors, isTrue);
      expect(state?.errors, contains(LeaveField.dates));
      expect(state?.submission.value, isNull);
    });

    test('offline shows as a failure', () async {
      final container = await hrContainer();
      setOffline(container, true);
      keep(container, leaveListProvider);

      await expectLater(
        container.read(leaveListProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });

    test('the lookups name the manager as approver', () async {
      final container = await hrContainer();
      final lookups = await container.read(leaveRepositoryProvider).lookups();

      expect(lookups.approverName?.en, 'Rafiqul Islam');
      expect(lookups.leaveTypes, hasLength(leaveTypeRows.length));
    });
  });
}

const _casual = LocalizedName('Casual', 'নৈমিত্তিক');

DateTime _nextSaturday(DateTime from) {
  var day = DateTime(from.year, from.month, from.day);
  while (day.weekday != DateTime.saturday) {
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return day;
}
