import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Today, Yesterday or `4 Oct`.
String salesDay(BuildContext context, DateTime date) {
  final now = DateTime.now();
  if (AppDateUtils.isSameDay(date, now)) return context.l10n.commonToday;
  if (AppDateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
    return context.l10n.commonYesterday;
  }
  return context.fmt.dayMonth(date);
}

class QuotationRow extends StatelessWidget {
  const QuotationRow({super.key, required this.quotation, this.onTap});

  final Quotation quotation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final q = quotation;
    return SrListRow(
      leading: SrAvatar(name: q.companyName),
      title: '${q.number} · ${q.companyName}',
      subtitle: [
        salesDay(context, q.sentAt ?? q.createdAt),
        if (q.ownerName.isNotEmpty) q.ownerName,
      ].join(' · '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SrRowTrailing(value: fmt.money(q.totals.total)),
          const SizedBox(height: 4),
          SrTag(l10n.quotationStatus(q.status), tone: quotationTone(q.status)),
        ],
      ),
      onTap: onTap,
    );
  }
}

class ProductRow extends StatelessWidget {
  const ProductRow({
    super.key,
    required this.product,
    this.showStock = false,
    this.onTap,
  });

  final Product product;
  final bool showStock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final p = product;
    final stock = p.stock;
    return SrListRow(
      leading: SrAvatar(name: p.name, square: true),
      title: p.nameIn(bangla: fmt.isBangla),
      subtitle: [
        if (p.code.isNotEmpty) p.code,
        l10n.unit(p.unit),
        if (p.vatBps > 0) l10n.salesVatPercent(fmt.bps(p.vatBps)),
      ].join(' · '),
      trailing: showStock
          ? stock == null
                ? null
                : SrTag(
                    l10n.salesStock(fmt.qty(stock)),
                    tone: stock <= 0
                        ? SrTone.err
                        : stock < 10
                        ? SrTone.warn
                        : SrTone.ok,
                  )
          : SrRowTrailing(value: fmt.money(p.price)),
      onTap: onTap,
    );
  }
}

class OrderRow extends StatelessWidget {
  const OrderRow({super.key, required this.order, this.onTap});

  final SalesOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final c = SrColors.of(context);
    final o = order;
    return SrListRow(
      leading: const SrAvatar(
        icon: Icons.inventory_2_outlined,
        square: true,
        tone: SrAvatarTone.accent,
      ),
      title: '${o.number} · ${o.companyName}',
      subtitle: '${l10n.orderStatus(o.status)} · ${fmt.dayMonth(o.createdAt)}',
      trailing: SrRowTrailing(
        value: fmt.money(o.totals.total),
        valueColor: c.ink,
      ),
      onTap: onTap,
    );
  }
}

class InvoiceRow extends StatelessWidget {
  const InvoiceRow({super.key, required this.invoice, this.onTap});

  final Invoice invoice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    final i = invoice;
    return SrListRow(
      leading: SrAvatar(name: i.companyName),
      title: '${i.number} · ${i.companyName}',
      subtitle: [fmt.dayMonth(i.issuedAt), ?i.orderNumber].join(' · '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SrRowTrailing(value: fmt.money(i.totals.total)),
          const SizedBox(height: 4),
          InvoiceTag(status: i.status, due: i.due),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// What is left on a bill: due, paid in full, or cancelled.
class InvoiceTag extends StatelessWidget {
  const InvoiceTag({super.key, required this.status, required this.due});

  final InvoiceStatus status;
  final double due;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (status == InvoiceStatus.cancelled) {
      return SrTag(l10n.salesCancelled, tone: SrTone.neutral);
    }
    return due > 0
        ? SrTag(
            l10n.salesDueAmountLabel(context.fmt.money(due)),
            tone: SrTone.err,
          )
        : SrTag(l10n.salesPaidInFull, tone: SrTone.ok);
  }
}

class CollectionRow extends StatelessWidget {
  const CollectionRow({super.key, required this.collection, this.onTap});

  final Collection collection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final c = SrColors.of(context);
    final row = collection;
    return SrListRow(
      leading: const SrAvatar(
        icon: Icons.payments_outlined,
        square: true,
        tone: SrAvatarTone.accent,
      ),
      title: row.companyName,
      subtitle: [
        row.number,
        l10n.method(row.method),
        '${salesDay(context, row.collectedAt)} ${fmt.time(row.collectedAt)}',
      ].join(' · '),
      trailing: row.cancelled
          ? SrTag(l10n.salesCancelled, tone: SrTone.neutral)
          : SrRowTrailing(value: fmt.money(row.amount), valueColor: c.success),
      onTap: onTap,
    );
  }
}

class OutstandingRow extends StatelessWidget {
  const OutstandingRow({super.key, required this.customer, this.onTap});

  final CustomerOutstanding customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final c = SrColors.of(context);
    final row = customer;
    final oldest = row.oldestDueDate;
    return SrListRow(
      leading: SrAvatar(name: row.companyName),
      title: row.companyName,
      subtitle: row.isOverdue
          ? l10n.salesBillsOldest(
              fmt.number(row.items),
              fmt.number(row.oldestDays),
            )
          : l10n.salesDueCount(fmt.number(row.items)),
      trailing: SrRowTrailing(
        value: fmt.money(row.due),
        meta: row.isOverdue
            ? l10n.salesOverdue
            : oldest == null
            ? null
            : l10n.salesDueOn(fmt.dayMonth(oldest)),
        valueColor: row.isOverdue ? c.danger : c.ink,
      ),
      chevron: onTap != null,
      onTap: onTap,
    );
  }
}
