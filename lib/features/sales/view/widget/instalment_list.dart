import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// What a bill is to be paid in: each instalment with its date, amount and
/// whether it is collected, due or overdue.
class InstalmentList extends StatelessWidget {
  const InstalmentList({super.key, required this.instalments});

  final List<Instalment> instalments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrRowGroup(
      dividerIndent: 66,
      rows: [
        for (final row in instalments)
          SrListRow(
            leading: SrAvatar(
              icon: row.state == InstalmentState.paid
                  ? Icons.check_rounded
                  : Icons.schedule_rounded,
              tone: row.state == InstalmentState.paid
                  ? SrAvatarTone.accent
                  : row.state == InstalmentState.overdue
                  ? SrAvatarTone.danger
                  : SrAvatarTone.neutral,
            ),
            title: l10n.instalment(row),
            subtitle: row.paid > 0 && row.due > 0
                ? '${fmt.dayMonth(row.dueDate)} · ${l10n.salesCollectedAmount(fmt.money(row.paid))}'
                : fmt.dayMonth(row.dueDate),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                SrRowTrailing(value: fmt.money(row.amount)),
                const SizedBox(height: 4),
                SrTag(
                  l10n.instalmentState(row.state),
                  tone: instalmentTone(row.state),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
