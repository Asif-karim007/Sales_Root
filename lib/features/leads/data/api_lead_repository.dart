import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/debug_log.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/leads/data/lead_api.dart';
import 'package:salesroot/features/leads/data/lead_repository.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/models/lead_transcript.dart';

class ApiLeadRepository implements LeadRepository {
  ApiLeadRepository(this._api, {required this.memberId});

  final LeadApi _api;

  /// The user's membership in the current workspace.
  final String? Function() memberId;

  @override
  Future<PageResult<Lead>> list(LeadQuery query) async {
    final json = await apiRequest(
      'Lead list',
      () => _api.list(query.toQuery()),
    );
    return PageResult.fromJson(jsonMap(json), Lead.fromJson);
  }

  @override
  Future<Lead> get(String id) async {
    final json = await apiRequest('Lead get', () => _api.get(id));
    return Lead.fromJson(jsonMap(json));
  }

  @override
  Future<List<LeadStage>> stages() async {
    final json = jsonMap(
      await apiRequest('Lead stages', () => _api.pipelines()),
    );
    final pipelines = jsonList(json['pipelines'], (p) => p);
    final pipeline =
        pipelines.where((p) => jsonBool(p['isDefault'])).firstOrNull ??
        pipelines.firstOrNull;
    final pipelineId = jsonId(pipeline?['id']);
    return [
      for (final stage in jsonList(json['stages'], LeadStage.fromJson))
        if (pipelineId == null || stage.pipelineId == pipelineId) stage,
    ];
  }

  @override
  Future<LeadLookups> lookups() async {
    final [members, workspace] = await Future.wait([
      apiRequest('Lead owners', () => _api.members()),
      apiRequest('Lead pack', () => _api.workspace()),
    ]);
    return LeadLookups.fromJson(
      members: members is List ? members : const [],
      workspace: jsonMap(workspace),
      currentMemberId: memberId(),
    );
  }

  @override
  Future<List<LeadLookupCompany>> companies(String search, int page) async {
    final json = await apiRequest(
      'Lead companies',
      () => _api.companies(_search(search, page)),
    );
    return PageResult.fromJson(jsonMap(json), LeadLookupCompany.fromJson).items;
  }

  @override
  Future<LeadLookupCompany> company(String id) async {
    final json = await apiRequest('Lead company', () => _api.company(id));
    return LeadLookupCompany.fromJson(jsonMap(jsonMap(json)['company']));
  }

  @override
  Future<List<LeadLookupContact>> contacts(
    String search,
    int page, {
    String? companyId,
  }) async {
    final json = await apiRequest(
      'Lead contacts',
      () => _api.contacts({..._search(search, page), 'companyId': ?companyId}),
    );
    return PageResult.fromJson(jsonMap(json), LeadLookupContact.fromJson).items;
  }

  @override
  Future<LeadLookupContact> contact(String id) async {
    final json = await apiRequest('Lead contact', () => _api.contact(id));
    return LeadLookupContact.fromJson(jsonMap(jsonMap(json)['contact']));
  }

  @override
  Future<Lead> create(LeadInput input) async {
    final dynamic json;
    try {
      json = await apiRequest(
        'Lead create',
        () => _api.create(input.toCreateJson()),
      );
    } on ApiFailure catch (failure) {
      if (failure.code != LeadDuplicateFailure.duplicateCode) rethrow;
      throw await _duplicate(input.phone, failure);
    }
    final lead = Lead.fromJson(jsonMap(json));
    final owner = input.ownerId;
    final note = input.note?.trim() ?? '';
    final extras = <Future<void> Function()>[
      if (owner != null && owner != lead.assignedTo?.id)
        () => _assign(lead.id, owner),
      if (_newCompany(input) != null) () => _linkNewCompany(lead.id, input),
      if (note.isNotEmpty)
        () => _api.logActivity({
          'type': LeadActivityKind.note.wire,
          'leadId': lead.id,
          'body': note,
        }),
    ];
    if (extras.isEmpty) return lead;
    for (final extra in extras) {
      try {
        await apiRequest('Lead create extras', extra);
      } on ApiFailure catch (failure) {
        logDebug('Lead ${lead.id} saved without an extra: $failure');
      }
    }
    return get(lead.id);
  }

