import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/sales_links.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/features/sales/view/widget/button_row.dart';
import 'package:salesroot/features/sales/view/widget/items_table.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/features/sales/view/widget/sales_rows.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #57: the order, where it stands, and the bills made from it.
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, required this.id});

  final String id;

  void _outcome(BuildContext context, AsyncValue<Invoice?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(:final value?):
        showSrSuccess(context, l10n.salesBillCreated(value.number));
        context.push(Routes.invoiceFor(value.id));
      case AsyncError(:final error):
        showSalesFailure(context, error);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(orderProvider(id));
    final order = value.value;
    final collect = ref.watch(moduleAccessProvider(AppModule.collection));
    ref.listen(orderActionsProvider(id), (_, next) => _outcome(context, next));
    final quotationId = order?.quotationId;
    final bill = order?.openInvoice;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.salesOrder,
        actions: [
          if (quotationId != null)
            SrIconButton(
              icon: Icons.request_quote_outlined,
              tooltip: l10n.salesOpenQuotation,
              onTap: () => context.push(Routes.quotationFor(quotationId)),
            ),
        ],
      ),
      body: SrAsyncView<SalesOrder>(
        value: value,
        onRetry: () => ref.invalidate(orderProvider(id)),
        onUpgrade: upgradeFor(context, value.error),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, order) => _OrderBody(order: order),
      ),
      footer: order != null && bill != null && collect.canAdd
          ? SrButton(
              label: l10n.salesRecordCollection,
              icon: Icons.payments_outlined,
              expand: true,
              onPressed: () => context.push(
                collectionNewFor(
                  customerId: order.companyId,
                  invoiceId: bill.id,
                ),
              ),
            )
          : null,
    );
  }
}

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order});

  final SalesOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final invoices = ref.watch(moduleAccessProvider(AppModule.invoice));
    const steps = OrderStatus.steps;
    final step = steps.indexOf(order.status);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(orderProvider(order.id).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          SrMetrics.gutter,
          14,
          SrMetrics.gutter,
          32,
        ),
        children: [
          _OrderHeader(order: order),
          if (step >= 0) ...[
            const SizedBox(height: 12),
            SrCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: SrSegmentBar(
                segments: steps.length,
                filled: step + 1,
                current: step,
                labels: [for (final status in steps) l10n.orderStatus(status)],
              ),
            ),
          ],
          if (order.lines.isNotEmpty) ...[
            const SizedBox(height: 12),
            SrCard(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ItemsTable(lines: order.lines),
                  const SizedBox(height: 4),
                  SalesTotalsLines(totals: order.totals),
                ],
              ),
            ),
          ],
          if (order.invoices.isNotEmpty && invoices.canView) ...[
            const SizedBox(height: 20),
            SrSectionHeader(title: l10n.salesBills),
            const SizedBox(height: 8),
            SrRowGroup(
              dividerIndent: 66,
              rows: [
                for (final bill in order.invoices)
                  SrListRow(
                    leading: const SrAvatar(
                      icon: Icons.receipt_long_outlined,
                      square: true,
                      tone: SrAvatarTone.accent,
                    ),
                    title: bill.number,
                    subtitle: context.fmt.dayMonth(bill.issuedAt),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SrRowTrailing(value: context.fmt.money(bill.total)),
                        const SizedBox(height: 4),
                        InvoiceTag(status: bill.status, due: bill.due),
                      ],
                    ),
                    onTap: () => context.push(Routes.invoiceFor(bill.id)),
                  ),
              ],
            ),
          ],
          if (order.deliveryDate != null || order.note.isNotEmpty) ...[
            const SizedBox(height: 20),
            SrSectionHeader(title: l10n.salesDeliverySection),
            const SizedBox(height: 8),
            _DeliveryCard(order: order),
          ],
          const SizedBox(height: 16),
          _OrderActions(order: order),
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final SalesOrder order;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrCard(
      child: Row(
        children: [
          const SrAvatar(
            icon: Icons.inventory_2_outlined,
            size: 44,
            square: true,
            tone: SrAvatarTone.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.salesOrderTitle(
                    order.number,
                    fmt.money(order.totals.total),
                  ),
                  style: AppText.rowTitle(c.ink),
                ),
                Text(
                  [
                    order.companyName,
                    if (order.contactName.isNotEmpty) order.contactName,
                  ].join(' · '),
                  style: AppText.meta(c.ink2),
                ),
              ],
            ),
          ),
          SrTag(
            l10n.orderStatus(order.status),
            tone: switch (order.status) {
              OrderStatus.invoiced => SrTone.accent,
              OrderStatus.cancelled => SrTone.neutral,
              _ => SrTone.ok,
            },
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  final SalesOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final delivered = order.deliveryDate;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          if (delivered != null)
            AmountLine(
              label: l10n.salesDeliveryDate,
              value: context.fmt.date(delivered),
            ),
          if (order.note.isNotEmpty)
            AmountLine(label: l10n.salesNote, value: order.note),
        ],
      ),
    );
  }
}

class _OrderActions extends ConsumerWidget {
  const _OrderActions({required this.order});

  final SalesOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orders = ref.watch(moduleAccessProvider(AppModule.order));
    final invoices = ref.watch(moduleAccessProvider(AppModule.invoice));
    final busy = ref.watch(orderActionsProvider(order.id)).isLoading;
    final canBill =
        order.invoices.isEmpty &&
        order.status != OrderStatus.cancelled &&
        invoices.canAdd;
    final buttons = [
      if (order.status.toDeliver && orders.canEdit)
        SrButton(
          label: l10n.salesLogDelivery,
          icon: Icons.local_shipping_outlined,
          variant: SrButtonVariant.secondary,
          onPressed: () => context.push(Routes.orderDeliveryFor(order.id)),
        ),
      if (canBill)
        SrButton(
          label: l10n.salesCreateBill,
          icon: Icons.receipt_long_outlined,
          variant: SrButtonVariant.secondary,
          loading: busy,
          onPressed: busy
              ? null
              : ref.read(orderActionsProvider(order.id).notifier).createInvoice,
        ),
    ];
    return ButtonRow(buttons: buttons);
  }
}
