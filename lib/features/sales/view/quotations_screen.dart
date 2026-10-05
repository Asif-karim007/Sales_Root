import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/paged_footer.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/features/sales/view/widget/sales_rows.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #55: quotations by status.
class QuotationsScreen extends ConsumerWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAdd = ref.watch(moduleAccessProvider(AppModule.quotation)).canAdd;
    final status = ref.watch(quotationStatusFilterProvider);
    final list = ref.watch(quotationListProvider);
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.salesQuotations,
        actions: [
          if (canAdd)
            SrIconButton(
              icon: Icons.add_rounded,
              tooltip: l10n.salesNewQuotation,
              onTap: () => context.push(Routes.quotationNew),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _StatusChips(
            selected: status,
            onChanged: ref.read(quotationStatusFilterProvider.notifier).set,
          ),
          Expanded(
            child: SrAsyncView<Paged<Quotation>>(
              value: list,
              onRetry: () => ref.invalidate(quotationListProvider),
              onUpgrade: upgradeFor(context, list.error),
              isEmpty: (paged) => paged.isEmpty,
              empty: (_) => SrEmptyState(
                icon: Icons.request_quote_outlined,
                title: l10n.salesQuotationsEmpty,
                message: l10n.salesQuotationsEmptyBody,
                actionLabel: canAdd ? l10n.salesNewQuotation : null,
                onAction: () => context.push(Routes.quotationNew),
              ),
              data: (context, paged) => RefreshIndicator(
                onRefresh: () => ref.refresh(quotationListProvider.future),
                child: LoadMoreListener(
                  paged: paged,
                  onLoadMore: () =>
                      ref.read(quotationListProvider.notifier).loadMore(),
                  child: _QuotationList(
                    paged: paged,
                    onRetry: () =>
                        ref.read(quotationListProvider.notifier).loadMore(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.selected, required this.onChanged});

  final QuotationStatus? selected;
  final ValueChanged<QuotationStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const statuses = QuotationStatus.values;
    final current = selected;
    return SrChipRow(
      chips: [
        SrChipItem(l10n.commonAll),
        for (final status in statuses)
          SrChipItem(l10n.quotationStatus(status), tone: quotationTone(status)),
      ],
      index: current == null ? 0 : statuses.indexOf(current) + 1,
      onChanged: (i) => onChanged(i == 0 ? null : statuses[i - 1]),
    );
  }
}

class _QuotationList extends StatelessWidget {
  const _QuotationList({required this.paged, required this.onRetry});

  final Paged<Quotation> paged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        10,
        SrMetrics.gutter,
        32,
      ),
      children: [
        SrRowGroup(
          dividerIndent: 66,
          rows: [
            for (final quotation in paged.items)
              QuotationRow(
                quotation: quotation,
                onTap: () => context.push(Routes.quotationFor(quotation.id)),
              ),
          ],
        ),
        PagedFooter(paged: paged, onRetry: onRetry),
      ],
    );
  }
}