  @override
  Future<Lead> edit(Lead lead, LeadInput input) async {
    await apiRequest(
      'Lead edit',
      () => _api.edit(lead.id, input.toUpdateJson()),
    );
    final stageId = input.stageId;
    if (stageId != null && stageId != lead.stage?.id) {
      await apiRequest(
        'Lead edit stage',
        () => _api.moveStage(lead.id, {'stageId': stageId}),
      );
    }
    final owner = input.ownerId;
    if (owner != null && owner != lead.assignedTo?.id) {
      await apiRequest('Lead edit owner', () => _assign(lead.id, owner));
    }
    if (_newCompany(input) != null) {
      await apiRequest(
        'Lead edit company',
        () => _linkNewCompany(lead.id, input),
      );
    }
    return get(lead.id);
  }

  @override
  Future<void> delete(String id) =>
      apiRequest('Lead delete', () => _api.delete(id));

  @override
  Future<Lead> restore(String id) async {
    final json = await apiRequest('Lead restore', () => _api.restore(id));
    return Lead.fromJson(jsonMap(json));
  }

  @override
  Future<Lead> moveStage(Lead lead, LeadStageInput input) async {
    final stage = input.stage;
    if (stage.isLost) {
      await apiRequest(
        'Lead lost',
        () => _api.lost(lead.id, {
          'reason': input.lostReason ?? 'other',
          'note': ?_text(input.note),
        }),
      );
      return get(lead.id);
    }
    var stageId = lead.stage?.id;
    if (lead.status != LeadStatus.open) {
      final json = await apiRequest('Lead reopen', () => _api.reopen(lead.id));
      stageId = jsonId(jsonMap(json)['stageId']);
    }
    if (stage.isWon) {
      await apiRequest(
        'Lead won',
        () => _api.won(lead.id, {
          'amount': input.amount ?? lead.estimatedAmount ?? 0,
          'createInvoice': false,
        }),
      );
    } else if (stage.id != stageId) {
      await apiRequest(
        'Lead move stage',
        () => _api.moveStage(lead.id, {
          'stageId': stage.id,
          'amount': ?input.amount,
          if (input.custom.isNotEmpty)
            'custom': {...lead.custom, ...input.custom},
        }),
      );
    }
    return get(lead.id);
  }

  @override
  Future<Lead> completeTask(String leadId, String taskId) async {
    await apiRequest(
      'Lead task done',
      () => _api.completeTask(taskId, const {}),
    );
    return get(leadId);
  }

  @override
  Future<Lead> logActivity(String leadId, LeadActivityInput input) async {
    await apiRequest(
      'Lead log activity',
      () => _api.logActivity(input.toJson(leadId)),
    );
    return get(leadId);
  }

  @override
  Future<LeadTranscript> refine(LeadTranscript heard) async {
    try {
      final status = jsonMap(
        await apiRequest('AI status', () => _api.aiStatus()),
      );
      if (status['enabled'] != true) return heard;
      final json = await apiRequest(
        'AI parse',
        () => _api.parse({'text': heard.text, 'kind': 'lead'}),
      );
      return heard.refinedBy(jsonMap(json));
    } on ApiFailure catch (failure) {
      logDebug('Voice lead read on the phone only: $failure');
      return heard;
    }
  }

  Future<dynamic> _assign(String id, String memberId) =>
      _api.assign(id, {'membershipId': memberId});

  static String? _newCompany(LeadInput input) =>
      input.companyId == null ? _text(input.companyName) : null;

  Future<void> _linkNewCompany(String id, LeadInput input) async {
    final name = _newCompany(input);
    if (name == null) return;
    final company = jsonMap(
      await _api.createCompany({'name': name, 'tags': const <String>[]}),
    );
    final companyId = jsonId(company['id']);
    if (companyId == null) return;
    await _api.edit(id, {'companyId': companyId});
  }

  /// The 422 for a phone already on a lead, with that lead to offer.
  Future<ApiFailure> _duplicate(String? phone, ApiFailure failure) async {
    if (phone == null) return failure;
    try {
      final json = jsonMap(
        await apiRequest('Lead check phone', () => _api.checkPhone(phone)),
      );
      final match = jsonMap(json['lead']);
      final id = jsonId(match['id']);
      if (id == null) return failure;
      final existing = await get(id).onError<ApiFailure>(
        (_, _) => Lead(id: id, leadName: match['name'] as String? ?? ''),
      );
      return LeadDuplicateFailure(existing: existing, message: failure.message);
    } on ApiFailure {
      return failure;
    }
  }

  static Map<String, dynamic> _search(String search, int page) => {
    ...pageQuery(page),
    if (search.trim().isNotEmpty) 'q': search.trim(),
  };

  static String? _text(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
