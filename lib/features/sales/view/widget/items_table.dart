import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/l10n/l10n.dart';

/// The prototype's `.qtable`: item, quantity and line amount.
class ItemsTable extends StatelessWidget {
  const ItemsTable({super.key, required this.lines});

  final List<SalesLine> lines;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final bangla = fmt.isBangla;
    final head = AppText.caption(c.ink3, size: 11.5);
    final body = AppText.meta(c.ink, size: 13);

    TableRow row(List<Widget> cells, {bool header = false}) => TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      children: [
        for (final cell in cells)
          Padding(
            padding: EdgeInsets.symmetric(vertical: header ? 6 : 8),
            child: cell,
          ),
      ],
    );

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(5),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(2.6),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        row(header: true, [
          Text(l10n.salesColItem, style: head),
          Text(l10n.salesColQty, style: head, textAlign: TextAlign.end),
          Text(l10n.salesColAmount, style: head, textAlign: TextAlign.end),
        ]),
        for (final line in lines)
          row([
            Text(
              line.discountBps > 0
                  ? '${line.nameIn(bangla: bangla)} · '
                        '${l10n.salesLineDiscount(fmt.bps(line.discountBps))}'
                  : line.nameIn(bangla: bangla),
              style: body,
            ),
            Text(fmt.qty(line.qty), style: body, textAlign: TextAlign.end),
            Text(fmt.money(line.net), style: body, textAlign: TextAlign.end),
          ]),
      ],
    );
  }
}
