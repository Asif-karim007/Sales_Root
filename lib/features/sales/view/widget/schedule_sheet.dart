import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

Future<void> showScheduleSheet(BuildContext context, SalesOrder order) =>
    showSrSheet<void>(
      context: context,
      builder: (_) => _ScheduleSheet(order: order),
    );

class _Row {
  _Row(this.instalment)
    : amount = TextEditingController(text: '${instalment.amount}'),
      dueDate = instalment.dueDate;

  final Instalment instalment;
  final TextEditingController amount;
  DateTime dueDate;

  int get value => int.tryParse(amount.text.trim()) ?? 0;
}

/// Edits the payment schedule; the amounts have to add up to the total.
class _ScheduleSheet extends ConsumerStatefulWidget {
  const _ScheduleSheet({required this.order});

  final SalesOrder order;

  @override
  ConsumerState<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends ConsumerState<_ScheduleSheet> {
  late final List<_Row> _rows = [
    for (final instalment in widget.order.instalments) _Row(instalment),
  ];

  @override
  void dispose() {
    for (final row in _rows) {
      row.amount.dispose();
    }
    super.dispose();
  }

  int get _left =>
      widget.order.totals.total - _rows.fold(0, (sum, r) => sum + r.value);

  void _add() {
    final last = _rows.last.dueDate;
    setState(
      () => _rows.add(
        _Row(
          Instalment(
            seq: _rows.length + 1,
            kind: InstalmentKind.onBill,
            dueDate: last.add(const Duration(days: 15)),
            amount: _left > 0 ? _left : 0,
          ),
        ),
      ),
    );
  }

  void _remove(_Row row) {
    setState(() => _rows.remove(row));
    row.amount.dispose();
  }

  Future<void> _pickDate(_Row row) async {
    final picked = await showSrDatePicker(
      context: context,
      initial: row.dueDate,
    );
    if (picked != null) setState(() => row.dueDate = picked);
  }

  void _save() =>
      ref.read(orderActionsProvider(widget.order.id).notifier).saveSchedule([
        for (var i = 0; i < _rows.length; i++)
          Instalment(
            seq: i + 1,
            kind: _rows[i].instalment.kind,
            dueDate: _rows[i].dueDate,
            amount: _rows[i].value,
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final busy = ref.watch(orderActionsProvider(widget.order.id)).isLoading;
    ref.listen(orderActionsProvider(widget.order.id), (_, next) {
      if (next case AsyncData(value: OrderScheduleSaved())) {
        Navigator.of(context).pop();
      }
    });
    final left = _left;
    return SrSheet(
      title: l10n.salesPaymentSchedule,
      subtitle: l10n.salesScheduleTotal(fmt.money(widget.order.totals.total)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (var i = 0; i < _rows.length; i++)
                  _ScheduleRowEditor(
                    label: l10n.instalment(_rows[i].instalment),
                    row: _rows[i],
                    onDate: () => _pickDate(_rows[i]),
                    onChanged: () => setState(() {}),
                    onRemove: _rows.length > 1 && _rows[i].instalment.paid == 0
                        ? () => _remove(_rows[i])
                        : null,
                  ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SrButton(
              label: l10n.salesAddInstalment,
              icon: Icons.add_rounded,
              variant: SrButtonVariant.ghost,
              size: SrButtonSize.sm,
              onPressed: _add,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            left == 0
                ? l10n.salesScheduleBalanced
                : l10n.salesScheduleLeft(fmt.money(left)),
            style: AppText.meta(left == 0 ? c.success : c.danger),
          ),
          const SizedBox(height: 12),
          SrButton(
            label: l10n.commonSave,
            expand: true,
            loading: busy,
            onPressed: left == 0 && !busy ? _save : null,
          ),
        ],
      ),
    );
  }
}

class _ScheduleRowEditor extends StatelessWidget {
  const _ScheduleRowEditor({
    required this.label,
    required this.row,
    required this.onDate,
    required this.onChanged,
    required this.onRemove,
  });

  final String label;
  final _Row row;
  final VoidCallback onDate;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remove = onRemove;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SrFieldLabel(label)),
              if (remove != null)
                SrIconButton(
                  icon: Icons.close_rounded,
                  compact: true,
                  tooltip: l10n.commonDelete,
                  onTap: remove,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SrTextField(
                  controller: row.amount,
                  prefix: Text(l10n.salesTaka),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SrPickerField(
                  icon: Icons.event_outlined,
                  value: context.fmt.dayMonth(row.dueDate),
                  onTap: onDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
