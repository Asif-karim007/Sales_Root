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
import 'package:salesroot/features/sales/view/widget/instalment_list.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/features/sales/view/widget/schedule_sheet.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #57: the order, where it stands, and its instalment schedule.
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, required this.id});

  final int id;

  void _outcome(BuildContext context, AsyncValue<OrderOutcome?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(value: OrderBilled(:final invoice)):
        showSrSuccess(context, l10n.salesBillCreated(invoice.number));
        context.push(Routes.invoiceFor(invoice.id));
      case AsyncData(value: OrderScheduleSaved()):
        showSrSuccess(context, l10n.salesScheduleSaved);
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
      footer: order != null && collect.canAdd && order.due > 0
          ? SrButton(
              label: l10n.salesRecordCollection,
              icon: Icons.payments_outlined,
              expand: true,
              onPressed: () => context.push(
                collectionNewFor(
                  customerId: order.companyId,
                  invoiceId: order.invoiceId,
                  orderId: order.invoiceId == null ? order.id : null,
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
    final orders = ref.watch(moduleAccessProvider(AppModule.order));
    final canEditSchedule = orders.canEdit && order.canEdit;
    final delivery = order.delivery;
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
          const SizedBox(height: 12),
          SrCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: SrSegmentBar(
              segments: OrderStatus.values.length,
              filled: order.status.index + 1,
              current: order.status.index,
              labels: [
                for (final status in OrderStatus.values)
                  l10n.orderStatus(status),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SrSectionHeader(
            title: l10n.salesPaymentSchedule,
            actionLabel: canEditSchedule ? l10n.commonEdit : null,
            onAction: () => showScheduleSheet(context, order),
          ),
          const SizedBox(height: 8),
          InstalmentList(instalments: order.instalments),
          if (delivery != null) ...[
            const SizedBox(height: 20),
            SrSectionHeader(title: l10n.salesDeliverySection),
            const SizedBox(height: 8),
            _DeliveryCard(delivery: delivery),
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
    final quotation = order.quotationNumber;
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
                  quotation == null
                      ? order.companyName
                      : l10n.salesFromQuotation(order.companyName, quotation),
                  style: AppText.meta(c.ink2),
                ),
              ],
            ),
          ),
          SrTag(
            l10n.orderStatus(order.status),
            tone: order.status == OrderStatus.invoiced
                ? SrTone.accent
                : SrTone.ok,
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          AmountLine(
            label: l10n.salesDeliveredOn,
            value:
                '${fmt.date(delivery.deliveredAt)} ${fmt.time(delivery.deliveredAt)}',
          ),
          AmountLine(label: l10n.salesReceivedBy, value: delivery.receivedBy),
          AmountLine(
            label: l10n.salesProof,
            value: [
              if (delivery.photoCount > 0)
                l10n.salesPhotoCount(fmt.number(delivery.photoCount)),
              if (delivery.signed) l10n.salesSigned,
            ].join(' · '),
          ),
          if (delivery.note.isNotEmpty)
            AmountLine(label: l10n.salesNote, value: delivery.note),
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
    final invoiceId = order.invoiceId;
    final buttons = [
      if (order.status.toDeliver && orders.canEdit && order.canEdit)
        SrButton(
          label: l10n.salesLogDelivery,
          icon: Icons.local_shipping_outlined,
          variant: SrButtonVariant.secondary,
          onPressed: () => context.push(Routes.orderDeliveryFor(order.id)),
        ),
      if (invoiceId != null && invoices.canView)
        SrButton(
          label: l10n.salesOpenBill,
          icon: Icons.receipt_long_outlined,
          variant: SrButtonVariant.secondary,
          onPressed: () => context.push(Routes.invoiceFor(invoiceId)),
        )
      else if (invoiceId == null && invoices.canAdd)
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
