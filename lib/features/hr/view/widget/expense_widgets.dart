import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/providers/expense_providers.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_line.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// One claim on the list; opens its detail sheet.
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({super.key, required this.claim});

  final ExpenseClaim claim;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final date = claim.expenseDate;
    final description = claim.description;
    final type = claim.typeName.of(fmt.isBangla);

    return SrCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: () => showSrSheet<void>(
        context: context,
        builder: (_) => ExpenseDetailSheet(claim: claim),
      ),
      child: Row(
        children: [
          SrAvatar(icon: claim.typeCode.expenseIcon, tone: SrAvatarTone.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description == null || description.isEmpty
                      ? type
                      : description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.rowTitle(c.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  [type, if (date != null) fmt.dayMonth(date)].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta(c.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmt.money(claim.cost), style: AppText.rowTitle(c.ink)),
              const SizedBox(height: 4),
              SrTag(l10n.expenseStage(claim.stage), tone: claim.stage.tone),
            ],
          ),
        ],
      ),
    );
  }
}

class ExpenseDetailSheet extends ConsumerWidget {
  const ExpenseDetailSheet({super.key, required this.claim});

  final ExpenseClaim claim;

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.hrWithdrawClaimTitle,
      message: l10n.hrWithdrawClaimBody,
      confirmLabel: l10n.hrWithdraw,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(expenseWithdrawProvider.notifier).withdraw(claim.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final withdrawing = ref.watch(expenseWithdrawProvider).isLoading;
    final note = claim.note;

    ref.listen(expenseWithdrawProvider, (_, next) {
      switch (next) {
        case AsyncData(value: final ExpenseClaim _):
          showSrSuccess(context, l10n.hrExpenseWithdrawn);
          Navigator.of(context).pop();
        case AsyncError(:final error):
          showHrFailure(context, error);
        default:
      }
    });

    return SrSheet(
      title: fmt.money(claim.cost),
      subtitle: claim.typeName.of(fmt.isBangla),
      trailing: SrTag(l10n.expenseStage(claim.stage), tone: claim.stage.tone),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (note != null && note.isNotEmpty) ...[
              SrNote(
                tone: SrNoteTone.gold,
                title: l10n.hrApproverNote,
                message: note,
              ),
              const SizedBox(height: 12),
            ],
            if (claim.isPending && claim.approvalStep > 1) ...[
              SrNote(message: l10n.hrExpenseWaitingManager),
              const SizedBox(height: 12),
            ],
            HrLineCard(lines: _lines(context)),
            if (claim.canWithdraw) ...[
              const SizedBox(height: 16),
              SrButton(
                label: l10n.hrWithdraw,
                variant: SrButtonVariant.danger,
                expand: true,
                loading: withdrawing,
                onPressed: () => _withdraw(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _lines(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final code = claim.code;
    final date = claim.expenseDate;
    final description = claim.description;
    final prospect = claim.prospectName;
    final approvedBy = claim.approvedByName;
    final receipts = claim.attachments;
    return [
      if (code != null) HrLine(label: l10n.hrExpenseDetailCode, value: code),
      if (date != null)
        HrLine(label: l10n.hrExpenseDate, value: fmt.date(date)),
      if (description != null && description.isNotEmpty)
        HrLine(label: l10n.hrExpenseNote, value: description),
      if (claim.hasRoute)
        HrLine(label: l10n.hrExpenseDetailRoute, value: expenseRoute(claim)),
      if (prospect != null)
        HrLine(label: l10n.hrExpenseDetailCustomer, value: prospect),
      if (claim.personCount > 1)
        HrLine(
          label: l10n.hrExpensePeople,
          value: fmt.number(claim.personCount),
        ),
      if (receipts.isNotEmpty)
        HrLine(
          label: l10n.hrExpenseReceipt,
          value: receipts.map((r) => r.name).join(', '),
        ),
      if (approvedBy != null)
        HrLine(
          label: l10n.hrExpenseDetailApprovedBy,
          value: approvedBy.of(fmt.isBangla),
        ),
    ];
  }
}

/// "Uttara → Banani", with whichever end is known.
String expenseRoute(ExpenseClaim claim) => [
  claim.startLocation,
  claim.endLocation,
].where((s) => s != null && s.isNotEmpty).join(' → ');

/// Totals per stage for the summary tiles, from the list's facets.
class ExpenseTotals extends StatelessWidget {
  const ExpenseTotals({super.key, required this.totals});

  final Map<String, int> totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    String total(ExpenseStage stage) =>
        fmt.moneyCompact(totals[stage.wire] ?? 0);

    return SrStatGrid(
      columns: 3,
      spacing: 8,
      tiles: [
        SrKpiTile(
          label: l10n.hrExpensePendingTotal,
          value: total(ExpenseStage.pending),
        ),
        SrKpiTile(
          label: l10n.hrExpenseApprovedTotal,
          value: total(ExpenseStage.approved),
        ),
        SrKpiTile(
          label: l10n.hrExpensePaidTotal,
          value: total(ExpenseStage.paid),
        ),
      ],
    );
  }
}
