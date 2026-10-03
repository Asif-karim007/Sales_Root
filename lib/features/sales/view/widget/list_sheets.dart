import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/view/widget/paged_footer.dart';
import 'package:salesroot/features/sales/view/widget/sales_rows.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Orders, or those still to deliver, in a sheet; a row opens the order.
Future<void> showOrdersSheet(BuildContext context, {bool toDeliver = false}) =>
    showSrSheet<void>(
      context: context,
      builder: (_) => _OrdersSheet(toDeliver: toDeliver),
    );

Future<void> showInvoicesSheet(BuildContext context) =>
    showSrSheet<void>(context: context, builder: (_) => const _InvoicesSheet());

class _OrdersSheet extends ConsumerWidget {
  const _OrdersSheet({required this.toDeliver});

  final bool toDeliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = orderListProvider(toDeliver: toDeliver);
    return SrSheet(
      title: toDeliver ? l10n.salesToDeliver : l10n.salesOrders,
      child: _PagedSheetBody(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        onLoadMore: () => ref.read(provider.notifier).loadMore(),
        empty: l10n.salesOrdersEmpty,
        row: (order) => OrderRow(
          order: order,
          onTap: () {
            Navigator.of(context).pop();
            context.push(Routes.orderFor(order.id));
          },
        ),
      ),
    );
  }
}

class _InvoicesSheet extends ConsumerWidget {
  const _InvoicesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.salesBills,
      child: _PagedSheetBody(
        value: ref.watch(invoiceListProvider),
        onRetry: () => ref.invalidate(invoiceListProvider),
        onLoadMore: () => ref.read(invoiceListProvider.notifier).loadMore(),
        empty: l10n.salesBillsEmpty,
        row: (invoice) => InvoiceRow(
          invoice: invoice,
          onTap: () {
            Navigator.of(context).pop();
            context.push(Routes.invoiceFor(invoice.id));
          },
        ),
      ),
    );
  }
}

class _PagedSheetBody<T> extends StatelessWidget {
  const _PagedSheetBody({
    required this.value,
    required this.onRetry,
    required this.onLoadMore,
    required this.empty,
    required this.row,
  });

  final AsyncValue<Paged<T>> value;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final String empty;
  final Widget Function(T item) row;

  @override
  Widget build(BuildContext context) {
    return SrAsyncView<Paged<T>>(
      value: value,
      onRetry: onRetry,
      isEmpty: (paged) => paged.isEmpty,
      empty: (_) => SrEmptyState(title: empty),
      loading: (_) => const SrSkeletonList(
        count: 5,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
      data: (context, paged) => LoadMoreListener(
        paged: paged,
        onLoadMore: onLoadMore,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: paged.items.length + 1,
          separatorBuilder: (context, _) =>
              Divider(height: 1, color: SrColors.of(context).line),
          itemBuilder: (context, index) => index == paged.items.length
              ? PagedFooter(paged: paged, onRetry: onLoadMore)
              : row(paged.items[index]),
        ),
      ),
    );
  }
}
