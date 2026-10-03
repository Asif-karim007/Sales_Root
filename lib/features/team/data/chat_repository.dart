import 'dart:typed_data';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/team/models/chat.dart';

abstract interface class ChatRepository {
  /// The user's threads, newest activity first, with `KindCounts` facets.
  Future<PageResult<ChatThread>> threads(ChatQuery query);

  /// Every thread in the workspace, for the owner's oversight view.
  Future<PageResult<ChatThread>> oversight(ChatQuery query);

  Future<ChatThread> thread(int id);

  /// The discussion thread of a lead, created on first use.
  Future<ChatThread> leadThread(int leadId);

  /// The one-to-one thread with a member, created on first use.
  Future<ChatThread> direct(int memberId);

  Future<ChatThread> createGroup(String name, List<int> memberIds);

  Future<ChatThread> updateSettings(
    int threadId, {
    bool? notifications,
    bool? autoDownload,
  });

  Future<ChatThread> addMembers(int threadId, List<int> memberIds);

  Future<void> leave(int threadId);

  /// Messages older than [beforeId] (all when null), newest first.
  Future<PageResult<ChatMessage>> messages(int threadId, {int? beforeId});

  Future<ChatMessage> send(int threadId, MessageInput input);

  Future<void> markRead(int threadId);

  /// The photo or file a message carries.
  Future<Uint8List> attachmentBytes(int messageId);

  /// New messages, typing and receipts in one thread.
  Stream<ChatEvent> events(int threadId);

  /// Fires whenever any thread's list row changes.
  Stream<void> get changes;

  /// Leads, quotations or contacts that can be shared into a chat.
  Future<PageResult<ChatRef>> attachables(
    AttachmentKind kind,
    String term,
    int page,
  );
}
