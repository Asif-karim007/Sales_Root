import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/data/expense_repository.dart';
import 'package:salesroot/features/hr/data/fake_expense_repository.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/providers/hr_paging.dart';

part 'expense_providers.g.dart';

@Riverpod(keepAlive: true)
ExpenseRepository expenseRepository(Ref ref) =>
    FakeExpenseRepository(ref.watch(fakeBackendProvider));

const List<String> expenseFacets = ['StatusCounts', 'StatusTotals'];

/// The status chip on the claim list; null shows every claim.
@riverpod
class ExpenseStageFilterNotifier extends _$ExpenseStageFilterNotifier {
  @override
  ExpenseStage? build() => null;

  void set(ExpenseStage? stage) => state = stage;
}

@riverpod
class ExpenseListNotifier extends _$ExpenseListNotifier {
  ExpenseQuery get _query =>
      ExpenseQuery(stage: ref.read(expenseStageFilterProvider));

  @override
  Future<Paged<ExpenseClaim>> build() async {
    final query = ExpenseQuery(stage: ref.watch(expenseStageFilterProvider));
    final page = await ref.watch(expenseRepositoryProvider).list(query);
    return Paged.first(page, facetKeys: expenseFacets);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    final next = await loadPageAfter(
      current,
      (page) => ref.read(expenseRepositoryProvider).list(_query.next(page)),
    );
    if (!ref.mounted) return;
    state = AsyncData(next);
  }
}

/// Withdrawing a pending claim from its detail sheet.
@riverpod
class ExpenseWithdrawNotifier extends _$ExpenseWithdrawNotifier {
  @override
  AsyncValue<ExpenseClaim?> build() => const AsyncData(null);

  Future<void> withdraw(int id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(expenseRepositoryProvider).withdraw(id),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) ref.invalidate(expenseListProvider);
  }
}

class ExpenseFormState {
  const ExpenseFormState({
    required this.lookups,
    required this.draft,
    this.showErrors = false,
    this.submission = const AsyncData(null),
  });

  final ExpenseLookups lookups;
  final ExpenseDraft draft;

  /// Set after a submit attempt, so errors show only once they matter.
  final bool showErrors;
  final AsyncValue<ExpenseClaim?> submission;

  Set<ExpenseField> errors(DateTime today) =>
      draft.errors(lookups.types, today);

  ExpenseFormState copyWith({
    ExpenseDraft? draft,
    bool? showErrors,
    AsyncValue<ExpenseClaim?>? submission,
  }) => ExpenseFormState(
    lookups: lookups,
    draft: draft ?? this.draft,
    showErrors: showErrors ?? this.showErrors,
    submission: submission ?? this.submission,
  );
}

/// The claim form. With [visitId] the visit is linked and its locations
/// prefill the route.
@riverpod
class ExpenseFormNotifier extends _$ExpenseFormNotifier {
  @override
  Future<ExpenseFormState> build(int? visitId) async {
    final repository = ref.watch(expenseRepositoryProvider);
    final id = visitId;
    final (lookups, visit) = await (
      repository.lookups(),
      id == null ? Future<ExpenseVisit?>.value() : repository.visit(id),
    ).wait;
    final travel = lookups.types.where((t) => t.code == 'Travel').firstOrNull;
    return ExpenseFormState(
      lookups: lookups,
      draft: ExpenseDraft(
        date: DateTime.now(),
        typeId: visit == null ? null : travel?.id,
        visit: visit,
        from: visit?.startLocation ?? '',
        to: visit?.endLocation ?? '',
      ),
    );
  }

  void edit(ExpenseDraft Function(ExpenseDraft draft) change) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(draft: change(current.draft)));
  }

  /// Links [visit] and takes its route, keeping what the user typed.
  void linkVisit(ExpenseVisit? visit) => edit(
    (draft) => draft.copyWith(
      visit: () => visit,
      from: draft.from.isEmpty ? visit?.startLocation : null,
      to: draft.to.isEmpty ? visit?.endLocation : null,
    ),
  );

  Future<void> submit() async {
    final current = state.value;
    if (current == null || current.submission.isLoading) return;
    if (current.errors(DateTime.now()).isNotEmpty) {
      state = AsyncData(current.copyWith(showErrors: true));
      return;
    }
    state = AsyncData(
      current.copyWith(showErrors: true, submission: const AsyncLoading()),
    );
    final result = await AsyncValue.guard(
      () => ref
          .read(expenseRepositoryProvider)
          .create(current.draft.toInput(current.lookups.types)),
    );
    if (!ref.mounted) return;
    state = AsyncData(current.copyWith(showErrors: true, submission: result));
    if (result.hasValue) ref.invalidate(expenseListProvider);
  }
}
