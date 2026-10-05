import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/data/guide_repository.dart';
import 'package:salesroot/features/support/data/support_api.dart';
import 'package:salesroot/features/support/models/guide.dart';

class ApiGuideRepository implements GuideRepository {
  ApiGuideRepository(this._api);

  final SupportApi _api;

  static const _screen = 'ai_guide';

  @override
  Future<GuideStatus> status() async => GuideStatus.fromJson(
    jsonMap(await apiRequest('AI status', _api.aiStatus)),
  );

  @override
  Future<GuideAnswer> ask(String question, {String? conversationId}) async {
    final json = await apiRequest(
      'Guide ask',
      () => _api.guide({
        'question': question.trim(),
        'conversationId': ?conversationId,
        'screen': _screen,
      }),
    );
    return GuideAnswer.fromJson(jsonMap(json));
  }

  @override
  Future<void> rate(String conversationId, int rating) => apiRequest(
    'Guide rate',
    () => _api.rateGuide({'conversationId': conversationId, 'rating': rating}),
  );
}
