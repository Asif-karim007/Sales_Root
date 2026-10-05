import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

const _counts = [2, 3, 4, 6, 12];
const _intervals = [7, 15, 30];

Future<void> showSplitSheet(BuildContext context, Invoice invoice) =>
    showSrSheet<void>(
      context: context,
      builder: (_) => _SplitSheet(invoice: invoice),
    );

/// Splits what is left on a bill into equal instalments.
class _SplitSheet extends ConsumerStatefulWidget {
  const _SplitSheet({required this.invoice});

  final Invoice invoice;

  @override
  ConsumerState<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends ConsumerState<_SplitSheet> {
  int _count = 2;
  int _interval = 30;
  late DateTime _first = DateTime.now().add(const Duration(days: 7));

  InstalmentPlan get _plan => InstalmentPlan(
    count: _count,
    intervalDays: _interval,
    firstDueDate: _first,
  );

  Future<void> _pickFirst() async {
    final picked = await showSrDatePicker(context: context, initial: _first);
    if (picked != null) setState(() => _first = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final provider = invoiceActionsProvider(widget.invoice.id);
    final busy = ref.watch(provider).isLoading;
    ref.listen(provider, (_, next) {
      if (next case AsyncData(value: InvoiceChange.split)) {
        Navigator.of(context).pop();
      }
    });
    final plan = _plan;
    final parts = plan.split(widget.invoice.due);
    return SrSheet(
      title: l10n.salesSplitInstalments,
      subtitle: l10n.salesDueAmountLabel(fmt.money(widget.invoice.due)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.salesSplitHint, style: AppText.meta(c.ink2)),
          const SizedBox(height: 12),
          SrFieldLabel(l10n.salesInstalmentCount),
          const SizedBox(height: 6),
          SrChipRow(
            padding: EdgeInsets.zero,
            chips: [for (final n in _counts) SrChipItem(fmt.number(n))],
            index: _counts.indexOf(_count),
            onChanged: (i) => setState(() => _count = _counts[i]),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SrPickerField(
                  label: l10n.salesFirstDue,
                  icon: Icons.event_outlined,
                  value: fmt.dayMonth(_first),
                  onTap: _pickFirst,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SrDropdownField(
                  label: l10n.salesInterval,
                  value: l10n.salesEveryDays(fmt.number(_interval)),
                  onTap: () async {
                    final picked = await showSrSheet<int>(
                      context: context,
                      builder: (_) => SrOptionSheet<int>(
                        title: l10n.salesInterval,
                        options: _intervals,
                        labelOf: (days) =>
                            l10n.salesEveryDays(fmt.number(days)),
                        isSelected: (days) => days == _interval,
                      ),
                    );
                    if (picked != null) setState(() => _interval = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < parts.length; i++)
            AmountLine(
              label:
                  '${l10n.salesInstalmentOf(l10n.ordinal(i + 1))} · ${fmt.dayMonth(plan.dueOf(i))}',
              value: fmt.money(parts[i]),
            ),
          const SizedBox(height: 14),
          SrButton(
            label: l10n.commonSave,
            expand: true,
            loading: busy,
            onPressed: busy
                ? null
                : () => ref.read(provider.notifier).split(plan),
          ),
        ],
      ),
    );
  }
}
