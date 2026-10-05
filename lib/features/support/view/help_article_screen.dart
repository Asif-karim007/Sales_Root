import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/help_article.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';
import 'package:salesroot/features/support/providers/help_providers.dart';
import 'package:salesroot/features/support/support_links.dart';
import 'package:salesroot/features/support/view/moment_survey.dart';
import 'package:salesroot/features/support/view/widget/support_failure.dart';
import 'package:salesroot/features/support/view/widget/support_labels.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/features/support/view/widget/support_rows.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #109 a help article: steps, a tip, a "try it" link and "did this help?".
class HelpArticleScreen extends ConsumerWidget {
  const HelpArticleScreen({super.key, required this.id});

  final String id;

  void _share(BuildContext context, HelpArticle article) {
    final bangla = context.fmt.isBangla;
    final steps = [
      for (final (i, step) in article.steps.indexed)
        '${context.fmt.digits('${i + 1}')}. ${step.of(bangla)}',
    ];
    SharePlus.instance.share(
      ShareParams(
        subject: article.title.of(bangla),
        text: [article.title.of(bangla), '', ...steps].join('\n'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final article = ref.watch(helpArticleProvider(id));
    final loaded = article.value;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.supportArticleTitle,
        actions: [
          const SupportLanguagePill(),
          if (loaded != null)
            SrIconButton(
              icon: Icons.share_outlined,
              tooltip: l10n.commonShare,
              onTap: () => _share(context, loaded),
            ),
        ],
      ),
      body: SrAsyncView(
        value: article,
        loading: (_) => const SrSkeletonList(cards: true, count: 3),
        onRetry: () => ref.invalidate(helpArticleProvider(id)),
        data: (_, article) => _ArticleBody(article: article),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.article});

  final HelpArticle article;

  Future<void> _openVideo(BuildContext context, String url) async {
    final failed = context.l10n.supportCantOpen;
    if (await openExternal(Uri.parse(url)) || !context.mounted) return;
    showSrError(context, failed);
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final bangla = fmt.isBangla;
    final video = article.videoSeconds;
    final videoUrl = article.videoUrl;
    final tip = article.tip;
    final action = article.action;
    final meta = [
      l10n.supportArticleRead(fmt.number(article.readMinutes)),
      if (video != null) l10n.supportArticleVideo(_duration(fmt, video)),
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.all(SrMetrics.gutter),
      children: [
        Text(article.title.of(bangla), style: AppText.hero(c.ink, size: 22)),
        const SizedBox(height: 6),
        Text(meta, style: AppText.meta(c.ink2)),
        const SizedBox(height: 10),
        Text(article.summary.of(bangla), style: AppText.lead(c.ink2)),
        if (videoUrl != null) ...[
          const SizedBox(height: 14),
          SrCard(
            padding: const EdgeInsets.all(8),
            child: SupportMediaCover(
              icon: Icons.play_circle_fill_rounded,
              semanticLabel: l10n.supportArticlePlay,
              onTap: () => _openVideo(context, videoUrl),
            ),
          ),
        ],
        const SizedBox(height: 14),
        _Steps(steps: [for (final step in article.steps) step.of(bangla)]),
        if (tip != null) ...[
          const SizedBox(height: 14),
          SrNote(message: tip.of(bangla), icon: Icons.info_outline_rounded),
        ],
        if (action != null) ...[
          const SizedBox(height: 14),
          SrButton(
            label: l10n.destination(action),
            variant: SrButtonVariant.secondary,
            icon: Icons.arrow_forward_rounded,
            expand: true,
            onPressed: () => context.push(action.location()),
          ),
        ],
        const SizedBox(height: 20),
        _Helpful(article: article),
      ],
    );
  }

  static String _duration(AppFormat fmt, int seconds) => fmt.digits(
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
  );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, step) in steps.indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${fmt.digits('${i + 1}')}.',
                      style: AppText.rowTitle(c.accent, size: 14),
                    ),
                  ),
                  Expanded(
                    child: Text(step, style: AppText.body(c.ink, size: 14)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Helpful extends ConsumerWidget {
  const _Helpful({required this.article});

  final HelpArticle article;

  void _no(BuildContext context, WidgetRef ref) {
    ref.read(articleVoteProvider(article.id).notifier).vote(helpful: false);
    context.push(
      Uri(
        path: Routes.supportNew,
        queryParameters: {
          'category': TicketCategory.question.wire,
          'from': article.title.of(context.fmt.isBangla),
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final provider = articleVoteProvider(article.id);
    final vote = ref.watch(provider);
    ref.listen(provider, (_, next) {
      if (next.value == true) {
        showMomentSurvey(context, moment: SurveyMoments.helpArticle);
      } else if (next.hasError) {
        showSrError(context, supportFailureText(context, next.error));
      }
    });

    if (vote.value != null) {
      return Row(
        children: [
          Icon(Icons.favorite_rounded, size: 18, color: c.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.supportArticleThanks, style: AppText.meta(c.ink2)),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(l10n.supportArticleHelpful, style: AppText.meta(c.ink)),
        ),
        SrButton(
          label: l10n.supportArticleYes,
          variant: SrButtonVariant.secondary,
          size: SrButtonSize.sm,
          loading: vote.isLoading,
          onPressed: () => ref.read(provider.notifier).vote(helpful: true),
        ),
        const SizedBox(width: 8),
        SrButton(
          label: l10n.supportArticleNo,
          variant: SrButtonVariant.secondary,
          size: SrButtonSize.sm,
          onPressed: vote.isLoading ? null : () => _no(context, ref),
        ),
      ],
    );
  }
}
