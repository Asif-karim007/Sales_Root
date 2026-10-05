import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/data/hr_repositories.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/providers/hr_paging.dart';

part 'expense_providers.g.dart';

/// The list facet with the money per stage.
const String expenseTotalsFacet = 'totals';

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
    return Paged.first(page, facetKeys: const [expenseTotalsFacet]);
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
  AsyncValue<String?> build() => const AsyncData(null);

  Future<void> withdraw(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(expenseRepositoryProvider).withdraw(id);
      return id;
    });
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

  /// The id of the claim once it is sent.
  final AsyncValue<String?> submission;

  Set<ExpenseField> errors(DateTime today) =>
      draft.errors(lookups.types, today);

  ExpenseFormState copyWith({
    ExpenseDraft? draft,
    bool? showErrors,
    AsyncValue<String?>? submission,
  }) => ExpenseFormState(
    lookups: lookups,
    draft: draft ?? this.draft,
    showErrors: showErrors ?? this.showErrors,
    submission: submission ?? this.submission,
  );
}

/// The claim form. With [visitId] the visit is linked and the category
/// starts on travel.
@riverpod
class ExpenseFormNotifier extends _$ExpenseFormNotifier {
  static const _travel = 'travel';

  @override
  Future<ExpenseFormState> build(String? visitId) async {
    final lookups = await ref.watch(expenseRepositoryProvider).lookups();
    final id = visitId;
    final visit = id == null
        ? null
        : lookups.visits.where((v) => v.id == id).firstOrNull ??
              ExpenseVisit(id: id);
    final travel = lookups.types.where((t) => t.code == _travel).firstOrNull;
    return ExpenseFormState(
      lookups: lookups,
      draft: ExpenseDraft(
        date: DateTime.now(),
        typeId: visit == null ? null : travel?.id,
        visit: visit,
      ),
    );
  }

  void edit(ExpenseDraft Function(ExpenseDraft draft) change) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(draft: change(current.draft)));
  }

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
      () => ref.read(expenseRepositoryProvider).create(current.draft.toInput()),
    );
    if (!ref.mounted) return;
    state = AsyncData(current.copyWith(showErrors: true, submission: result));
    if (result.hasValue) ref.invalidate(expenseListProvider);
  }
}
