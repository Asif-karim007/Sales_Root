import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';

abstract interface class SupportRepository {
  /// The user's own requests, newest activity first.
  Future<PageResult<SupportTicket>> tickets({int page = 1});

  Future<SupportTicket> ticket(int id);

  Future<SupportTicket> createTicket(TicketInput input);

  Future<SupportTicket> reply(
    int ticketId,
    String text, {
    List<SupportAttachment> attachments = const [],
  });

  Future<SupportTicket> resolve(int ticketId);

  /// Ids of tickets that changed on the server, such as a new agent reply.
  Stream<int> get ticketChanges;

  Future<FeedbackReceipt> sendFeedback(FeedbackInput input);

  Future<void> sendSurvey(String moment, SurveyScore score);

  Future<EnquiryReceipt> sendEnquiry(EnquiryInput input);

  /// Starts preparing the user's data export; it arrives by notification.
  Future<void> requestDataExport();
}
