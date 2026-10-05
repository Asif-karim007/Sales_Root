import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/models/approval.dart';

abstract interface class ApprovalsRepository {
  /// The requests waiting on the signed-in approver, or those already
  /// decided, with a `counts` facet of pending requests keyed by
  /// [ApprovalFilter.wire].
  Future<PageResult<ApprovalItem>> list(ApprovalFilter filter);

  /// Approves or rejects one request; returns it as it now stands when the
  /// server sends it back.
  Future<ApprovalItem?> decide(ApprovalDecision decision);

  /// Approves every request in [items] that is still pending and returns
  /// how many were approved.
  Future<int> approveAll(List<ApprovalItem> items);
}
