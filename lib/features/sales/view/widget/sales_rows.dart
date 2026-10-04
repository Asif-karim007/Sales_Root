import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
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

/// When an open instalment is due: `12 days overdue`, `today`, `on 15 Oct`.
String dueWhen(BuildContext context, Instalment instalment) {
  final l10n = context.l10n;
  final days = instalment.daysOverdue ?? -1;
  if (days > 0) return l10n.salesOverdueDays(context.fmt.number(days));
  if (days == 0) return l10n.commonToday;
  return l10n.salesDueOn(context.fmt.dayMonth(instalment.dueDate));
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
    final via = q.sentVia;
    final order = q.orderNumber;
    final meta = [
      salesDay(context, q.sentAt ?? q.createdAt),
      if (q.version > 1) l10n.salesVersion(fmt.number(q.version)),
      if (order != null)
        l10n.salesOrderMade(order)
      else if (q.viewCount > 0)
        l10n.salesViewedTimes(fmt.number(q.viewCount))
      else if (via != null)
        l10n.channel(via),
    ];
    return SrListRow(
      leading: SrAvatar(name: q.companyName),
      title: '${q.number} · ${q.companyName}',
      subtitle: meta.join(' · '),
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
    required this.priceList,
    this.showStock = false,
    this.onTap,
  });

  final Product product;
  final PriceList priceList;
  final bool showStock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final p = product;
    final other = priceList == PriceList.list
        ? PriceList.dealer
        : PriceList.list;
    final stock = p.stock;
    return SrListRow(
      leading: SrAvatar(name: p.name, square: true),
      title: p.nameIn(bangla: fmt.isBangla),
      subtitle: [
        p.code,
        l10n.unit(p.unit),
        l10n.salesVatPercent(fmt.bps(p.vatBps)),
      ].join(' · '),
      trailing: showStock
          ? stock == null
                ? null
                : SrTag(
                    l10n.salesStock(fmt.number(stock)),
                    tone: stock == 0
                        ? SrTone.err
                        : stock < 10
                        ? SrTone.warn
                        : SrTone.ok,
                  )
          : SrRowTrailing(
              value: fmt.money(p.priceIn(priceList)),
              meta: p.sameInAllLists
                  ? l10n.salesSameInAllLists
                  : '${l10n.priceList(other)} ${fmt.money(p.priceIn(other))}',
            ),
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
        meta: o.due > 0
            ? l10n.salesDueAmountLabel(fmt.money(o.due))
            : l10n.salesPaidInFull,
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
    final l10n = context.l10n;
    final fmt = context.fmt;
    final i = invoice;
    return SrListRow(
      leading: SrAvatar(name: i.companyName),
      title: '${i.number} · ${i.companyName}',
      subtitle: '${fmt.dayMonth(i.issuedAt)} · ${i.orderNumber}',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SrRowTrailing(value: fmt.money(i.totals.total)),
          const SizedBox(height: 4),
          i.due > 0
              ? SrTag(
                  l10n.salesDueAmountLabel(fmt.money(i.due)),
                  tone: SrTone.err,
                )
              : SrTag(l10n.salesPaidInFull, tone: SrTone.ok),
        ],
      ),
      onTap: onTap,
    );
  }
}

class DueRowTile extends StatelessWidget {
  const DueRowTile({super.key, required this.due, this.onTap});

  final DueRow due;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final instalment = due.instalment;
    final state = instalment.state;
    return SrListRow(
      leading: SrAvatar(name: due.companyName),
      title: due.companyName,
      subtitle: [
        due.invoiceNumber ?? due.orderNumber,
        l10n.salesInstalmentOf(l10n.ordinal(instalment.seq)),
        dueWhen(context, instalment),
      ].join(' · '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SrRowTrailing(value: fmt.money(instalment.due)),
          const SizedBox(height: 4),
          SrTag(l10n.instalmentState(state), tone: instalmentTone(state)),
        ],
      ),
      onTap: onTap,
    );
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
      trailing: SrRowTrailing(
        value: fmt.money(row.amount),
        valueColor: c.success,
      ),
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
    final next = row.nextDueDate;
    return SrListRow(
      leading: SrAvatar(name: row.companyName),
      title: row.companyName,
      subtitle: l10n.salesBillsOldest(
        fmt.number(row.bills),
        fmt.number(row.oldestDays),
      ),
      trailing: SrRowTrailing(
        value: fmt.money(row.due),
        meta: next == null
            ? null
            : row.overdue
            ? l10n.salesOverdue
            : fmt.dayMonth(next),
        valueColor: row.overdue ? c.danger : c.ink,
      ),
      chevron: onTap != null,
      onTap: onTap,
    );
  }
}
