import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/providers/product_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/features/sales/view/widget/product_form_sheet.dart';
import 'package:salesroot/features/sales/view/widget/sales_rows.dart';
import 'package:salesroot/features/sales/view/widget/search_box.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #51: the catalogue, searched by name or code.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final search = ref.watch(productSearchProvider);
    final locale = ref.watch(appLocaleProvider);
    final canAdd = ref.watch(moduleAccessProvider(AppModule.product)).canAdd;
    final provider = productListProvider(search);
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
          if (canAdd)
            SrIconButton(
              icon: Icons.add_rounded,
              tooltip: l10n.salesAddProduct,
              onTap: () => showProductForm(context),
            ),
        ],
        bottom: SearchBox(
          hint: l10n.salesProductSearchHint,
          initial: search,
          onSearch: ref.read(productSearchProvider.notifier).set,
        ),
      ),
      body: SrAsyncView<Paged<Product>>(
        value: list,
        onRetry: () => ref.invalidate(provider),
        isEmpty: (paged) => paged.isEmpty,
        empty: (_) => SrEmptyState(
          icon: Icons.inventory_2_outlined,
          title: l10n.salesProductsEmpty,
          message: search.isEmpty ? null : l10n.salesNoMatchFor(search),
          actionLabel: canAdd && search.isEmpty ? l10n.salesAddProduct : null,
          onAction: () => showProductForm(context),
        ),
        data: (context, paged) => RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: _ProductList(products: paged.items),
        ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        12,
        SrMetrics.gutter,
        32,
      ),
      children: [
        SrRowGroup(
          dividerIndent: 66,
          rows: [
            for (final product in products)
              ProductRow(
                product: product,
                onTap: () => showSrSheet<void>(
                  context: context,
                  builder: (_) => _ProductSheet(
                    product: product,
                    onEdit: () => showProductForm(context, product: product),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProductSheet extends ConsumerWidget {
  const _ProductSheet({required this.product, required this.onEdit});

  final Product product;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final p = product;
    final stock = p.stock;
    final canEdit = ref.watch(moduleAccessProvider(AppModule.product)).canEdit;
    return SrSheet(
      title: p.nameIn(bangla: fmt.isBangla),
      subtitle: p.code.isEmpty ? null : p.code,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountLine(label: l10n.salesUnit, value: l10n.unit(p.unit)),
          AmountLine(label: l10n.salesPrice, value: fmt.money(p.price)),
          AmountLine(label: l10n.salesVat, value: fmt.bps(p.vatBps)),
          AmountLine(
            label: l10n.salesStockLabel,
            value: stock == null ? l10n.salesNoStockKept : fmt.qty(stock),
          ),
          if (canEdit) ...[
            const SizedBox(height: 14),
            SrButton(
              label: l10n.salesEditProduct,
              icon: Icons.edit_outlined,
              variant: SrButtonVariant.secondary,
              expand: true,
              onPressed: () {
                Navigator.of(context).pop();
                onEdit();
              },
            ),
          ],
        ],
      ),
    );
  }
}
