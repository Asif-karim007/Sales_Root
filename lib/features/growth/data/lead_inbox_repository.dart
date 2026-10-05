import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/models/conversation.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';

/// Customer conversations and the enquiries waiting in them.
abstract interface class LeadInboxRepository {
  /// One page of [box]; [openOnly] leaves out closed conversations.
  Future<PageResult<Conversation>> list(
    ConversationBox box, {
    bool openOnly = false,
    int page = 1,
  });

  /// The conversation with its messages.
  Future<Conversation> get(String id);

  /// Assigns it to the signed-in member.
  Future<Conversation> take(String id);

  Future<Conversation> assign(String id, String membershipId);

  Future<Conversation> close(String id);

  /// Sends a message to the customer on the conversation's channel.
  Future<Conversation> reply(String id, ReplyInput input);

  /// Active members a conversation can be assigned to.
  Future<List<GrowthMember>> members();
}
