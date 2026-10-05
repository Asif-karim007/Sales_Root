import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/hr/data/hr_repositories.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/providers/expense_providers.dart';

import '../../helpers/api_stub.dart';
import 'hr_test_setup.dart';

void main() {
  final categories = [
    for (final row in fixture('hr_expense_categories') as List)
      ExpenseType.fromJson(row as Map<String, dynamic>),
  ];

  group('draft', () {
    final today = DateTime(2026, 10, 5, 0, 5);

    test('category, amount and date are required', () {
      expect(const ExpenseDraft().errors(categories, today), {
        ExpenseField.type,
        ExpenseField.amount,
        ExpenseField.date,
      });
    });

    test('tomorrow is a future date; any time today is not', () {
      final draft = ExpenseDraft(typeId: travelId, amount: 100, date: today);
      expect(draft.errors(categories, today), isEmpty);
      final tomorrow = draft.copyWith(date: DateTime(2026, 10, 6));
      expect(tomorrow.errors(categories, today), {ExpenseField.futureDate});
    });

    test('a receipt is needed above the category limit', () {
      final travel = ExpenseDraft(typeId: travelId, amount: 600, date: today);
      expect(travel.errors(categories, today), {ExpenseField.receipt});
      expect(
        travel.copyWith(amount: () => 500).errors(categories, today),
        isEmpty,
      );
      final mobile = ExpenseDraft(typeId: mobileId, amount: 50, date: today);
      expect(mobile.errors(categories, today), {ExpenseField.receipt});
    });
  });

  group('parsing', () {
    test('claims and totals read the real JSON', () async {
      final container = await hrContainer(hrStub());
      listenTo(container, expenseListProvider);

      final paged = await container.read(expenseListProvider.future);
      final claim = paged.items.first;
      expect(claim.cost, 120);
      expect(claim.stage, ExpenseStage.pending);
      expect(claim.typeCode, 'travel');
      expect(claim.typeName.bn, 'যাতায়াত');
      expect(claim.expenseDate, DateTime(2026, 10, 5));
      expect(claim.visitId, visitId);
      expect(claim.canWithdraw, isTrue);
      expect(paged.facets[expenseTotalsFacet]?['pending'], 220);
    });

    test('an approved claim with a payout reads as paid', () {
      final row = (fixtureMap('hr_expenses')['items'] as List).first as Map;
      final paid = ExpenseClaim.fromJson({
        ...row.cast<String, dynamic>(),
        'status': 'approved',
        'paidAt': '2026-10-06T10:00:00Z',
      });
      expect(paid.stage, ExpenseStage.paid);
      expect(paid.canWithdraw, isFalse);
    });

    test('the status chip filters the list', () async {
      final stub = hrStub();
      final container = await hrContainer(stub);
      listenTo(container, expenseListProvider);
      container
          .read(expenseStageFilterProvider.notifier)
          .set(ExpenseStage.approved);

      await container.read(expenseListProvider.future);

      expect(
        stub.last('GET', 'hr/expenses')?.queryParameters['status'],
        'approved',
      );
    });
  });

  group('form', () {
    late ProviderContainer container;

    Future<ExpenseFormNotifier> openForm(ApiStub stub, {String? visit}) async {
      container = await hrContainer(stub);
      listenTo(container, expenseFormProvider(visit));
      await container.read(expenseFormProvider(visit).future);
      return container.read(expenseFormProvider(visit).notifier);
    }

    ExpenseFormState? formState([String? visit]) =>
        container.read(expenseFormProvider(visit)).value;

    test('the lookups list categories, my visits and the approver', () async {
      final stub = hrStub();
      await openForm(stub);

      final lookups = formState()?.lookups;
      expect(lookups?.types, hasLength(7));
      expect(lookups?.visits.single.id, visitId);
      expect(lookups?.approverName, 'Rumpa Sarker');
      expect(
        stub.last('GET', 'visits')?.queryParameters['membershipId'],
        rafiId,
      );
    });

    test('a visit link starts on travel and is sent with the claim', () async {
      final stub = hrStub();
      final form = await openForm(stub, visit: visitId);
      expect(formState(visitId)?.draft.typeId, travelId);

      form.edit(
        (d) => d.copyWith(
          amount: () => 120,
          date: DateTime(2026, 10, 5),
          note: ' CNG to the shop ',
        ),
      );
      await form.submit();

      expect(formState(visitId)?.submission.value, isNotEmpty);
      expect(stub.lastBody('POST', 'hr/expenses'), {
        'categoryId': travelId,
        'amount': 120.0,
        'spentOn': '2026-10-05',
        'note': 'CNG to the shop',
        'visitId': visitId,
      });
    });

    test('a receipt is uploaded and its key sent', () async {
      final stub = hrStub();
      final form = await openForm(stub);
      form.edit(
        (d) => d.copyWith(
          typeId: travelId,
          amount: () => 900,
          date: DateTime(2026, 10, 5),
          receipt: () => photoFile(),
        ),
      );

      await form.submit();

      expect(
        stub.lastBody('POST', 'hr/expenses')['receiptKey'],
        fixtureMap('hr_uploaded')['key'],
      );
    });

    test('the server asking for a receipt is a field error', () async {
      final stub = hrStub()
        ..on(
          'POST',
          'hr/expenses',
          fixture('hr_expense_receipt_required'),
          status: 422,
        );
      final form = await openForm(stub);
      form.edit(
        (d) => d.copyWith(
          typeId: travelId,
          amount: () => 100,
          date: DateTime(2026, 10, 5),
        ),
      );

      await form.submit();

      expect(
        formState()?.submission.error,
        isA<ApiFailure>().having(
          (f) => f.fieldErrors['receiptKey'],
          'receipt',
          isNotNull,
        ),
      );
    });
  });

  test('withdrawing deletes the claim', () async {
    final stub = hrStub();
    final container = await hrContainer(stub);
    listenTo(container, expenseWithdrawProvider);

    await container.read(expenseWithdrawProvider.notifier).withdraw('x1');

    expect(stub.last('DELETE', 'hr/expenses/{id}')?.path, 'hr/expenses/x1');
    expect(container.read(expenseWithdrawProvider).value, 'x1');
  });

  test('the second page asks from offset 20', () async {
    final stub = hrStub();
    final container = await hrContainer(stub);

    await container
        .read(expenseRepositoryProvider)
        .list(const ExpenseQuery(page: 2));

    expect(stub.last('GET', 'hr/expenses')?.queryParameters, {
      'offset': 20,
      'limit': 20,
    });
  });
}
