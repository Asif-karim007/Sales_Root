import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/providers/product_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/features/sales/view/widget/paged_footer.dart';
import 'package:salesroot/features/sales/view/widget/sales_rows.dart';
import 'package:salesroot/features/sales/view/widget/search_box.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #51: the catalogue with category chips, list or dealer prices and search
/// by name or code.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(productFilterProvider);
    final notifier = ref.read(productFilterProvider.notifier);
    final locale = ref.watch(appLocaleProvider);
    final provider = productListProvider(filter.search, filter.category);
    final list = ref.watch(provider);
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.salesProductsTitle,
        actions: [
          SrLanguageToggle(
            isBangla: locale == bangla,
            onChanged: (isBangla) => ref
                .read(appLocaleProvider.notifier)
                .set(isBangla ? bangla : english),
          ),
        ],
        bottom: SearchBox(
          hint: l10n.salesProductSearchHint,
          initial: filter.search,
          onSearch: notifier.setSearch,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _CategoryChips(
            counts: list.value?.facets['CategoryCounts'] ?? const {},
            selected: filter.category,
            onChanged: notifier.setCategory,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              8,
              SrMetrics.gutter,
              4,
            ),
            child: _PriceListSwitch(
              value: filter.priceList,
              onChanged: (_) => notifier.togglePriceList(),
            ),
          ),
          Expanded(
            child: SrAsyncView<Paged<Product>>(
              value: list,
              onRetry: () => ref.invalidate(provider),
              isEmpty: (paged) => paged.isEmpty,
              empty: (_) => SrEmptyState(
                icon: Icons.inventory_2_outlined,
                title: l10n.salesProductsEmpty,
                message: filter.search.isEmpty
                    ? null
                    : l10n.salesNoMatchFor(filter.search),
              ),
              data: (context, paged) => RefreshIndicator(
                onRefresh: () => ref.refresh(provider.future),
                child: LoadMoreListener(
                  paged: paged,
                  onLoadMore: () => ref.read(provider.notifier).loadMore(),
                  child: _ProductList(
                    paged: paged,
                    priceList: filter.priceList,
                    onRetry: () => ref.read(provider.notifier).loadMore(),
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

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  final Map<String, int> counts;
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ProductCategory.values;
    final current = selected;
    return SrChipRow(
      chips: [
        SrChipItem(l10n.commonAll, count: counts['All']),
        for (final category in categories)
          SrChipItem(l10n.category(category), count: counts[category.wire]),
      ],
      index: current == null ? 0 : categories.indexOf(current) + 1,
      onChanged: (i) => onChanged(i == 0 ? null : categories[i - 1]),
    );
  }
}

class _PriceListSwitch extends StatelessWidget {
  const _PriceListSwitch({required this.value, required this.onChanged});

  final PriceList value;
  final ValueChanged<PriceList> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(child: Text(l10n.salesPriceList, style: AppText.meta(c.ink2))),
        SizedBox(
          width: 190,
          child: SrSegmented(
            compact: true,
            segments: [
              SrSegment(l10n.priceList(PriceList.list)),
              SrSegment(l10n.priceList(PriceList.dealer)),
            ],
            index: value.index,
            onChanged: (i) => onChanged(PriceList.values[i]),
          ),
        ),
      ],
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.paged,
    required this.priceList,
    required this.onRetry,
  });

  final Paged<Product> paged;
  final PriceList priceList;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        8,
        SrMetrics.gutter,
        32,
      ),
      children: [
        SrRowGroup(
          dividerIndent: 66,
          rows: [
            for (final product in paged.items)
              ProductRow(
                product: product,
                priceList: priceList,
                onTap: () => showSrSheet<void>(
                  context: context,
                  builder: (_) => _ProductSheet(product: product),
                ),
              ),
          ],
        ),
        PagedFooter(paged: paged, onRetry: onRetry),
      ],
    );
  }
}

class _ProductSheet extends StatelessWidget {
  const _ProductSheet({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final p = product;
    final stock = p.stock;
    return SrSheet(
      title: p.nameIn(bangla: fmt.isBangla),
      subtitle: '${p.code} · ${l10n.category(p.category)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountLine(label: l10n.salesUnit, value: l10n.unit(p.unit)),
          AmountLine(
            label: l10n.priceList(PriceList.list),
            value: fmt.money(p.price),
          ),
          AmountLine(
            label: l10n.priceList(PriceList.dealer),
            value: fmt.money(p.dealerPrice),
          ),
          AmountLine(label: l10n.salesVat, value: fmt.bps(p.vatBps)),
          AmountLine(
            label: l10n.salesStockLabel,
            value: stock == null ? l10n.salesNoStockKept : fmt.number(stock),
          ),
        ],
      ),
    );
  }
}
