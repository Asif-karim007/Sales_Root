import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';

abstract interface class SupportRepository {
  /// The user's own requests to the SalesRoot team.
  Future<PageResult<SupportTicket>> tickets();

  Future<SupportTicket> ticket(String id);

  Future<SupportTicket> createTicket(TicketInput input);

  Future<SupportTicket> reply(
    String ticketId,
    String text, {
    List<SupportAttachment> attachments = const [],
  });

  Future<void> sendFeedback(FeedbackInput input);

  Future<void> sendSurvey(String moment, SurveyScore score);

  Future<void> sendEnquiry(EnquiryInput input);
}
