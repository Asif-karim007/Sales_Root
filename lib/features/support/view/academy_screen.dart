import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/lesson.dart';
import 'package:salesroot/features/support/providers/academy_providers.dart';
import 'package:salesroot/features/support/view/widget/support_labels.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #114 the sales academy: today's tip, lessons for the user and the career
/// path, or one category's lessons.
class AcademyScreen extends ConsumerWidget {
  const AcademyScreen({super.key});

  bool _onScroll(WidgetRef ref, ScrollNotification notification) {
    final category = ref.read(academyCategoryProvider);
    if (category != null && notification.metrics.extentAfter < 300) {
      ref.read(academyLessonsProvider(category).notifier).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final category = ref.watch(academyCategoryProvider);
    final categories = LessonCategory.values;
    final home = ref.watch(academyHomeProvider);

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.supportAcademyTitle,
        actions: const [SupportLanguagePill()],
      ),
      body: SrAsyncView(
        value: home,
        loading: (_) => const SrSkeletonList(cards: true, count: 4),
        onRetry: () => ref.invalidate(academyHomeProvider),
        data: (_, home) => NotificationListener<ScrollNotification>(
          onNotification: (n) => _onScroll(ref, n),
          child: ListView(
            padding: const EdgeInsets.all(SrMetrics.gutter),
            children: [
              if (home.tip case final tip?) ...[
                _TipCard(lesson: tip),
                const SizedBox(height: 14),
              ],
              SrChipRow(
                padding: EdgeInsets.zero,
                chips: [
                  SrChipItem(l10n.commonAll),
                  for (final c in categories)
                    SrChipItem(l10n.lessonCategory(c)),
                ],
                index: category == null ? 0 : categories.indexOf(category) + 1,
                onChanged: (i) => ref
                    .read(academyCategoryProvider.notifier)
                    .select(i == 0 ? null : categories[i - 1]),
              ),
              const SizedBox(height: 16),
              if (category == null)
                _ForYou(home: home)
              else
                _CategoryLessons(category: category),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final video = lesson.videoSeconds;

    return SrCard(
      tone: SrCardTone.gold,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => context.push(Routes.lessonFor(lesson.id)),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.deep,
              borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
            ),
            child: Icon(Icons.play_arrow_rounded, size: 32, color: c.onDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.supportAcademyTip, style: AppText.label(c.ink2)),
                Text(
                  lesson.title.of(fmt.isBangla),
                  style: AppText.rowTitle(c.ink),
                ),
                Text(
                  video == null
                      ? l10n.supportAcademyMinutes(fmt.number(lesson.minutes))
                      : l10n.supportAcademyTipMeta(lessonDuration(fmt, video)),
                  style: AppText.meta(c.ink2, size: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// m:ss in the app's digits.
String lessonDuration(AppFormat fmt, int seconds) =>
    fmt.digits('${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}');

class _ForYou extends StatelessWidget {
  const _ForYou({required this.home});

  final AcademyHome home;

  void _why(BuildContext context) {
    final l10n = context.l10n;
    showSrSheet<void>(
      context: context,
      builder: (_) => SrSheet(
        title: l10n.supportAcademyWhyTitle,
        child: Text(
          l10n.supportAcademyWhyBody,
          style: AppText.lead(SrColors.of(context).ink2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final career = home.career;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrSectionHeader(
          title: l10n.supportAcademyForYou,
          actionLabel: l10n.supportAcademyWhy,
          onAction: () => _why(context),
        ),
        const SizedBox(height: 8),
        if (home.forYou.isEmpty)
          SrEmptyState(
            icon: Icons.school_outlined,
            title: l10n.supportAcademyNothingNew,
          )
        else
          SrRowGroup(
            rows: [for (final lesson in home.forYou) LessonRow(lesson: lesson)],
          ),
        const SizedBox(height: 20),
        SrRowGroup(
          title: l10n.supportAcademyCareer,
          rows: [
            SrListRow(
              title: career.title.of(fmt.isBangla),
              subtitle: l10n.supportAcademyCareerProgress(
                fmt.number(career.total),
                fmt.number(career.done),
              ),
              leading: const SrAvatar(
                icon: Icons.trending_up_rounded,
                tone: SrAvatarTone.accent,
              ),
              chevron: true,
              onTap: () => context.push(Routes.career),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryLessons extends ConsumerWidget {
  const _CategoryLessons({required this.category});

  final LessonCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = academyLessonsProvider(category);
    final lessons = ref.watch(provider);

    return SrAsyncView(
      value: lessons,
      loading: (_) => const SrSkeletonList(count: 5, shrinkWrap: true),
      onRetry: () => ref.invalidate(provider),
      isEmpty: (page) => page.isEmpty,
      empty: (_) => SrEmptyState(
        icon: Icons.school_outlined,
        title: l10n.supportAcademyNoLessons,
      ),
      data: (_, page) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrRowGroup(
            rows: [for (final lesson in page.items) LessonRow(lesson: lesson)],
          ),
          if (page.isLoadingMore) ...[
            const SizedBox(height: 12),
            const SrSkeletonRow(),
          ],
          if (page.loadMoreError case final error?) ...[
            const SizedBox(height: 12),
            SrErrorState(
              error: error,
              compact: true,
              onRetry: () => ref.read(provider.notifier).loadMore(),
            ),
          ],
        ],
      ),
    );
  }
}

/// A lesson in a list: title, length and why it is suggested, and a tag for
/// new, in progress or done.
class LessonRow extends StatelessWidget {
  const LessonRow({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final reason = switch (lesson.reason) {
      LessonReason.lostLeads => l10n.supportAcademyReasonLost(
        fmt.number(lesson.reasonCount),
      ),
      LessonReason.quotationsSent => l10n.supportAcademyReasonQuotes,
      LessonReason.continueLesson => l10n.supportAcademyReasonContinue,
      null => null,
    };
    final tag = lesson.isDone
        ? SrTag(l10n.supportAcademyDone, tone: SrTone.neutral)
        : lesson.isStarted
        ? SrTag(fmt.percent(lesson.progress), tone: SrTone.warn)
        : lesson.isNew
        ? SrTag(l10n.supportAcademyNew, tone: SrTone.ok)
        : null;

    return SrListRow(
      title: lesson.title.of(fmt.isBangla),
      subtitle: [
        l10n.supportAcademyMinutes(fmt.number(lesson.minutes)),
        ?reason,
      ].join(' · '),
      leading: SrAvatar(
        icon: lesson.isDone
            ? Icons.check_rounded
            : Icons.play_circle_outline_rounded,
        tone: lesson.isDone ? SrAvatarTone.accent : SrAvatarTone.neutral,
      ),
      trailing: tag,
      chevron: true,
      onTap: () => context.push(Routes.lessonFor(lesson.id)),
    );
  }
}
