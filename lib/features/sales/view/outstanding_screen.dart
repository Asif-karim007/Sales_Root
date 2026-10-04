import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/providers/collection_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/sales_links.dart';
import 'package:salesroot/features/sales/view/widget/paged_footer.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/features/sales/view/widget/sales_rows.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #63: what customers owe, by age of the bill, and who owes it.
class OutstandingScreen extends ConsumerWidget {
  const OutstandingScreen({super.key});

  void _share(BuildContext context, OutstandingSummary summary) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final lines = [
      l10n.salesOutstandingTotal(fmt.moneyCompact(summary.total)),
      for (final bucket in AgingBucket.values)
        '${l10n.agingBucket(bucket)}: ${fmt.money(summary.buckets[bucket] ?? 0)}',
    ];
    SharePlus.instance.share(ShareParams(text: lines.join('\n')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(outstandingSummaryProvider);
    final filter = ref.watch(outstandingFilterProvider);
    final provider = outstandingListProvider(filter);
    final list = ref.watch(provider);
    final canAdd = ref.watch(moduleAccessProvider(AppModule.collection)).canAdd;
    final loaded = summary.value;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.salesOutstandingTitle,
        actions: [
          if (loaded != null)
            SrIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: l10n.commonShare,
              onTap: () => _share(context, loaded),
            ),
        ],
      ),
      body: SrAsyncView<OutstandingSummary>(
        value: summary,
        onRetry: () => ref.invalidate(outstandingSummaryProvider),
        onUpgrade: upgradeFor(context, summary.error),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, summary) => RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(provider)
              ..invalidate(outstandingSummaryProvider);
            await ref.read(outstandingSummaryProvider.future);
          },
          child: LoadMoreListener(
            paged: list.value,
            onLoadMore: () => ref.read(provider.notifier).loadMore(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SrMetrics.gutter,
                14,
                SrMetrics.gutter,
                32,
              ),
              children: [
                _AgingCard(summary: summary),
                const SizedBox(height: 14),
                SrChipRow(
                  padding: EdgeInsets.zero,
                  chips: [
                    SrChipItem(l10n.commonAll),
                    SrChipItem(l10n.salesOverdue, tone: SrTone.err),
                    SrChipItem(l10n.salesMine),
                    SrChipItem(l10n.salesByCustomer),
                  ],
                  index: filter.index,
                  onChanged: (i) => ref
                      .read(outstandingFilterProvider.notifier)
                      .set(OutstandingFilter.values[i]),
                ),
                const SizedBox(height: 10),
                _CustomerList(
                  value: list,
                  onRetry: () => ref.invalidate(provider),
                  onLoadMore: () => ref.read(provider.notifier).loadMore(),
                  onTap: canAdd
                      ? (row) => context.push(
                          collectionNewFor(customerId: row.companyId),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgingCard extends StatelessWidget {
  const _AgingCard({required this.summary});

  final OutstandingSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final largest = summary.buckets.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    final colors = {
      AgingBucket.upTo30: c.accent,
      AgingBucket.upTo60: c.warning,
      AgingBucket.upTo90: c.danger,
      AgingBucket.over90: c.danger,
    };
    return SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(
            title: l10n.salesOutstandingTotal(fmt.moneyCompact(summary.total)),
            actionLabel: l10n.salesCustomerCount(
              fmt.number(summary.customerCount),
            ),
          ),
          const SizedBox(height: 12),
          for (final bucket in AgingBucket.values) ...[
            SrBarRow(
              label: l10n.agingBucket(bucket),
              value: (summary.buckets[bucket] ?? 0).toDouble(),
              max: largest.toDouble(),
              valueLabel: fmt.moneyCompact(summary.buckets[bucket] ?? 0),
              color: colors[bucket],
              labelWidth: 72,
              valueWidth: 84,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({
    required this.value,
    required this.onRetry,
    required this.onLoadMore,
    required this.onTap,
  });

  final AsyncValue<Paged<CustomerOutstanding>> value;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<CustomerOutstanding>? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tap = onTap;
    return switch (value) {
      AsyncValue(:final value?) when value.isEmpty => SrEmptyState(
        icon: Icons.verified_outlined,
        title: l10n.salesNothingOutstanding,
      ),
      AsyncValue(:final value?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrRowGroup(
            dividerIndent: 66,
            rows: [
              for (final row in value.items)
                OutstandingRow(
                  customer: row,
                  onTap: tap == null ? null : () => tap(row),
                ),
            ],
          ),
          PagedFooter(paged: value, onRetry: onLoadMore),
        ],
      ),
      AsyncValue(:final error?) => SrErrorState(
        error: error,
        compact: true,
        onRetry: onRetry,
      ),
      _ => const SrSkeletonList(
        count: 5,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
    };
  }
}
