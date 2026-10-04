import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/hr/models/approval.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/models/payroll.dart';
import 'package:salesroot/features/hr/models/ticket.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The words and tones HR screens use for server codes.
extension HrLabels on AppLocalizations {
  String leaveStatus(int statusId) => switch (statusId) {
    LeaveStatusRef.approved => hrStatusApproved,
    LeaveStatusRef.rejected => hrStatusRejected,
    _ => hrStatusPending,
  };

  String expenseStage(ExpenseStage stage) => switch (stage) {
    ExpenseStage.pending => hrStatusPending,
    ExpenseStage.returned => hrStatusReturned,
    ExpenseStage.approved => hrStatusApproved,
    ExpenseStage.paid => hrStatusPaid,
    ExpenseStage.rejected => hrStatusRejected,
    ExpenseStage.withdrawn => hrStatusWithdrawn,
  };

  String approvalState(ApprovalState state) => switch (state) {
    ApprovalState.pending => hrStatusPending,
    ApprovalState.approved => hrStatusApproved,
    ApprovalState.rejected => hrStatusRejected,
  };

  String approvalKind(ApprovalKind kind) => switch (kind) {
    ApprovalKind.leave => hrApprovalsLeave,
    ApprovalKind.expense => hrApprovalsExpense,
    ApprovalKind.collection => hrApprovalsCollection,
  };

  String approvalTag(ApprovalKind kind) => switch (kind) {
    ApprovalKind.leave => hrApprovalsLeave,
    ApprovalKind.expense => hrApprovalsExpense,
    ApprovalKind.collection => hrApprovalTagMoney,
  };

  String collectionMethod(String method) => switch (method) {
    'Cash' => hrMethodCash,
    'bKash' => hrMethodBkash,
    'Cheque' => hrMethodCheque,
    'Bank' => hrMethodBank,
    _ => method,
  };

  String ticketStatus(TicketStatus status) => switch (status) {
    TicketStatus.open => hrTicketOpen,
    TicketStatus.inProgress => hrTicketInProgress,
    TicketStatus.onHold => hrTicketOnHold,
    TicketStatus.resolved => hrTicketResolved,
  };

  String ticketPriority(TicketPriority priority) => switch (priority) {
    TicketPriority.low => hrPriorityLow,
    TicketPriority.medium => hrPriorityMedium,
    TicketPriority.high => hrPriorityHigh,
    TicketPriority.urgent => hrPriorityUrgent,
  };

  String ticketIssue(TicketIssue issue) => switch (issue) {
    TicketIssue.problem => hrIssueProblem,
    TicketIssue.installation => hrIssueInstallation,
    TicketIssue.warranty => hrIssueWarranty,
    TicketIssue.billing => hrIssueBilling,
    TicketIssue.other => hrIssueOther,
  };

  String ticketSource(String? source) => switch (source) {
    'WhatsApp' => hrSourceWhatsApp,
    'Phone' => hrSourcePhone,
    _ => hrSourceFieldVisit,
  };
}

extension HrFormat on AppFormat {
  /// `1 day`, `1.5 days`; Bangla has one form.
  String days(double value) {
    final text = number(value, decimals: value % 1 == 0 ? 0 : 1);
    return value == 1 ? _l10n.hrDaySingle(text) : _l10n.hrDayPlural(text);
  }

  /// `1%`, `0.5%`
  String rate(double value) =>
      '${number(value, decimals: value % 1 == 0 ? 0 : 1)}%';

  AppLocalizations get _l10n => lookupAppLocalizations(locale);

  /// `9:00 AM` from a server `09:00`.
  String clock(String? hhmm) {
    final parts = (hhmm ?? '').split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return time(DateTime(2000, 1, 1, hour, minute));
  }

  /// `2:10` for a number of minutes.
  String hoursMinutes(int minutes) {
    final whole = minutes.abs();
    final mm = (whole % 60).toString().padLeft(2, '0');
    return digits('${whole ~/ 60}:$mm');
  }
}

extension LeaveTone on LeaveRequest {
  SrTone get tone => switch (statusId) {
    LeaveStatusRef.approved => SrTone.ok,
    LeaveStatusRef.rejected => SrTone.err,
    _ => SrTone.warn,
  };
}

extension ExpenseStageTone on ExpenseStage {
  SrTone get tone => switch (this) {
    ExpenseStage.pending => SrTone.warn,
    ExpenseStage.returned => SrTone.gold,
    ExpenseStage.approved => SrTone.accent,
    ExpenseStage.paid => SrTone.ok,
    ExpenseStage.rejected => SrTone.err,
    ExpenseStage.withdrawn => SrTone.neutral,
  };
}

extension ApprovalStateTone on ApprovalState {
  SrTone get tone => switch (this) {
    ApprovalState.pending => SrTone.warn,
    ApprovalState.approved => SrTone.ok,
    ApprovalState.rejected => SrTone.err,
  };
}

extension TicketStatusTone on TicketStatus {
  SrTone get tone => switch (this) {
    TicketStatus.open => SrTone.info,
    TicketStatus.inProgress => SrTone.warn,
    TicketStatus.onHold => SrTone.neutral,
    TicketStatus.resolved => SrTone.ok,
  };
}

extension ExpenseTypeIcon on String {
  /// The icon for an expense category [ExpenseType.code].
  IconData get expenseIcon => switch (this) {
    'Travel' => Icons.local_taxi_outlined,
    'Meals' => Icons.restaurant_outlined,
    'Entertainment' => Icons.local_cafe_outlined,
    'Mobile' => Icons.phone_android_outlined,
    _ => Icons.receipt_long_outlined,
  };
}

extension PayslipLineLabel on PayslipLine {
  String label(AppLocalizations l10n, AppFormat fmt) {
    final count = this.count ?? 0;
    return switch (code) {
      PayslipLineCode.basic => l10n.hrLineBasic,
      PayslipLineCode.houseRent => l10n.hrLineHouseRent,
      PayslipLineCode.conveyance => l10n.hrLineConveyance,
      PayslipLineCode.commission => switch (count) {
        0 => l10n.hrLineCommission,
        1 => l10n.hrLineCommissionDeal(fmt.number(count)),
        _ => l10n.hrLineCommissionDeals(fmt.number(count)),
      },
      PayslipLineCode.reimbursement => l10n.hrLineReimbursement(
        fmt.number(count),
      ),
      PayslipLineCode.unpaidLeave => l10n.hrLineUnpaidLeave(
        fmt.days(count.toDouble()),
      ),
      PayslipLineCode.late => l10n.hrLineLate(fmt.days(count.toDouble())),
      PayslipLineCode.advanceRecovery => l10n.hrLineAdvance,
      PayslipLineCode.providentFund => l10n.hrLinePf,
    };
  }
}
