import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/providers/quotation_wizard.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/features/sales/view/widget/quote_items_step.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

const _deliveryChoices = [3, 7, 14, 21, 30, 45];

/// What a percentage field shows for [bps]: empty for none, `5`, `7.5`.
String _percentText(int bps) {
  if (bps == 0) return '';
  final percent = percentFromBps(bps);
  return percent == percent.roundToDouble()
      ? percent.toStringAsFixed(0)
      : percent.toString();
}

/// #53: the overall and per-line discount, VAT, validity, payment and
/// delivery terms, and the note printed on the quotation.
class QuoteTermsStep extends StatefulWidget {
  const QuoteTermsStep({super.key, required this.draft, required this.wizard});

  final QuotationDraft draft;
  final QuotationWizard wizard;

  @override
  State<QuoteTermsStep> createState() => _QuoteTermsStepState();
}

class _QuoteTermsStepState extends State<QuoteTermsStep> {
  late final _discount = TextEditingController(
    text: _percentText(widget.draft.discountBps),
  );
  late final _note = TextEditingController(text: widget.draft.note);

  @override
  void dispose() {
    _discount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickValidity() async {
    final now = DateTime.now();
    final picked = await showSrDatePicker(
      context: context,
      initial: widget.draft.validUntil,
      first: DateTime(now.year, now.month, now.day),
      last: now.add(const Duration(days: 365)),
    );
    if (picked != null) widget.wizard.setValidUntil(picked);
  }

  Future<void> _pickTerms() async {
    final l10n = context.l10n;
    final picked = await showSrSheet<PaymentTerms>(
      context: context,
      builder: (_) => SrOptionSheet<PaymentTerms>(
        title: l10n.salesPaymentTerms,
        options: PaymentTerms.values,
        labelOf: l10n.paymentTerms,
        isSelected: (t) => t == widget.draft.paymentTerms,
      ),
    );
    if (picked != null) widget.wizard.setPaymentTerms(picked);
  }

  Future<void> _pickDelivery() async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final picked = await showSrSheet<int>(
      context: context,
      builder: (_) => SrOptionSheet<int>(
        title: l10n.salesDelivery,
        options: _deliveryChoices,
        labelOf: (days) => l10n.salesWithinDays(fmt.number(days)),
        isSelected: (days) => days == widget.draft.deliveryDays,
      ),
    );
    if (picked != null) widget.wizard.setDeliveryDays(picked);
  }

  Future<void> _editLine(SalesLine line) => showSrSheet<void>(
    context: context,
    builder: (_) => _LineSheet(line: line, wizard: widget.wizard),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final draft = widget.draft;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        14,
        SrMetrics.gutter,
        32,
      ),
      children: [
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SalesTotalsLines(
            totals: draft.totals,
            discountBps: draft.discountBps,
            vatBps: standardVatBps,
            itemCount: draft.itemCount,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SrTextField(
                controller: _discount,
                label: l10n.salesDiscount,
                hint: '0',
                suffixText: '%',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,2}(\.\d?)?'),
                  ),
                ],
                onChanged: (value) => widget.wizard.setDiscount(
                  bpsFromPercent(double.tryParse(value) ?? 0),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrPickerField(
                label: l10n.salesValidUntil,
                icon: Icons.event_outlined,
                value: fmt.dayMonth(draft.validUntil),
                onTap: _pickValidity,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SrDropdownField(
          label: l10n.salesPaymentTerms,
          value: l10n.paymentTerms(draft.paymentTerms),
          onTap: _pickTerms,
        ),
        const SizedBox(height: 12),
        SrDropdownField(
          label: l10n.salesDelivery,
          value: l10n.salesWithinDays(fmt.number(draft.deliveryDays)),
          onTap: _pickDelivery,
        ),
        const SizedBox(height: 12),
        SrTextField(
          controller: _note,
          label: l10n.salesNotePrinted,
          optional: true,
          multiline: true,
          maxLength: 400,
          onChanged: widget.wizard.setNote,
        ),
        const SizedBox(height: 18),
        SrSectionHeader(title: l10n.salesLineDiscounts),
        const SizedBox(height: 8),
        SrRowGroup(
          rows: [
            for (final line in draft.lines)
              SrListRow(
                title: line.nameIn(bangla: fmt.isBangla),
                subtitle:
                    '${fmt.qty(line.qty)} × ${fmt.money(line.unitPrice)}${line.discountBps > 0 ? ' · ${l10n.salesLineDiscount(fmt.bps(line.discountBps))}' : ''}',
                trailing: SrRowTrailing(value: fmt.money(line.net)),
                chevron: true,
                onTap: () => _editLine(line),
              ),
          ],
        ),
      ],
    );
  }
}

class _LineSheet extends StatefulWidget {
  const _LineSheet({required this.line, required this.wizard});

  final SalesLine line;
  final QuotationWizard wizard;

  @override
  State<_LineSheet> createState() => _LineSheetState();
}

class _LineSheetState extends State<_LineSheet> {
  late int _qty = widget.line.qty;
  late final _discount = TextEditingController(
    text: _percentText(widget.line.discountBps),
  );

  @override
  void dispose() {
    _discount.dispose();
    super.dispose();
  }

  void _save() {
    final line = widget.line;
    widget.wizard
      ..setQty(line.productId, _qty)
      ..setLineDiscount(
        line.productId,
        bpsFromPercent(double.tryParse(_discount.text) ?? 0),
      );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final c = SrColors.of(context);
    final line = widget.line;
    return SrSheet(
      title: line.nameIn(bangla: fmt.isBangla),
      subtitle: '${fmt.money(line.unitPrice)} / ${l10n.unit(line.unit)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SrFieldLabel(l10n.salesQuantity)),
              QtyStepper(
                qty: _qty,
                onChanged: (qty) => setState(() => _qty = qty < 0 ? 0 : qty),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SrTextField(
            controller: _discount,
            label: l10n.salesLineDiscountLabel,
            hint: '0',
            suffixText: '%',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d?)?')),
            ],
          ),
          if (_qty == 0) ...[
            const SizedBox(height: 10),
            Text(l10n.salesRemoveLineHint, style: AppText.meta(c.danger)),
          ],
          const SizedBox(height: 16),
          SrButton(label: l10n.commonDone, expand: true, onPressed: _save),
        ],
      ),
    );
  }
}
