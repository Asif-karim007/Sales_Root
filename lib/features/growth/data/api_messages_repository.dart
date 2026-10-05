import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/growth_api.dart';
import 'package:salesroot/features/growth/data/messages_repository.dart';
import 'package:salesroot/features/growth/models/conversation.dart';

class ApiMessagesRepository implements MessagesRepository {
  ApiMessagesRepository(this._api);

  final GrowthApi _api;

  @override
  Future<List<MessageTemplate>> templates({String? channel}) async => jsonList(
    await apiRequest('Templates', () => _api.templates(channel)),
    MessageTemplate.fromJson,
  );

  @override
  Future<String> draft(DraftAsk ask) async {
    final json = await apiRequest('AI draft', () => _api.draft(ask.toJson()));
    return jsonMap(json)['text'] as String? ?? '';
  }
}
