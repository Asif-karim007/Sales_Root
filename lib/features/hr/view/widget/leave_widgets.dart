import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/providers/leave_providers.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_line.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Days free per paid leave type, as "7/10" tiles.
class LeaveBalanceGrid extends StatelessWidget {
  const LeaveBalanceGrid({super.key, required this.balances});

  final List<LeaveBalance> balances;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    String n(double value) =>
        fmt.number(value, decimals: value % 1 == 0 ? 0 : 1);

    return SrStatGrid(
      columns: 3,
      spacing: 8,
      tiles: [
        for (final balance in balances)
          if (balance.isPaid)
            SrKpiTile(
              label: balance.leaveType.of(fmt.isBangla),
              value:
                  '${n(balance.remainingAfterPending)}/${n(balance.entitlement)}',
              delta: balance.pending > 0
                  ? context.l10n.hrLeavePendingDays(fmt.days(balance.pending))
                  : null,
            ),
      ],
    );
  }
}

/// "Sick · 12 Sep" with its status; opens the request's detail sheet.
class LeaveRequestRow extends StatelessWidget {
  const LeaveRequestRow({
    super.key,
    required this.request,
    this.divider = false,
  });

  final LeaveRequest request;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final decidedBy = request.decidedByName;
    final status = l10n.leaveStatus(request.status);

    return SrListRow(
      leading: SrAvatar(
        icon: request.isApproved
            ? Icons.event_available_outlined
            : Icons.event_note_outlined,
        tone: request.isPending ? SrAvatarTone.gold : SrAvatarTone.accent,
      ),
      title:
          '${request.leaveType.of(fmt.isBangla)} · ${leaveRange(fmt, request)}',
      subtitle: [
        fmt.days(request.noOfDays),
        if (!request.isPending && decidedBy != null)
          '$status · ${decidedBy.split(' ').first}',
      ].join(' · '),
      trailing: SrTag(status, tone: request.tone),
      divider: divider,
      onTap: () => showSrSheet<void>(
        context: context,
        builder: (_) => LeaveDetailSheet(request: request),
      ),
    );
  }
}

/// "3–4 Oct", or one day.
String leaveRange(AppFormat fmt, LeaveRequest request) {
  final start = request.startDate;
  final end = request.endDate;
  if (start == null) return '';
  if (end == null || end == start) return fmt.dayMonth(start);
  return '${fmt.dayMonth(start)}–${fmt.dayMonth(end)}';
}

class LeaveDetailSheet extends ConsumerWidget {
  const LeaveDetailSheet({super.key, required this.request});

  final LeaveRequest request;

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.hrWithdrawLeaveTitle,
      message: l10n.hrWithdrawLeaveBody,
      confirmLabel: l10n.hrWithdraw,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(leaveWithdrawProvider.notifier).withdraw(request.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final withdrawing = ref.watch(leaveWithdrawProvider).isLoading;

    ref.listen(leaveWithdrawProvider, (_, next) {
      switch (next) {
        case AsyncData(value: final String _):
          showSrSuccess(context, l10n.hrLeaveWithdrawn);
          Navigator.of(context).pop();
        case AsyncError(:final error):
          showHrFailure(context, error);
        default:
      }
    });

    return SrSheet(
      title: request.leaveType.of(fmt.isBangla),
      subtitle: leaveRange(fmt, request),
      trailing: SrTag(l10n.leaveStatus(request.status), tone: request.tone),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HrLineCard(lines: _lines(context)),
            if (request.canWithdraw) ...[
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
    final decidedBy = request.decidedByName;
    final applied = request.appliedAt;
    final reason = request.reason;
    final remarks = request.remarks;
    return [
      HrLine(label: l10n.hrLeaveDetailDays, value: fmt.days(request.noOfDays)),
      if (applied != null)
        HrLine(label: l10n.hrLeaveDetailApplied, value: fmt.date(applied)),
      if (reason != null) HrLine(label: l10n.hrLeaveReason, value: reason),
      if (decidedBy != null)
        HrLine(label: l10n.hrLeaveDetailApprover, value: decidedBy),
      if (remarks != null) HrLine(label: l10n.hrApproverNote, value: remarks),
      if (request.hasDocument)
        HrLine(label: l10n.hrLeaveAttachment, value: l10n.hrAttached),
    ];
  }
}
