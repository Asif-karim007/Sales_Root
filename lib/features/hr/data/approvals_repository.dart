import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/models/approval.dart';

abstract interface class ApprovalsRepository {
  /// Team members' requests, with a `Counts` facet keyed by
  /// [ApprovalFilter.wire].
  Future<PageResult<ApprovalItem>> list(ApprovalQuery query);

  /// Approves or rejects one request and returns it as it now stands.
  Future<ApprovalItem> decide(ApprovalDecision decision);

  /// Approves every request in [items] that is still pending and returns
  /// how many were approved.
  Future<int> approveAll(List<ApprovalItem> items);
}
