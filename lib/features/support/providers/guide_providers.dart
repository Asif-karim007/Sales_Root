import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/support/data/fake_guide_repository.dart';
import 'package:salesroot/features/support/data/gemini_guide_repository.dart';
import 'package:salesroot/features/support/data/guide_gemini_api.dart';
import 'package:salesroot/features/support/data/guide_repository.dart';
import 'package:salesroot/features/support/models/guide.dart';
import 'package:salesroot/features/support/providers/help_providers.dart';

part 'guide_providers.g.dart';

/// Gemini when the build has `GEMINI_API_KEY`, the keyword matcher otherwise.
@Riverpod(keepAlive: true)
GuideRepository guideRepository(Ref ref) => GeminiGuideRepository.isAvailable
    ? GeminiGuideRepository(GuideGeminiApi(), ref.watch(helpRepositoryProvider))
    : FakeGuideRepository(ref.watch(fakeBackendProvider));

class GuideChat {
  const GuideChat({
    required this.messages,
    this.thinking = false,
    this.failure,
    this.unanswered,
  });

  final List<GuideMessage> messages;
  final bool thinking;
  final ApiFailure? failure;

  /// The question whose answer failed, for retry.
  final String? unanswered;

  bool get isFresh =>
      messages.every((m) => m.kind == GuideMessageKind.greeting);
}

@riverpod
class GuideChatNotifier extends _$GuideChatNotifier {
  static const _historyTurns = 6;

  @override
  GuideChat build() => const GuideChat(
    messages: [GuideMessage(id: 0, kind: GuideMessageKind.greeting)],
  );

  Future<void> ask(String text, {required bool appInBangla}) async {
    final question = text.trim();
    if (question.isEmpty || state.thinking) return;
    state = GuideChat(
      messages: [
        ...state.messages,
        GuideMessage(id: _nextId, kind: GuideMessageKind.mine, text: question),
      ],
    );
    await _answer(question, appInBangla);
  }

  Future<void> retry({required bool appInBangla}) async {
    final question = state.unanswered;
    if (question == null || state.thinking) return;
    await _answer(question, appInBangla);
  }

  /// Marks a confirm answer as handled; a decline gets a short reply.
  void settle(int messageId, {required bool accepted}) {
    state = GuideChat(
      messages: [
        for (final m in state.messages) m.id == messageId ? m.settle() : m,
        if (!accepted)
          GuideMessage(id: _nextId, kind: GuideMessageKind.declined),
      ],
    );
  }

  int get _nextId =>
      state.messages.fold<int>(0, (max, m) => m.id > max ? m.id : max) + 1;

  Future<void> _answer(String question, bool appInBangla) async {
    final history = [
      for (final m in state.messages)
        if (m.kind == GuideMessageKind.mine)
          GuideTurn(text: m.text, mine: true)
        else if (m.answer case final answer?)
          GuideTurn(text: answer.text, mine: false),
    ];
    final previous = history.isEmpty
        ? history
        : history.sublist(0, history.length - 1);
    state = GuideChat(messages: state.messages, thinking: true);
    try {
      final answer = await ref
          .read(guideRepositoryProvider)
          .ask(
            GuideQuestion(
              text: question,
              appInBangla: appInBangla,
              history: previous.length > _historyTurns
                  ? previous.sublist(previous.length - _historyTurns)
                  : previous,
            ),
          );
      if (!ref.mounted) return;
      state = GuideChat(
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
      state = GuideChat(
        messages: state.messages,
        failure: failure,
        unanswered: question,
      );
    }
  }
}
