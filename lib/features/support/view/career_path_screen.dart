import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/lesson.dart';
import 'package:salesroot/features/support/providers/academy_providers.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #116 the career path from sales executive to team lead, step by step.
class CareerPathScreen extends ConsumerWidget {
  const CareerPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final career = ref.watch(careerPathProvider);

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.supportCareerTitle,
        actions: const [SupportLanguagePill()],
      ),
      body: SrAsyncView(
        value: career,
        loading: (_) => const SrSkeletonList(count: 6),
        onRetry: () => ref.invalidate(careerPathProvider),
        isEmpty: (career) => career.steps.isEmpty,
        empty: (_) => Center(
          child: SrEmptyState(
            icon: Icons.trending_up_rounded,
            title: l10n.supportCareerEmpty,
          ),
        ),
        data: (_, career) => ListView(
          padding: const EdgeInsets.all(SrMetrics.gutter),
          children: [
            _Summary(career: career),
            const SizedBox(height: 12),
            SrNote(
              tone: SrNoteTone.gold,
              icon: Icons.workspace_premium_outlined,
              message: l10n.supportCareerNote,
            ),
            const SizedBox(height: 12),
            SrRowGroup(
              rows: [for (final step in career.steps) _StepRow(step: step)],
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.career});

  final CareerPath career;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SrRing(
            value: career.ratio,
            size: 64,
            child: Text(
              fmt.digits('${career.done}/${career.total}'),
              style: AppText.rowTitle(c.ink, size: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  career.title.of(fmt.isBangla),
                  style: AppText.rowTitle(c.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.supportCareerRecord(
                    fmt.number(career.calls),
                    fmt.number(career.visits),
                    fmt.number(career.wins),
                  ),
                  style: AppText.meta(c.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final CareerStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final locked = step.status == CareerStepStatus.locked;
    final (icon, tag) = switch (step.status) {
      CareerStepStatus.done => (
        Icons.check_rounded,
        SrTag(l10n.supportAcademyDone, tone: SrTone.ok),
      ),
      CareerStepStatus.current => (
        Icons.play_arrow_rounded,
        SrTag(l10n.supportCareerNow),
      ),
      CareerStepStatus.locked => (Icons.lock_outline_rounded, null),
    };

    return SrListRow(
      title: '${fmt.digits('${step.index}')}. ${step.title.of(fmt.isBangla)}',
      subtitle: step.subtitle.of(fmt.isBangla),
      leading: SrAvatar(
        icon: icon,
        tone: locked ? SrAvatarTone.neutral : SrAvatarTone.accent,
      ),
      trailing: tag,
      chevron: !locked,
      onTap: locked
          ? null
          : () => context.push(Routes.lessonFor(step.lessonId)),
    );
  }
}
