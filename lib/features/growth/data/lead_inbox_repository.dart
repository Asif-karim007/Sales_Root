import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';

/// New leads from every channel, waiting to be accepted, assigned or
/// rejected. Pages carry the `Counts` facet keyed by [InboxFilter.wire] and
/// the `Stats` facet with `AvgFirstResponseMinutes` and `SlaMinutes`.
abstract interface class LeadInboxRepository {
  /// Open leads, most urgent first: unanswered ones by how long they have
  /// waited, then assigned ones.
  Future<PageResult<InboxLead>> list(InboxFilter filter, {int page = 1});

  Future<InboxLead> get(int id);

  /// Who the distribution rules would give this lead to right now.
  Future<AssigneeSuggestion> suggestAssignee(int id);

  Future<InboxLead> accept(int id, AcceptInput input);

  Future<InboxLead> assign(int id, int memberId);

  Future<InboxLead> reject(int id, RejectReason reason);

  Future<List<GrowthMember>> members();

  /// The open pipeline stages an accepted lead can start in.
  Future<List<LeadStage>> stages();
}
