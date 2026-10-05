import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/data/hr_repositories.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/providers/hr_paging.dart';

part 'leave_providers.g.dart';

@riverpod
Future<List<LeaveBalance>> leaveBalances(Ref ref) =>
    ref.watch(leaveRepositoryProvider).balances();

/// The status chip on the leave list; null shows every request.
@riverpod
class LeaveStatusFilterNotifier extends _$LeaveStatusFilterNotifier {
  @override
  LeaveStatus? build() => null;

  void set(LeaveStatus? status) => state = status;
}

@riverpod
class LeaveListNotifier extends _$LeaveListNotifier {
  LeaveQuery get _query =>
      LeaveQuery(status: ref.read(leaveStatusFilterProvider));

  @override
  Future<Paged<LeaveRequest>> build() async {
    final query = LeaveQuery(status: ref.watch(leaveStatusFilterProvider));
    return Paged.first(await ref.watch(leaveRepositoryProvider).list(query));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    final next = await loadPageAfter(
      current,
      (page) => ref.read(leaveRepositoryProvider).list(_query.next(page)),
    );
    if (!ref.mounted) return;
    state = AsyncData(next);
  }
}

/// Withdrawing a pending request from its detail sheet.
@riverpod
class LeaveWithdrawNotifier extends _$LeaveWithdrawNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  Future<void> withdraw(String id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(leaveRepositoryProvider).withdraw(id);
      return id;
    });
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) {
      ref
        ..invalidate(leaveListProvider)
        ..invalidate(leaveBalancesProvider);
    }
  }
}

/// Everything the request form shows before the user types.
class LeaveFormData {
  const LeaveFormData({
    required this.lookups,
    required this.balances,
    required this.recent,
  });

  final LeaveLookups lookups;
  final List<LeaveBalance> balances;
  final List<LeaveRequest> recent;
}

class LeaveFormState {
  const LeaveFormState({
    required this.data,
    this.draft = const LeaveDraft(),
    this.showErrors = false,
    this.submission = const AsyncData(null),
  });

  final LeaveFormData data;
  final LeaveDraft draft;

  /// Set after a submit attempt, so errors show only once they matter.
  final bool showErrors;

  /// The id of the request once it is sent.
  final AsyncValue<String?> submission;

  Set<LeaveField> get errors => draft.errors(data.lookups, data.balances);

  double get noOfDays => draft.days(data.lookups.holidays);

  LeaveFormState copyWith({
    LeaveDraft? draft,
    bool? showErrors,
    AsyncValue<String?>? submission,
  }) => LeaveFormState(
    data: data,
    draft: draft ?? this.draft,
    showErrors: showErrors ?? this.showErrors,
    submission: submission ?? this.submission,
  );
}

@riverpod
class LeaveFormNotifier extends _$LeaveFormNotifier {
  @override
  Future<LeaveFormState> build() async {
    final repository = ref.watch(leaveRepositoryProvider);
    final [lookups, balances, recent] = await Future.wait<Object>([
      repository.lookups(),
      repository.balances(),
      repository.list(const LeaveQuery()),
    ]);
    final types = (lookups as LeaveLookups).leaveTypes;
    return LeaveFormState(
      data: LeaveFormData(
        lookups: lookups,
        balances: balances as List<LeaveBalance>,
        recent: (recent as PageResult<LeaveRequest>).items.take(3).toList(),
      ),
      draft: LeaveDraft(leaveTypeId: types.isEmpty ? null : types.first.id),
    );
  }

  void edit(LeaveDraft Function(LeaveDraft draft) change) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(draft: change(current.draft)));
  }

  Future<void> submit() async {
    final current = state.value;
    if (current == null || current.submission.isLoading) return;
    if (current.errors.isNotEmpty) {
      state = AsyncData(current.copyWith(showErrors: true));
      return;
    }
    state = AsyncData(
      current.copyWith(showErrors: true, submission: const AsyncLoading()),
    );
    final result = await AsyncValue.guard(
      () => ref.read(leaveRepositoryProvider).create(current.draft.toInput()),
    );
    if (!ref.mounted) return;
    state = AsyncData(current.copyWith(showErrors: true, submission: result));
    if (result.hasValue) {
      ref
        ..invalidate(leaveListProvider)
        ..invalidate(leaveBalancesProvider);
    }
  }
}
