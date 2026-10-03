import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/support/models/help_article.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';
import 'package:salesroot/features/support/providers/help_providers.dart';
import 'package:salesroot/features/support/providers/ticket_providers.dart';
import 'package:salesroot/features/support/support_links.dart';
import 'package:salesroot/features/support/view/widget/support_labels.dart';
import 'package:salesroot/features/support/view/widget/support_language_pill.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #108 help and support: the AI guide, search, categories, contact and the
/// user's own requests.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  late final _search = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery;
    if (initial != null && initial.isNotEmpty) {
      Future.microtask(() {
        if (mounted) ref.read(helpQueryProvider.notifier).setTerm(initial);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String term) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => ref.read(helpQueryProvider.notifier).setTerm(term),
    );
  }

  void _clear() {
    _debounce?.cancel();
    _search.clear();
    setState(() {});
    ref.read(helpQueryProvider.notifier).setTerm('');
  }

  bool _onScroll(ScrollNotification notification) {
    if (ref.read(helpQueryProvider).isBrowsing) return false;
    if (notification.metrics.extentAfter < 300) {
      ref.read(helpSearchProvider.notifier).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = ref.watch(helpQueryProvider);
    final categories = HelpCategory.values;
    final category = query.category;

    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.supportHelpTitle,
          actions: const [SupportLanguagePill()],
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: ListView(
            padding: const EdgeInsets.all(SrMetrics.gutter),
            children: [
              const _GuideHint(),
              const SizedBox(height: 12),
              SrTextField(
                controller: _search,
                hint: l10n.supportHelpSearch,
                prefixIcon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                onChanged: _onSearch,
                suffix: _search.text.isEmpty
                    ? null
                    : SrIconButton(
                        icon: Icons.close_rounded,
                        compact: true,
                        tooltip: l10n.commonClear,
                        onTap: _clear,
                      ),
              ),
              const SizedBox(height: 10),
              SrChipRow(
                padding: EdgeInsets.zero,
                chips: [
                  SrChipItem(l10n.commonAll),
                  for (final c in categories) SrChipItem(l10n.helpCategory(c)),
                ],
                index: category == null ? 0 : categories.indexOf(category) + 1,
                onChanged: (i) => ref
                    .read(helpQueryProvider.notifier)
                    .setCategory(i == 0 ? null : categories[i - 1]),
              ),
              const SizedBox(height: 16),
              if (query.isBrowsing) ...[
                const _PopularSection(),
                const _ContactSection(),
                const _MyRequestsSection(),
              ] else
                const _SearchResults(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideHint extends StatelessWidget {
  const _GuideHint();

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;

    return SrCard(
      tone: SrCardTone.tint,
      onTap: () => context.push(Routes.aiGuide),
      child: Row(
        children: [
          const SrAvatar(
            icon: Icons.auto_awesome_rounded,
            tone: SrAvatarTone.dark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.supportHelpAskGuide, style: AppText.rowTitle(c.ink)),
                Text(l10n.supportHelpAskGuideHint, style: AppText.meta(c.ink2)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.ink3),
        ],
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article, this.withSummary = false});

  final HelpArticle article;
  final bool withSummary;

  @override
  Widget build(BuildContext context) {
    final bangla = context.fmt.isBangla;
    return SrListRow(
      title: article.title.of(bangla),
      subtitle: withSummary ? article.summary.of(bangla) : null,
      leading: const SrAvatar(icon: Icons.help_outline_rounded),
      chevron: true,
      onTap: () => context.push(Routes.helpArticleFor(article.id)),
    );
  }
}

class _PopularSection extends ConsumerWidget {
  const _PopularSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final popular = ref.watch(popularArticlesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrSectionHeader(title: l10n.supportHelpPopular),
        const SizedBox(height: 8),
        SrAsyncView(
          value: popular,
          loading: (_) => const SrSkeletonList(count: 4, shrinkWrap: true),
          onRetry: () => ref.invalidate(popularArticlesProvider),
          isEmpty: (articles) => articles.isEmpty,
          empty: (_) => SrEmptyState(
            icon: Icons.menu_book_outlined,
            title: l10n.supportHelpNoArticles,
          ),
          data: (_, articles) => SrRowGroup(
            rows: [for (final a in articles) _ArticleRow(article: a)],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ContactSection extends ConsumerWidget {
  const _ContactSection();

  Future<void> _open(BuildContext context, Uri uri) async {
    final failed = context.l10n.supportCantOpen;
    if (await openExternal(uri) || !context.mounted) return;
    showSrError(context, failed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(moduleAccessProvider(AppModule.support));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrRowGroup(
          title: l10n.supportHelpContact,
          rows: [
            if (access.canAdd)
              SrListRow(
                title: l10n.supportHelpSendRequest,
                subtitle: l10n.supportHelpSendRequestSub,
                leading: const SrAvatar(
                  icon: Icons.support_agent_rounded,
                  tone: SrAvatarTone.accent,
                ),
                chevron: true,
                onTap: () => context.push(Routes.supportNew),
              ),
            SrListRow(
              title: l10n.supportHelpWhatsApp,
              subtitle: l10n.supportHelpHours,
              leading: const SrAvatar(icon: Icons.chat_outlined),
              chevron: true,
              onTap: () => _open(context, SupportLinks.chat),
            ),
            SrListRow(
              title: l10n.supportHelpCall,
              subtitle: context.fmt.phone(l10n.supportHelpPhone),
              leading: const SrAvatar(icon: Icons.call_outlined),
              chevron: true,
              onTap: () => _open(context, SupportLinks.call),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _MyRequestsSection extends ConsumerWidget {
  const _MyRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(moduleAccessProvider(AppModule.support));
    if (!access.canView) return const SizedBox.shrink();
    final tickets = ref.watch(myTicketsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrSectionHeader(title: l10n.supportHelpMyRequests),
        const SizedBox(height: 8),
        SrAsyncView(
          value: tickets,
          loading: (_) => const SrSkeletonList(count: 2, shrinkWrap: true),
          onRetry: () => ref.invalidate(myTicketsProvider),
          isEmpty: (page) => page.isEmpty,
          empty: (_) => SrCard(
            child: Text(
              l10n.supportHelpNoRequests,
              style: AppText.meta(SrColors.of(context).ink2),
            ),
          ),
          data: (_, page) => SrRowGroup(
            rows: [
              for (final ticket in page.items) _TicketRow(ticket: ticket),
              if (page.hasMore)
                SrListRow(
                  title: l10n.supportHelpMoreRequests,
                  leading: const SrAvatar(icon: Icons.expand_more_rounded),
                  onTap: page.isLoadingMore
                      ? null
                      : () => ref.read(myTicketsProvider.notifier).loadMore(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final updated = ticket.updatedAt;
    final (tag, tone) = switch (ticket.status) {
      TicketStatus.replied => (l10n.supportTicketTagReply, SrTone.ok),
      TicketStatus.open => (l10n.supportTicketStatusOpen, SrTone.warn),
      TicketStatus.resolved => (
        l10n.supportTicketStatusResolved,
        SrTone.neutral,
      ),
    };

    return SrListRow(
      title: l10n.supportTicketHeading(ticket.number, ticket.subject),
      subtitle: [
        l10n.ticketStatus(ticket.status),
        if (updated != null) fmt.dayTime(updated),
      ].join(' · '),
      leading: const SrAvatar(icon: Icons.forum_outlined),
      trailing: SrTag(tag, tone: tone),
      chevron: true,
      onTap: () => context.push(Routes.supportTicketFor(ticket.id)),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final results = ref.watch(helpSearchProvider);

    return SrAsyncView(
      value: results,
      loading: (_) => const SrSkeletonList(count: 5, shrinkWrap: true),
      onRetry: () => ref.invalidate(helpSearchProvider),
      isEmpty: (page) => page.isEmpty,
      empty: (_) => SrEmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.supportHelpNoResults,
        message: l10n.supportHelpNoResultsBody,
        actionLabel: l10n.supportHelpAskGuide,
        onAction: () => context.push(
          Uri(
            path: Routes.aiGuide,
            queryParameters: {'q': ref.read(helpQueryProvider).term},
          ).toString(),
        ),
      ),
      data: (_, page) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(
            title: l10n.supportHelpResults(context.fmt.number(page.totalCount)),
          ),
          const SizedBox(height: 8),
          SrRowGroup(
            rows: [
              for (final article in page.items)
                _ArticleRow(article: article, withSummary: true),
            ],
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
              onRetry: () => ref.read(helpSearchProvider.notifier).loadMore(),
            ),
          ],
        ],
      ),
    );
  }
}
