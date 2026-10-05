import 'package:salesroot/features/growth/models/conversation.dart';

/// Saved replies and AI drafts for the inbox; the conversations themselves
/// come from the inbox.
abstract interface class MessagesRepository {
  /// Templates for [channel] (`whatsapp`, `sms`), or for every channel.
  Future<List<MessageTemplate>> templates({String? channel});

  /// A message the AI writes for [ask].
  Future<String> draft(DraftAsk ask);
}
