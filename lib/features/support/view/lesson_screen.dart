import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/lesson.dart';
import 'package:salesroot/features/support/providers/academy_providers.dart';
import 'package:salesroot/features/support/view/widget/support_failure.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/features/support/view/widget/support_rows.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #115 one lesson: the content, a key-points card, a one-question quiz and
/// "mark complete", which updates the academy and career progress.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  int? _answer;

  void _share(Lesson lesson) {
    final bangla = context.fmt.isBangla;
    SharePlus.instance.share(
      ShareParams(
        subject: lesson.title.of(bangla),
        text: [
          lesson.title.of(bangla),
          lesson.summary.of(bangla),
          '',
          for (final point in lesson.points) '• ${point.of(bangla)}',
        ].join('\n'),
      ),
    );
  }

  String _failureText(Object? error) {
    if (error is! ApiFailure) return supportFailureText(context, error);
    if (error.isConflict) return context.l10n.supportLessonLocked;
    if (error.isValidation) return context.l10n.supportLessonQuizWrong;
    return supportFailureText(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lesson = ref.watch(lessonProvider(widget.id));
    final complete = ref.watch(lessonCompleteProvider(widget.id));
    ref.listen(lessonCompleteProvider(widget.id), (_, next) {
      if (next.value != null) {
        showSrSuccess(context, l10n.supportLessonCompleted);
        if (context.canPop()) context.pop();
      } else if (next.hasError) {
        showSrError(context, _failureText(next.error));
      }
    });
    final loaded = lesson.value;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.supportLessonTitle,
        actions: [
          const SupportLanguagePill(),
          if (loaded != null)
            SrIconButton(
              icon: Icons.share_outlined,
              tooltip: l10n.commonShare,
              onTap: () => _share(loaded),
            ),
        ],
      ),
      footer: loaded == null ? null : _footer(loaded, complete.isLoading),
      body: SrAsyncView(
        value: lesson,
        loading: (_) => const SrSkeletonList(cards: true, count: 3),
        onRetry: () => ref.invalidate(lessonProvider(widget.id)),
        data: (_, lesson) => _LessonBody(
          lesson: lesson,
          answer: _answer,
          onAnswer: lesson.isDone
              ? null
              : (index) => setState(() => _answer = index),
        ),
      ),
    );
  }

  Widget _footer(Lesson lesson, bool saving) {
    final l10n = context.l10n;
    if (lesson.isDone) {
      return SrButton(
        label: l10n.supportLessonBack,
        variant: SrButtonVariant.secondary,
        expand: true,
        onPressed: () => context.pop(),
      );
    }
    final quiz = lesson.quiz;
    final ready = quiz == null || _answer == quiz.correctIndex;
    return SrButton(
      label: l10n.supportLessonComplete,
      expand: true,
      loading: saving,
      onPressed: ready
          ? () => ref
                .read(lessonCompleteProvider(widget.id).notifier)
                .complete(quizAnswer: _answer)
          : null,
    );
  }
}

class _LessonBody extends StatelessWidget {
  const _LessonBody({
    required this.lesson,
    required this.answer,
    required this.onAnswer,
  });

  final Lesson lesson;
  final int? answer;
  final ValueChanged<int>? onAnswer;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final bangla = fmt.isBangla;
    final quiz = lesson.quiz;
    final action = lesson.action;
    final actionLabel = lesson.actionLabel;

    return ListView(
      padding: const EdgeInsets.all(SrMetrics.gutter),
      children: [
        SupportMediaCover(
          icon: Icons.menu_book_rounded,
          height: 160,
          progress: lesson.progress / 100,
        ),
        const SizedBox(height: 14),
        Text(lesson.title.of(bangla), style: AppText.hero(c.ink, size: 22)),
        const SizedBox(height: 4),
        Text(
          l10n.supportAcademyMinutes(fmt.number(lesson.minutes)),
          style: AppText.meta(c.ink2),
        ),
        const SizedBox(height: 10),
        Text(lesson.summary.of(bangla), style: AppText.lead(c.ink2)),
        for (final paragraph in lesson.body) ...[
          const SizedBox(height: 12),
          Text(paragraph.of(bangla), style: AppText.body(c.ink)),
        ],
        if (lesson.points.isNotEmpty) ...[
          const SizedBox(height: 16),
          SrCard(
            tone: SrCardTone.tint,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.supportLessonRemember,
                  style: AppText.rowTitle(c.ink),
                ),
                const SizedBox(height: 6),
                for (final point in lesson.points)
                  SupportCheckLine(text: point.of(bangla)),
              ],
            ),
          ),
        ],
        if (quiz != null) ...[
          const SizedBox(height: 16),
          _Quiz(quiz: quiz, answer: answer, onAnswer: onAnswer),
        ],
        if (action != null) ...[
          const SizedBox(height: 16),
          SrButton(
            label: actionLabel?.of(bangla) ?? l10n.supportLessonTryIt,
            icon: Icons.arrow_forward_rounded,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () => context.push(action.location()),
          ),
        ],
      ],
    );
  }
}

class _Quiz extends StatelessWidget {
  const _Quiz({
    required this.quiz,
    required this.answer,
    required this.onAnswer,
  });

  final LessonQuiz quiz;
  final int? answer;

  /// Null once the lesson is done; the right answer is then shown.
  final ValueChanged<int>? onAnswer;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final chosen = onAnswer == null ? quiz.correctIndex : answer;
    final correct = chosen == quiz.correctIndex;

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.supportLessonQuiz, style: AppText.label(c.ink2)),
          const SizedBox(height: 4),
          Text(quiz.question.of(bangla), style: AppText.rowTitle(c.ink)),
          const SizedBox(height: 8),
          for (final (i, option) in quiz.options.indexed)
            _QuizOption(
              text: option.of(bangla),
              selected: chosen == i,
              correct: i == quiz.correctIndex,
              onTap: onAnswer == null ? null : () => onAnswer?.call(i),
            ),
          if (chosen != null) ...[
            const SizedBox(height: 8),
            SrNote(
              tone: correct ? SrNoteTone.tint : SrNoteTone.err,
              icon: correct
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              title: correct
                  ? l10n.supportLessonRight
                  : l10n.supportLessonNotQuite,
              message: correct
                  ? quiz.explanation.of(bangla)
                  : l10n.supportLessonTryAgain,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.text,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ink = !selected
        ? c.ink3
        : correct
        ? c.accent
        : c.danger;

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: ink,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: AppText.body(c.ink, size: 14))),
            ],
          ),
        ),
      ),
    );
  }
}
