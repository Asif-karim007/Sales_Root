import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/growth_api.dart';
import 'package:salesroot/features/growth/data/lead_inbox_repository.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';

class ApiLeadInboxRepository implements LeadInboxRepository {
  ApiLeadInboxRepository(this._api);

  final GrowthApi _api;

  @override
  Future<PageResult<Conversation>> list(
    ConversationBox box, {
    bool openOnly = false,
    int page = 1,
  }) async {
    final json = await apiRequest(
      'Inbox',
      () => _api.inbox({
        ...pageQuery(page),
        'box': box.wire,
        if (openOnly) 'status': 'open',
      }),
    );
    return PageResult.fromJson(jsonMap(json), Conversation.fromJson);
  }

  @override
  Future<Conversation> get(String id) async => Conversation.fromJson(
    jsonMap(await apiRequest('Conversation', () => _api.conversation(id))),
  );

  @override
  Future<Conversation> take(String id) async {
    await apiRequest('Conversation take', () => _api.take(id));
    return get(id);
  }

  @override
  Future<Conversation> assign(String id, String membershipId) async {
    await apiRequest(
      'Conversation assign',
      () => _api.assign(id, membershipId),
    );
    return get(id);
  }

  @override
  Future<Conversation> close(String id) async {
    await apiRequest('Conversation close', () => _api.close(id));
    return get(id);
  }

  @override
  Future<Conversation> reply(String id, ReplyInput input) async {
    await apiRequest(
      'Conversation reply',
      () => _api.reply(id, input.toJson()),
    );
    return get(id);
  }

  @override
  Future<List<GrowthMember>> members() async {
    final rows = await apiRequest('Inbox members', _api.members);
    return [
      for (final row in jsonList(rows, (row) => row))
        if (row['status'] == 'active') GrowthMember.fromJson(row),
    ];
  }
}
