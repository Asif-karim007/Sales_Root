import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/support/data/support_repositories.dart';
import 'package:salesroot/features/support/models/guide.dart';

part 'guide_providers.g.dart';

@riverpod
Future<GuideStatus> guideStatus(Ref ref) =>
    ref.watch(guideRepositoryProvider).status();

class GuideChat {
  const GuideChat({
    required this.messages,
    this.conversationId,
    this.thinking = false,
    this.failure,
    this.unanswered,
    this.rated = false,
  });

  final List<GuideMessage> messages;

  /// The server's thread, set by the first answer.
  final String? conversationId;
  final bool thinking;
  final ApiFailure? failure;

  /// The question whose answer failed, for retry.
  final String? unanswered;

  /// The user already said whether the guide helped.
  final bool rated;

  bool get isFresh =>
      messages.every((m) => m.kind == GuideMessageKind.greeting);

  /// This chat with a new step: [messages] and [thinking] replace the old
  /// ones and any earlier failure is cleared.
  GuideChat next({
    List<GuideMessage>? messages,
    String? conversationId,
    bool thinking = false,
    ApiFailure? failure,
    String? unanswered,
  }) => GuideChat(
    messages: messages ?? this.messages,
    conversationId: conversationId ?? this.conversationId,
    thinking: thinking,
    failure: failure,
    unanswered: unanswered,
    rated: rated,
  );

  GuideChat withRated(bool value) => GuideChat(
    messages: messages,
    conversationId: conversationId,
    thinking: thinking,
    failure: failure,
    unanswered: unanswered,
    rated: value,
  );
}

@riverpod
class GuideChatNotifier extends _$GuideChatNotifier {
  @override
  GuideChat build() => const GuideChat(
    messages: [GuideMessage(id: 0, kind: GuideMessageKind.greeting)],
  );

  Future<void> ask(String text) async {
    final question = text.trim();
    if (question.isEmpty || state.thinking) return;
    state = state.next(
      messages: [
        ...state.messages,
        GuideMessage(id: _nextId, kind: GuideMessageKind.mine, text: question),
      ],
    );
    await _answer(question);
  }

  Future<void> retry() async {
    final question = state.unanswered;
    if (question == null || state.thinking) return;
    await _answer(question);
  }

  /// Marks a confirm answer as handled; a decline gets a short reply.
  void settle(int messageId, {required bool accepted}) {
    state = state.next(
      messages: [
        for (final m in state.messages) m.id == messageId ? m.settle() : m,
        if (!accepted)
          GuideMessage(id: _nextId, kind: GuideMessageKind.declined),
      ],
    );
  }

  /// Tells the server whether the thread helped; asked once per chat. A
  /// failed rating can be given again.
  Future<void> rate({required bool helpful}) async {
    final conversation = state.conversationId;
    if (conversation == null || state.rated) return;
    state = state.withRated(true);
    try {
      await ref
          .read(guideRepositoryProvider)
          .rate(conversation, helpful ? _helpful : _unhelpful);
    } on ApiFailure {
      if (!ref.mounted) return;
      state = state.withRated(false);
    }
  }

  static const _helpful = 5;
  static const _unhelpful = 1;

  int get _nextId =>
      state.messages.fold<int>(0, (max, m) => m.id > max ? m.id : max) + 1;

  Future<void> _answer(String question) async {
    state = state.next(thinking: true);
    try {
      final answer = await ref
          .read(guideRepositoryProvider)
          .ask(question, conversationId: state.conversationId);
      if (!ref.mounted) return;
      state = state.next(
        conversationId: answer.conversationId,
        messages: [
          ...state.messages,
          GuideMessage(
            id: _nextId,
            kind: GuideMessageKind.answer,
            answer: answer,
          ),
        ],
      );
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.next(failure: failure, unanswered: question);
    }
  }
}
