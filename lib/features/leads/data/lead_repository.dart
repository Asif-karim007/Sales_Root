import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';

abstract interface class LeadRepository {
  /// One page, with the `ChipCounts`, `StageCounts` and `Summary` facets.
  Future<PageResult<Lead>> list(LeadQuery query);

  /// The lead with its timeline.
  Future<Lead> get(int id);

  Future<List<LeadStage>> stages();

  Future<LeadLookups> lookups();

  /// Throws [LeadDuplicateFailure] when the phone or company is already on a
  /// lead, unless the input allows duplicates.
  Future<Lead> create(LeadInput input);

  Future<Lead> edit(int id, LeadInput input);

  Future<void> delete(int id);

  Future<LeadStageMove> moveStage(int id, LeadStageInput input);

  Future<Lead> undoStageMove(int id, int moveId);

  /// Marks the lead's next task done.
  Future<Lead> completeNextTask(int id);

  Future<Lead> logActivity(int id, LeadActivityInput input);
}
