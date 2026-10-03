import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/hr/data/expense_fixtures.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/providers/expense_providers.dart';

import 'hr_test_utils.dart';

void main() {
  final types = [for (final row in expenseTypeRows) ExpenseType.fromJson(row)];

  group('expense draft', () {
    final today = DateTime(2026, 10, 4, 0, 13);

    test('category, amount and date are required', () {
      expect(const ExpenseDraft().errors(types, today), {
        ExpenseField.type,
        ExpenseField.amount,
        ExpenseField.date,
      });
    });

    test('tomorrow is a future date; any time today is not', () {
      const draft = ExpenseDraft(typeId: mobileTypeId, amount: 300);

      expect(draft.copyWith(date: DateTime(2026, 10, 5)).errors(types, today), {
        ExpenseField.futureDate,
      });
      expect(
        draft
            .copyWith(date: DateTime(2026, 10, 4, 23, 59))
            .errors(types, today),
        isEmpty,
      );
    });

    test('a receipt is needed above the category limit', () {
      final draft = ExpenseDraft(
        typeId: travelTypeId,
        amount: 1500,
        date: DateTime(2026, 10, 4),
      );

      expect(draft.errors(types, today), {ExpenseField.receipt});
      expect(
        draft.copyWith(receipts: ['/tmp/bill.jpg']).errors(types, today),
        isEmpty,
      );
    });

    test('the title is the category name and blanks are left out', () {
      final body = ExpenseDraft(
        typeId: travelTypeId,
        amount: 850,
        date: DateTime(2026, 10, 4),
        from: 'Uttara',
      ).toInput(types).toJson();

      expect(body['Title'], 'Travel');
      expect(body['IncurredOn'], '2026-10-04');
      expect(body.containsKey('EndLocation'), isFalse);
      expect(body.containsKey('Description'), isFalse);
    });
  });

  group('expense repository', () {
    test('the list pages 20 at a time', () async {
      final container = await hrContainer();
      keep(container, expenseListProvider);

      final first = await container.read(expenseListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.hasMore, isTrue);

      await container.read(expenseListProvider.notifier).loadMore();
      final second = container.read(expenseListProvider).value;
      expect(second?.items.length, first.totalCount);
      expect(second?.hasMore, isFalse);
    });

    test('a future date is refused by the server', () async {
      final container = await hrContainer();
      final tomorrow = AppDateUtils.dateOnly(
        DateTime.now(),
      ).add(const Duration(days: 1));

      await expectLater(
        container
            .read(expenseRepositoryProvider)
            .create(
              ExpenseInput(
                title: 'Mobile',
                expenseTypeId: mobileTypeId,
                incurredOn: tomorrow,
                claimedAmount: 300,
              ),
            ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.fieldError('IncurredOn'),
            'IncurredOn',
            'Expense date cannot be a future date.',
          ),
        ),
      );
    });

    test('missing fields are a 400 naming them', () async {
      final container = await hrContainer();

      await expectLater(
        container
            .read(expenseRepositoryProvider)
            .create(
              const ExpenseInput(
                title: null,
                expenseTypeId: null,
                incurredOn: null,
                claimedAmount: null,
              ),
            ),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.statusCode, 'status', 400)
              .having(
                (f) => f.fieldErrors.keys,
                'fields',
                containsAll(['Title', 'ExpenseTypeId', 'IncurredOn']),
              ),
        ),
      );
    });

    test('a visit link prefills the route and travel', () async {
      final container = await hrContainer();
      final form = expenseFormProvider(3);
      keep(container, form);

      final state = await container.read(form.future);

      expect(state.draft.visit?.id, 3);
      expect(state.draft.typeId, travelTypeId);
      expect(state.draft.from, isNotEmpty);
      expect(state.draft.to, state.draft.visit?.endLocation);
    });

    test('submitting files a pending claim in the list', () async {
      final container = await hrContainer();
      keep(container, expenseListProvider);
      final form = expenseFormProvider(null);
      keep(container, form);
      await container.read(form.future);

      container
          .read(form.notifier)
          .edit(
            (d) => d.copyWith(
              typeId: mobileTypeId,
              amount: () => 350,
              note: 'Recharge',
            ),
          );
      await container.read(form.notifier).submit();

      final claim = container.read(form).value?.submission.value;
      expect(claim?.stage, ExpenseStage.pending);
      final list = await container.read(expenseListProvider.future);
      expect(list.items.first.id, claim?.id);
      expect(list.facets['StatusCounts']?['pending'], 4);
    });

    test('a receipt needs storage, so a full plan is a 402', () async {
      final container = await hrContainer();
      container
          .read(devSettingsProvider.notifier)
          .update((s) => s.copyWith(quotaReached: true));

      await expectLater(
        container
            .read(expenseRepositoryProvider)
            .create(
              ExpenseInput(
                title: 'Travel',
                expenseTypeId: travelTypeId,
                incurredOn: DateTime.now(),
                claimedAmount: 1500,
                attachments: const [ExpenseAttachment(name: 'bill.jpg')],
              ),
            ),
        throwsA(isA<ApiFailure>().having((f) => f.isQuota, 'quota', true)),
      );
    });

    test('a member can withdraw a pending claim', () async {
      final container = await hrContainer(role: WorkspaceRole.member);
      final repository = container.read(expenseRepositoryProvider);
      final pending = await repository.list(
        const ExpenseQuery(stage: ExpenseStage.pending),
      );
      final claim = pending.items.first;
      expect(claim.canWithdraw, isTrue);

      final withdrawn = await repository.withdraw(claim.id);

      expect(withdrawn.stage, ExpenseStage.withdrawn);
      expect(withdrawn.canWithdraw, isFalse);
    });
  });
}
