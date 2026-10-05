import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/hr/data/hr_repositories.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/providers/leave_providers.dart';

import '../../helpers/api_stub.dart';
import 'hr_test_setup.dart';

void main() {
  group('leaveDays', () {
    final tuesday = DateTime(2026, 10, 6);

    test('counts both ends and skips the Friday off', () {
      expect(leaveDays(tuesday, DateTime(2026, 10, 10)), 4);
      expect(leaveDays(tuesday, tuesday), 1);
    });

    test('a half day takes half of the last day', () {
      expect(leaveDays(tuesday, tuesday, halfDay: true), 0.5);
    });

    test('an end before the start is no days', () {
      expect(leaveDays(tuesday, DateTime(2026, 10, 5)), 0);
    });

    test('a holiday is not counted', () {
      final days = leaveDays(
        tuesday,
        DateTime(2026, 10, 8),
        holidays: {DateTime(2026, 10, 7)},
      );
      expect(days, 2);
    });
  });

  group('parsing', () {
    test('types, balances and requests read the real JSON', () async {
      final container = await hrContainer(hrStub());
      final repository = container.read(leaveRepositoryProvider);

      final lookups = await repository.lookups();
      expect(lookups.leaveTypes.map((t) => t.name.en), [
        'Casual leave',
        'Sick leave',
        'Unpaid leave',
      ]);
      final sick = lookups.leaveTypes[1];
      expect(sick.id, sickId);
      expect(sick.needsDocument(3), isTrue);
      expect(lookups.leaveTypes.last.isPaid, isFalse);
      expect(lookups.approverName, 'Rumpa Sarker');

      final balances = await repository.balances();
      final casual = balances.firstWhere((b) => b.leaveTypeId == casualId);
      expect(casual.leaveType.bn, 'নৈমিত্তিক ছুটি');
      expect(casual.entitlement, 10);
      expect(casual.pending, 2);
      expect(casual.remainingAfterPending, 8);

      final page = await repository.list(const LeaveQuery());
      final request = page.items.first;
      expect(request.status, LeaveStatus.pending);
      expect(request.noOfDays, 2);
      expect(request.startDate, DateTime(2026, 12, 22));
      expect(request.endDate, DateTime(2026, 12, 23));
      expect(request.employeeName, 'Rafi Ahmed');
      expect(request.canWithdraw, isTrue);
      expect(page.items.last.status, LeaveStatus.cancelled);
    });
  });

  group('list', () {
    test('the status chip filters and pages by offset', () async {
      final stub = hrStub()
        ..on('GET', 'hr/leave', (RequestOptions r) {
          return {...fixtureMap('hr_leave_list'), 'total': 45};
        });
      final container = await hrContainer(stub);
      listenTo(container, leaveListProvider);
      container
          .read(leaveStatusFilterProvider.notifier)
          .set(LeaveStatus.pending);

      await container.read(leaveListProvider.future);
      expect(stub.last('GET', 'hr/leave')?.queryParameters, {
        'status': 'pending',
        'offset': 0,
        'limit': 20,
      });

      await container.read(leaveListProvider.notifier).loadMore();
      expect(stub.last('GET', 'hr/leave')?.queryParameters['offset'], 20);
      expect(container.read(leaveListProvider).value?.items, hasLength(4));
    });

    test('withdrawing cancels the request', () async {
      final stub = hrStub();
      final container = await hrContainer(stub);
      listenTo(container, leaveWithdrawProvider);

      await container.read(leaveWithdrawProvider.notifier).withdraw('abc');

      expect(container.read(leaveWithdrawProvider).value, 'abc');
      expect(
        stub.last('POST', 'hr/leave/{id}/cancel')?.path,
        'hr/leave/abc/cancel',
      );
    });
  });

  group('form', () {
    late ProviderContainer container;

    Future<LeaveFormNotifier> openForm(ApiStub stub) async {
      container = await hrContainer(stub);
      listenTo(container, leaveFormProvider);
      await container.read(leaveFormProvider.future);
      return container.read(leaveFormProvider.notifier);
    }

    LeaveFormState? formState() => container.read(leaveFormProvider).value;

    test('submitting sends the request by date', () async {
      final stub = hrStub();
      final form = await openForm(stub);

      form.edit(
        (d) => d.copyWith(
          start: DateTime(2026, 12, 22),
          end: DateTime(2026, 12, 23),
          halfDay: true,
          reason: '  family event  ',
        ),
      );
      await form.submit();

      expect(formState()?.submission.value, isNotEmpty);
      expect(stub.lastBody('POST', 'hr/leave'), {
        'leaveTypeId': casualId,
        'fromDate': '2026-12-22',
        'toDate': '2026-12-23',
        'halfDay': 'second',
        'reason': 'family event',
      });
    });

    test('a form without dates shows its errors and sends nothing', () async {
      final stub = hrStub();
      final form = await openForm(stub);

      await form.submit();

      final state = formState();
      expect(state?.showErrors, isTrue);
      expect(state?.errors, contains(LeaveField.dates));
      expect(stub.last('POST', 'hr/leave'), isNull);
    });

    test('more days than the balance is flagged', () async {
      final form = await openForm(hrStub());

      form.edit(
        (d) => d.copyWith(
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 30),
        ),
      );

      expect(formState()?.errors, contains(LeaveField.balance));
    });

    test('a long sick leave needs a document, uploaded first', () async {
      final stub = hrStub();
      final form = await openForm(stub);
      form.edit(
        (d) => d.copyWith(
          leaveTypeId: sickId,
          start: DateTime(2026, 11, 17),
          end: DateTime(2026, 11, 21),
        ),
      );
      expect(formState()?.errors, {LeaveField.document});

      form.edit((d) => d.copyWith(attachmentPath: () => photoFile()));
      await form.submit();

      expect(stub.last('POST', 'files'), isNotNull);
      expect(
        stub.lastBody('POST', 'hr/leave')['docKey'],
        fixtureMap('hr_uploaded')['key'],
      );
    });

    test('an overlap comes back as a field error', () async {
      final stub = hrStub()
        ..on('POST', 'hr/leave', fixture('hr_leave_overlap'), status: 422);
      final form = await openForm(stub);
      form.edit(
        (d) => d.copyWith(
          start: DateTime(2026, 12, 22),
          end: DateTime(2026, 12, 22),
        ),
      );

      await form.submit();

      final error = formState()?.submission.error;
      expect(
        error,
        isA<ApiFailure>()
            .having((f) => f.isValidation, 'validation', isTrue)
            .having((f) => f.fieldErrors['fromDate'], 'field', isNotNull),
      );
    });

    test('offline shows as a failure', () async {
      final stub = hrStub();
      final form = await openForm(stub);
      form.edit(
        (d) => d.copyWith(
          start: DateTime(2026, 12, 22),
          end: DateTime(2026, 12, 22),
        ),
      );
      stub.offline = true;

      await form.submit();

      expect(
        formState()?.submission.error,
        isA<ApiFailure>().having((f) => f.isOffline, 'offline', isTrue),
      );
    });
  });
}
