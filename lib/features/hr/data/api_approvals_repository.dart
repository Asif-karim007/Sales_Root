import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/approvals_repository.dart';
import 'package:salesroot/features/hr/data/hr_api.dart';
import 'package:salesroot/features/hr/models/approval.dart';

class ApiApprovalsRepository implements ApprovalsRepository {
  ApiApprovalsRepository(this._api);

  final HrApi _api;

  static const _inbox = 'inbox';

  @override
  Future<PageResult<ApprovalItem>> list(ApprovalFilter filter) async {
    final pending = await _inboxWith(ApprovalState.pending);
    final counts = {
      ApprovalFilter.pending.wire: pending.length,
      for (final f in ApprovalFilter.values)
        if (f.kind case final kind?)
          f.wire: pending.where((i) => i.kind == kind).length,
    };
    final List<ApprovalItem> items;
    if (filter == ApprovalFilter.done) {
      final [approved, rejected] = await Future.wait([
        _inboxWith(ApprovalState.approved),
        _inboxWith(ApprovalState.rejected),
      ]);
      items = [...approved, ...rejected]
        ..sort((a, b) => _newest(a.submittedAt, b.submittedAt));
    } else {
      final kind = filter.kind;
      items = [
        for (final item in pending)
          if (kind == null || item.kind == kind) item,
      ];
    }
    return PageResult(
      items: items,
      page: 1,
      totalCount: items.length,
      totalPages: 1,
      raw: {'counts': counts},
    );
  }

  @override
  Future<ApprovalItem?> decide(ApprovalDecision decision) async {
    final json = await apiRequest(
      'Approval ${decision.action}',
      () => _api.decide(decision.id, decision.action, decision.toJson()),
    );
    final row = jsonMap(json);
    return row['status'] is String ? ApprovalItem.fromJson(row) : null;
  }

  @override
  Future<int> approveAll(List<ApprovalItem> items) async {
    var approved = 0;
    for (final item in items) {
      if (!item.isPending) continue;
      await decide(ApprovalDecision(id: item.id, approve: true));
      approved++;
    }
    return approved;
  }

  Future<List<ApprovalItem>> _inboxWith(ApprovalState state) async => jsonList(
    await apiRequest(
      'Approvals ${state.wire}',
      () => _api.approvals({'box': _inbox, 'status': state.wire}),
    ),
    ApprovalItem.fromJson,
  );

  static int _newest(DateTime? a, DateTime? b) {
    if (a == null || b == null) return 0;
    return b.compareTo(a);
  }
}
