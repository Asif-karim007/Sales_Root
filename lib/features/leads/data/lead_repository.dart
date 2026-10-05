import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/models/lead_transcript.dart';

abstract interface class LeadRepository {
  Future<PageResult<Lead>> list(LeadQuery query);

  /// The lead with its timeline, open tasks and quotations.
  Future<Lead> get(String id);

  /// The stages of the workspace's default pipeline.
  Future<List<LeadStage>> stages();

  Future<LeadLookups> lookups();

  Future<List<LeadLookupCompany>> companies(String search, int page);

  Future<LeadLookupCompany> company(String id);

  /// Contacts matching [search], only [companyId]'s when it is set.
  Future<List<LeadLookupContact>> contacts(
    String search,
    int page, {
    String? companyId,
  });

  Future<LeadLookupContact> contact(String id);

  /// Throws [LeadDuplicateFailure] when the phone is already on a lead,
  /// unless the input allows duplicates.
  Future<Lead> create(LeadInput input);

  /// Saves [input] over [lead], moving its stage or owner when they changed.
  Future<Lead> edit(Lead lead, LeadInput input);

  Future<void> delete(String id);

  Future<Lead> restore(String id);

  Future<Lead> moveStage(Lead lead, LeadStageInput input);

  Future<Lead> completeTask(String leadId, String taskId);

  /// Logs the activity and answers the lead as it is afterwards.
  Future<Lead> logActivity(String leadId, LeadActivityInput input);

  /// [heard] refined by the server's parser when the workspace has it on;
  /// otherwise [heard] as it is.
  Future<LeadTranscript> refine(LeadTranscript heard);
}
