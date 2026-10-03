import 'package:salesroot/features/team/models/chat.dart';

/// What an open thread shows: messages newest first (unsent ones on top),
/// who is typing and the last send that failed.
class ChatRoom {
  const ChatRoom({
    this.messages = const [],
    this.hasOlder = false,
    this.loadingOlder = false,
    this.typing = const [],
    this.failure,
  });

  final List<ChatMessage> messages;
  final bool hasOlder;
  final bool loadingOlder;
  final List<ChatPerson> typing;
  final Object? failure;

  ChatRoom copyWith({
    List<ChatMessage>? messages,
    bool? hasOlder,
    bool? loadingOlder,
    List<ChatPerson>? typing,
    Object? Function()? failure,
  }) => ChatRoom(
    messages: messages ?? this.messages,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    typing: typing ?? this.typing,
    failure: failure != null ? failure() : this.failure,
  );

  /// Adds [message], or replaces the one with its id.
  ChatRoom upsert(ChatMessage message) => copyWith(
    messages: _ordered([
      for (final m in messages)
        if (m.id != message.id) m,
      message,
    ]),
  );

  ChatRoom remove(int messageId) => copyWith(
    messages: [
      for (final m in messages)
        if (m.id != messageId) m,
    ],
  );

  ChatRoom withOlder(List<ChatMessage> older, {required bool hasOlder}) {
    final known = {for (final m in messages) m.id};
    return copyWith(
      messages: _ordered([
        ...messages,
        for (final m in older)
          if (!known.contains(m.id)) m,
      ]),
      hasOlder: hasOlder,
      loadingOlder: false,
    );
  }

  ChatRoom apply(ChatEvent event) => switch (event) {
    MessageAdded(:final message) => upsert(message).copyWith(
      typing: [
        for (final p in typing)
          if (p.id != message.senderId) p,
      ],
    ),
    MessagesStatusChanged(:final upToId, :final status) => copyWith(
      messages: [
        for (final m in messages)
          m.isMine &&
                  m.id > 0 &&
                  m.id <= upToId &&
                  m.status.index < status.index
              ? m.withStatus(status)
              : m,
      ],
    ),
    TypingChanged(:final person, typing: true) => copyWith(
      typing: [
        for (final p in typing)
          if (p.id != person.id) p,
        person,
      ],
    ),
    TypingChanged(:final person) => copyWith(
      typing: [
        for (final p in typing)
          if (p.id != person.id) p,
      ],
    ),
  };

  static List<ChatMessage> _ordered(List<ChatMessage> messages) => [
    ...messages.where((m) => m.id < 0).toList()
      ..sort((a, b) => a.id.compareTo(b.id)),
    ...messages.where((m) => m.id >= 0).toList()
      ..sort((a, b) => b.id.compareTo(a.id)),
  ];
}
