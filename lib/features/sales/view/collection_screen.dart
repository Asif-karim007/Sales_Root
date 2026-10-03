import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/providers/collection_providers.dart';
import 'package:salesroot/features/sales/view/sales_links.dart';
import 'package:salesroot/features/sales/view/widget/paged_footer.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/features/sales/view/widget/sales_rows.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #60: today's collection by method, what is receivable and due, who to
/// collect from, and what came in.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAdd = ref.watch(moduleAccessProvider(AppModule.collection)).canAdd;
    final summary = ref.watch(collectionSummaryProvider);
    final collections = ref.watch(collectionListProvider);
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.salesCollection,
        actions: [
          SrIconButton(
            icon: Icons.stacked_bar_chart_rounded,
            tooltip: l10n.salesOutstandingTitle,
            onTap: () => context.push(Routes.outstanding),
          ),
        ],
      ),
      body: SrAsyncView<CollectionSummary>(
        value: summary,
        onRetry: () => ref.invalidate(collectionSummaryProvider),
        onUpgrade: upgradeFor(context, summary.error),
        loading: (_) => const SrSkeletonList(count: 3, cards: true),
        data: (context, summary) => RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(dueListProvider)
              ..invalidate(collectionListProvider)
              ..invalidate(collectionSummaryProvider);
            await ref.read(collectionSummaryProvider.future);
          },
          child: LoadMoreListener(
            paged: collections.value,
            onLoadMore: () =>
                ref.read(collectionListProvider.notifier).loadMore(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SrMetrics.gutter,
                14,
                SrMetrics.gutter,
                32,
              ),
              children: [
                _TodayCard(summary: summary),
                const SizedBox(height: 10),
                _Figures(summary: summary),
                const SizedBox(height: 20),
                const _CollectToday(),
                const SizedBox(height: 20),
                const _RecentCollections(),
              ],
            ),
          ),
        ),
      ),
      footer: canAdd
          ? SrButton(
              label: l10n.salesRecordACollection,
              icon: Icons.add_rounded,
              expand: true,
              onPressed: () => context.push(Routes.collectionNew),
            )
          : null,
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.summary});

  final CollectionSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final change = summary.changeOnYesterday;
    return SrCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.salesCollectionToday,
                      style: AppText.label(c.ink2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.money(summary.collectedToday),
                      style: AppText.metric(c.ink, size: 30),
                    ),
                    if (change != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        change >= 0
                            ? l10n.salesAboveYesterday(fmt.percent(change))
                            : l10n.salesBelowYesterday(fmt.percent(-change)),
                        style: AppText.label(
                          change >= 0 ? c.success : c.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SrAvatar(
                icon: Icons.payments_outlined,
                size: 40,
                square: true,
                tone: SrAvatarTone.accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: c.line),
          const SizedBox(height: 12),
          Row(
            children: [
              _MethodFigure(
                label: l10n.salesMethodCash,
                amount: summary.todayCash,
              ),
              _MethodFigure(
                label: l10n.salesMobileMoney,
                amount: summary.todayMobile,
              ),
              _MethodFigure(
                label: l10n.salesMethodBank,
                amount: summary.todayBank,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodFigure extends StatelessWidget {
  const _MethodFigure({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label(c.ink2)),
          const SizedBox(height: 2),
          Text(
            context.fmt.moneyCompact(amount),
            style: AppText.rowTitle(c.ink, size: 14),
          ),
        ],
      ),
    );
  }
}

class _Figures extends StatelessWidget {
  const _Figures({required this.summary});

  final CollectionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrStatGrid(
      tiles: [
        SrKpiTile(
          label: l10n.salesReceivable,
          value: fmt.moneyCompact(summary.receivable),
          delta: l10n.salesOverdueAmount(fmt.moneyCompact(summary.overdue)),
          deltaUp: summary.overdue > 0 ? true : null,
          upIsGood: false,
          onTap: () => context.push(Routes.outstanding),
        ),
        SrKpiTile(
          label: l10n.salesDueToday,
          value: fmt.moneyCompact(summary.dueToday),
          delta: l10n.salesCustomerCount(fmt.number(summary.dueTodayCustomers)),
        ),
        SrKpiTile(
          label: l10n.salesCollectedThisMonth,
          value: fmt.moneyCompact(summary.collectedThisMonth),
        ),
      ],
    );
  }
}

class _CollectToday extends ConsumerWidget {
  const _CollectToday();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAdd = ref.watch(moduleAccessProvider(AppModule.collection)).canAdd;
    final dues = ref.watch(dueListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrSectionHeader(
          title: l10n.salesCollectToday,
          actionLabel: l10n.salesAllOutstanding,
          onAction: () => context.push(Routes.outstanding),
        ),
        const SizedBox(height: 8),
        switch (dues) {
          AsyncValue(:final value?) when value.isEmpty => SrCard(
            child: Text(
              l10n.salesDuesEmpty,
              style: AppText.meta(SrColors.of(context).ink2),
            ),
          ),
          AsyncValue(:final value?) => SrRowGroup(
            dividerIndent: 66,
            rows: [
              for (final due in value.items.take(6))
                DueRowTile(
                  due: due,
                  onTap: canAdd
                      ? () => context.push(collectionNewForDue(due))
                      : null,
                ),
            ],
          ),
          AsyncValue(:final error?) => SrErrorState(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(dueListProvider),
          ),
          _ => const SrSkeletonList(
            count: 3,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
          ),
        },
      ],
    );
  }
}

class _RecentCollections extends ConsumerWidget {
  const _RecentCollections();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(collectionListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrSectionHeader(title: l10n.salesRecentCollections),
        const SizedBox(height: 8),
        switch (list) {
          AsyncValue(:final value?) when value.isEmpty => SrEmptyState(
            icon: Icons.payments_outlined,
            title: l10n.salesCollectionsEmpty,
          ),
          AsyncValue(:final value?) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SrRowGroup(
                dividerIndent: 66,
                rows: [
                  for (final row in value.items)
                    CollectionRow(
                      collection: row,
                      onTap: () => context.push(Routes.receiptFor(row.id)),
                    ),
                ],
              ),
              PagedFooter(
                paged: value,
                onRetry: () =>
                    ref.read(collectionListProvider.notifier).loadMore(),
              ),
            ],
          ),
          AsyncValue(:final error?) => SrErrorState(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(collectionListProvider),
          ),
          _ => const SrSkeletonList(
            count: 4,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
          ),
        },
      ],
    );
  }
}
