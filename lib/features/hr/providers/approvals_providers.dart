import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/data/hr_repositories.dart';
import 'package:salesroot/features/hr/models/approval.dart';
import 'package:salesroot/features/hr/providers/expense_providers.dart';
import 'package:salesroot/features/hr/providers/leave_providers.dart';

part 'approvals_providers.g.dart';

const String approvalCountsFacet = 'counts';

@riverpod
class ApprovalFilterNotifier extends _$ApprovalFilterNotifier {
  @override
  ApprovalFilter build() => ApprovalFilter.pending;

  void set(ApprovalFilter filter) => state = filter;
}

@riverpod
Future<Paged<ApprovalItem>> approvalList(Ref ref) async {
  final filter = ref.watch(approvalFilterProvider);
  final page = await ref.watch(approvalsRepositoryProvider).list(filter);
  return Paged.first(page, facetKeys: const [approvalCountsFacet]);
}

/// The result of a decision, for the snackbar.
class ApprovalOutcome {
  const ApprovalOutcome({required this.approved, this.count = 1, this.item});

  final bool approved;
  final int count;

  /// The request as it now stands, when the server sent it back.
  final ApprovalItem? item;
}

@riverpod
class ApprovalActionsNotifier extends _$ApprovalActionsNotifier {
  @override
  AsyncValue<ApprovalOutcome?> build() => const AsyncData(null);

  Future<void> decide(ApprovalDecision decision) => _run(() async {
    final item = await ref.read(approvalsRepositoryProvider).decide(decision);
    return ApprovalOutcome(approved: decision.approve, item: item);
  });

  Future<void> approveAll(List<ApprovalItem> items) => _run(() async {
    final count = await ref.read(approvalsRepositoryProvider).approveAll(items);
    return ApprovalOutcome(approved: true, count: count);
  });

  Future<void> _run(Future<ApprovalOutcome> Function() work) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(work);
    if (!ref.mounted) return;
    state = result;
    if (!result.hasValue) return;
    ref
      ..invalidate(approvalListProvider)
      ..invalidate(leaveListProvider)
      ..invalidate(leaveBalancesProvider)
      ..invalidate(expenseListProvider);
  }
}
