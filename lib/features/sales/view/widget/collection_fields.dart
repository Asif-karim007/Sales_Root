import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/providers/collection_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The method chips and the fields each method needs: a TrxID for bKash and
/// Nagad, the bank for a transfer, the bank, number and date for a cheque.
/// [easy] drops the optional fields.
class CollectionMethodFields extends StatefulWidget {
  const CollectionMethodFields({
    super.key,
    required this.easy,
    required this.draft,
    required this.form,
    required this.failure,
  });

  final bool easy;
  final CollectionDraft draft;
  final CollectionEntry form;

  /// The last save's validation failure, to mark the fields it names.
  final ApiFailure? failure;

  @override
  State<CollectionMethodFields> createState() => _CollectionMethodFieldsState();
}

class _CollectionMethodFieldsState extends State<CollectionMethodFields> {
  late final _reference = TextEditingController(text: widget.draft.reference);
  late final _sender = TextEditingController(text: widget.draft.senderNumber);
  late final _bank = TextEditingController(text: widget.draft.bankName);
  late final _cheque = TextEditingController(text: widget.draft.chequeNumber);
  late final _note = TextEditingController(text: widget.draft.note);

  @override
  void dispose() {
    _reference.dispose();
    _sender.dispose();
    _bank.dispose();
    _cheque.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _error(String field) => widget.failure?.fieldError(field) == null
      ? null
      : context.l10n.commonRequired;

  Future<void> _pickDate() async {
    final picked = await showSrDatePicker(
      context: context,
      initial: widget.draft.collectedAt,
      withTime: true,
      last: DateTime.now(),
    );
    if (picked != null) widget.form.setCollectedAt(picked);
  }

  Future<void> _pickChequeDate() async {
    final picked = await showSrDatePicker(
      context: context,
      initial: widget.draft.chequeDate ?? DateTime.now(),
    );
    if (picked != null) widget.form.setChequeDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final draft = widget.draft;
    final method = draft.method;
    final chequeDate = draft.chequeDate;
    final easy = widget.easy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrFieldLabel(l10n.salesMethod),
        const SizedBox(height: 6),
        SrChipRow(
          padding: EdgeInsets.zero,
          chips: [
            for (final m in PaymentMethod.values) SrChipItem(l10n.method(m)),
          ],
          index: method.index,
          onChanged: (i) => widget.form.setMethod(PaymentMethod.values[i]),
        ),
        const SizedBox(height: 12),
        SrPickerField(
          label: l10n.salesDateTime,
          icon: Icons.event_outlined,
          value:
              '${fmt.date(draft.collectedAt)} · ${fmt.time(draft.collectedAt)}',
          onTap: _pickDate,
        ),
        if (method.isMobile) ...[
          const SizedBox(height: 12),
          SrTextField(
            controller: _reference,
            label: l10n.salesTrxId,
            hint: l10n.salesTrxIdHint,
            textCapitalization: TextCapitalization.characters,
            error: _error('Reference'),
            onChanged: widget.form.setReference,
          ),
          if (!easy) ...[
            const SizedBox(height: 12),
            SrTextField(
              controller: _sender,
              label: l10n.salesSenderNumber,
              optional: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9+]')),
              ],
              onChanged: widget.form.setSenderNumber,
            ),
          ],
        ],
        if (method.needsBank) ...[
          const SizedBox(height: 12),
          SrTextField(
            controller: _bank,
            label: l10n.salesBankName,
            textCapitalization: TextCapitalization.words,
            error: _error('BankName'),
            onChanged: widget.form.setBankName,
          ),
        ],
        if (method == PaymentMethod.bank && !easy) ...[
          const SizedBox(height: 12),
          SrTextField(
            controller: _reference,
            label: l10n.salesReference,
            optional: true,
            onChanged: widget.form.setReference,
          ),
        ],
        if (method == PaymentMethod.cheque) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SrTextField(
                  controller: _cheque,
                  label: l10n.salesChequeNumber,
                  keyboardType: TextInputType.number,
                  error: _error('ChequeNumber'),
                  onChanged: widget.form.setChequeNumber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SrPickerField(
                  label: l10n.salesChequeDate,
                  icon: Icons.event_outlined,
                  placeholder: l10n.salesPickDate,
                  value: chequeDate == null ? null : fmt.dayMonth(chequeDate),
                  error: _error('ChequeDate'),
                  onTap: _pickChequeDate,
                ),
              ),
            ],
          ),
        ],
        if (!easy) ...[
          const SizedBox(height: 12),
          SrTextField(
            controller: _note,
            label: l10n.salesNote,
            optional: true,
            onChanged: widget.form.setNote,
          ),
        ],
      ],
    );
  }
}
