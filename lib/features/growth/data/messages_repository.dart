import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/models/message_thread.dart';

/// WhatsApp, Messenger and SMS conversations in one inbox. Pages carry the
/// `Counts` facet keyed by [ThreadFilter.wire].
abstract interface class MessagesRepository {
  Future<PageResult<MessageThread>> threads(
    ThreadFilter filter, {
    int page = 1,
  });

  /// The Page and WhatsApp number the inbox is connected to.
  Future<MessagingAccount> account();

  Future<MessageThread> thread(int id);

  /// The conversation, re-emitted whenever a message is sent or arrives.
  Stream<List<ThreadMessage>> watch(int threadId);

  Future<ThreadMessage> send(int threadId, SendMessageInput input);

  Future<MessageThread> markRead(int threadId);

  Future<MessageThread> assign(int threadId, int memberId);

  Future<List<MessageTemplate>> templates();

  /// The thread with this number, created when there is none yet.
  Future<int> openThread({
    required String phone,
    required String name,
    ThreadChannel channel = ThreadChannel.whatsapp,
  });
}
