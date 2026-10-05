import 'package:dio/dio.dart';

import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/support/data/support_api.dart';
import 'package:salesroot/features/support/data/support_repository.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';

class ApiSupportRepository implements SupportRepository {
  ApiSupportRepository(this._api);

  final SupportApi _api;

  @override
  Future<PageResult<SupportTicket>> tickets() async => PageResult.all(
    jsonList(
      await apiRequest('Help tickets', _api.tickets),
      SupportTicket.fromJson,
    ),
  );

  @override
  Future<SupportTicket> ticket(String id) async => SupportTicket.fromJson(
    jsonMap(await apiRequest('Help ticket $id', () => _api.ticket(id))),
  );

  @override
  Future<SupportTicket> createTicket(TicketInput input) async {
    final json = await apiRequest(
      'Help ticket create',
      () => _api.createTicket(input.toJson()),
    );
    final id = jsonId(jsonMap(json)['id']) ?? '';
    if (input.attachments.isEmpty) return ticket(id);
    return reply(id, '', attachments: input.attachments);
  }

  @override
  Future<SupportTicket> reply(
    String ticketId,
    String text, {
    List<SupportAttachment> attachments = const [],
  }) async {
    final keys = [for (final file in attachments) await _upload(file)];
    final body = text.trim();
    await apiRequest(
      'Help ticket reply',
      () => _api.reply(ticketId, {
        'body': body.isEmpty
            ? attachments.map((file) => file.name).join(', ')
            : body,
        if (keys.isNotEmpty) 'attachments': keys,
      }),
    );
    return ticket(ticketId);
  }

  @override
  Future<void> sendFeedback(FeedbackInput input) async {
    final screenshot = input.screenshot;
    final key = screenshot == null ? null : await _upload(screenshot);
    await apiRequest(
      'Feedback',
      () => _api.feedback(input.toJson(screenshotKey: key)),
    );
  }

  @override
  Future<void> sendSurvey(String moment, SurveyScore score) => apiRequest(
    'Survey',
    () => _api.feedback(
      feedbackBody(FeedbackKind.survey, rating: score.score, screen: moment),
    ),
  );

  @override
  Future<void> sendEnquiry(EnquiryInput input) =>
      apiRequest('Enquiry', () => _api.feedback(input.toJson()));

  /// Uploads [file] and returns its storage key.
  Future<String> _upload(SupportAttachment file) async {
    final json = await apiRequest(
      'Attachment upload',
      () async => _api.upload(
        FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: file.name),
        }),
      ),
    );
    return jsonMap(json)['key'] as String? ?? '';
  }
}
