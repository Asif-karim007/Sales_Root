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
  String leaveStatus(LeaveStatus status) => switch (status) {
    LeaveStatus.pending => hrStatusPending,
    LeaveStatus.approved => hrStatusApproved,
    LeaveStatus.rejected => hrStatusRejected,
    LeaveStatus.cancelled => hrStatusWithdrawn,
  };

  String expenseStage(ExpenseStage stage) => switch (stage) {
    ExpenseStage.pending => hrStatusPending,
    ExpenseStage.approved => hrStatusApproved,
    ExpenseStage.paid => hrStatusPaid,
    ExpenseStage.rejected => hrStatusRejected,
  };

  String approvalState(ApprovalState state) => switch (state) {
    ApprovalState.pending => hrStatusPending,
    ApprovalState.approved => hrStatusApproved,
    ApprovalState.rejected => hrStatusRejected,
    ApprovalState.cancelled => hrStatusWithdrawn,
  };

  String approvalKind(ApprovalKind kind) => switch (kind) {
    ApprovalKind.leave => hrApprovalsLeave,
    ApprovalKind.expense => hrApprovalsExpense,
    ApprovalKind.collection => hrApprovalsCollection,
    ApprovalKind.other => hrApprovalsOther,
  };

  String approvalTag(ApprovalKind kind) => switch (kind) {
    ApprovalKind.collection => hrApprovalTagMoney,
    _ => approvalKind(kind),
  };

  String ticketStatus(TicketStatus status) => switch (status) {
    TicketStatus.fresh => hrTicketNew,
    TicketStatus.open => hrTicketOpen,
    TicketStatus.waiting => hrTicketWaiting,
    TicketStatus.resolved => hrTicketResolved,
    TicketStatus.closed => hrTicketClosed,
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
    'whatsapp' => hrSourceWhatsApp,
    'phone' => hrSourcePhone,
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
}

extension LeaveTone on LeaveRequest {
  SrTone get tone => switch (status) {
    LeaveStatus.approved => SrTone.ok,
    LeaveStatus.rejected => SrTone.err,
    LeaveStatus.cancelled => SrTone.neutral,
    LeaveStatus.pending => SrTone.warn,
  };
}

extension ExpenseStageTone on ExpenseStage {
  SrTone get tone => switch (this) {
    ExpenseStage.pending => SrTone.warn,
    ExpenseStage.approved => SrTone.accent,
    ExpenseStage.paid => SrTone.ok,
    ExpenseStage.rejected => SrTone.err,
  };
}

extension ApprovalStateTone on ApprovalState {
  SrTone get tone => switch (this) {
    ApprovalState.pending => SrTone.warn,
    ApprovalState.approved => SrTone.ok,
    ApprovalState.rejected => SrTone.err,
    ApprovalState.cancelled => SrTone.neutral,
  };
}

extension TicketStatusTone on TicketStatus {
  SrTone get tone => switch (this) {
    TicketStatus.fresh => SrTone.info,
    TicketStatus.open => SrTone.warn,
    TicketStatus.waiting => SrTone.gold,
    TicketStatus.resolved => SrTone.ok,
    TicketStatus.closed => SrTone.neutral,
  };
}

extension ExpenseTypeIcon on String {
  /// The icon for an expense category [ExpenseType.code].
  IconData get expenseIcon => switch (this) {
    'travel' => Icons.local_taxi_outlined,
    'fuel' => Icons.local_gas_station_outlined,
    'food' => Icons.restaurant_outlined,
    'entertainment' => Icons.local_cafe_outlined,
    'mobile' => Icons.phone_android_outlined,
    'lodging' => Icons.hotel_outlined,
    _ => Icons.receipt_long_outlined,
  };
}

extension PayslipLineLabel on PayslipLine {
  String label(AppLocalizations l10n, AppFormat fmt) {
    final count = this.count;
    return switch (code) {
      PayslipLineCode.basic => l10n.hrLineBasic,
      PayslipLineCode.houseRent => l10n.hrLineHouseRent,
      PayslipLineCode.medical => l10n.hrLineMedical,
      PayslipLineCode.conveyance => l10n.hrLineConveyance,
      PayslipLineCode.commission => switch (count) {
        null || 0 => l10n.hrLineCommission,
        1 => l10n.hrLineCommissionDeal(fmt.number(count)),
        _ => l10n.hrLineCommissionDeals(fmt.number(count)),
      },
      PayslipLineCode.bonus => l10n.hrLineBonus,
      PayslipLineCode.arrears => l10n.hrLineArrears,
      PayslipLineCode.reimbursement =>
        count == null
            ? l10n.hrLineReimbursementPlain
            : l10n.hrLineReimbursement(fmt.number(count)),
      PayslipLineCode.unpaidLeave =>
        count == null
            ? l10n.hrLineUnpaidLeavePlain
            : l10n.hrLineUnpaidLeave(fmt.days(count.toDouble())),
      PayslipLineCode.late =>
        count == null
            ? l10n.hrLineLatePlain
            : l10n.hrLineLate(fmt.days(count.toDouble())),
      PayslipLineCode.advanceRecovery => l10n.hrLineAdvance,
      PayslipLineCode.providentFund => l10n.hrLinePf,
      PayslipLineCode.tax => l10n.hrLineTax,
      PayslipLineCode.otherDeduction => l10n.hrLineOtherDeduction,
    };
  }
}
