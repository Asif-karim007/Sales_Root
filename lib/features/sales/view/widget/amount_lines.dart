import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/translations/translations.dart';

/// The prototype's `.line`: a label and an amount; [strong] is the total row
/// with a hairline above it.
class AmountLine extends StatelessWidget {
  const AmountLine({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: strong
          ? BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? AppText.rowTitle(c.ink, size: 15)
                  : AppText.meta(c.ink2, size: 13.5),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.style(
                size: strong ? 16 : 14,
                weight: FontWeight.w600,
                color: valueColor ?? c.ink,
                tabular: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtotal, discount, VAT and total, plus what was collected and what is
/// still due when [collected] is given.
class SalesTotalsLines extends StatelessWidget {
  const SalesTotalsLines({
    super.key,
    required this.totals,
    required this.discountBps,
    required this.vatBps,
    this.itemCount,
    this.collected,
  });

  final SalesTotals totals;
  final int discountBps;
  final int vatBps;
  final int? itemCount;
  final int? collected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final c = SrColors.of(context);
    final count = itemCount;
    final paid = collected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AmountLine(
          label: count == null
              ? l10n.salesSubtotal
              : l10n.salesSubtotalItems(fmt.number(count)),
          value: fmt.money(totals.subtotal),
        ),
        if (totals.discount > 0)
          AmountLine(
            label: l10n.salesDiscountPercent(fmt.bps(discountBps)),
            value: '− ${fmt.money(totals.discount)}',
          ),
        AmountLine(
          label: l10n.salesVatPercent(fmt.bps(vatBps)),
          value: fmt.money(totals.vat),
        ),
        AmountLine(
          label: l10n.salesTotal,
          value: fmt.money(totals.total),
          strong: paid == null,
        ),
        if (paid != null) ...[
          AmountLine(label: l10n.salesCollected, value: '− ${fmt.money(paid)}'),
          AmountLine(
            label: l10n.salesDue,
            value: fmt.money(totals.total - paid),
            strong: true,
            valueColor: totals.total - paid > 0 ? c.danger : c.success,
          ),
        ],
      ],
    );
  }
}
