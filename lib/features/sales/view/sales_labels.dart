import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

extension SalesFormat on AppFormat {
  /// 500 bps → 5%, 750 → 7.5%.
  String bps(int bps) =>
      '${number(bps / 100, decimals: bps % 100 == 0 ? 0 : 1)}%';

  /// Whole quantities without decimals, parts to two places.
  String qty(double qty) =>
      number(qty, decimals: qty == qty.roundToDouble() ? 0 : 2);
}

extension SalesLabels on AppLocalizations {
  String quotationStatus(QuotationStatus status) => switch (status) {
    QuotationStatus.draft => salesStatusDraft,
    QuotationStatus.pendingApproval => salesStatusPendingApproval,
    QuotationStatus.approved => salesStatusApproved,
    QuotationStatus.sent => salesStatusSent,
    QuotationStatus.viewed => salesStatusViewed,
    QuotationStatus.accepted => salesStatusAccepted,
    QuotationStatus.rejected => salesStatusRejected,
    QuotationStatus.expired => salesStatusExpired,
  };

  String orderStatus(OrderStatus status) => switch (status) {
    OrderStatus.confirmed => salesOrderConfirmed,
    OrderStatus.inProgress => salesOrderInProgress,
    OrderStatus.delivered => salesOrderDelivered,
    OrderStatus.invoiced => salesOrderInvoiced,
    OrderStatus.cancelled => salesCancelled,
  };

  String unit(String unit) => switch (unit) {
    'piece' || 'pc' || 'pcs' => salesUnitPiece,
    'metre' => salesUnitMetre,
    'pair' => salesUnitPair,
    'per kW' => salesUnitPerKw,
    'set' => salesUnitSet,
    'visit' => salesUnitVisit,
    'year' => salesUnitYear,
    'job' => salesUnitJob,
    'day' => salesUnitDay,
    _ => unit,
  };

  String channel(SendChannel channel) => switch (channel) {
    SendChannel.whatsApp => salesChannelWhatsApp,
    SendChannel.sms => salesChannelSms,
    SendChannel.email => salesChannelEmail,
    SendChannel.share => salesChannelShare,
  };

  String method(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => salesMethodCash,
    PaymentMethod.bkash => salesMethodBkash,
    PaymentMethod.nagad => salesMethodNagad,
    PaymentMethod.bank => salesMethodBank,
    PaymentMethod.cheque => salesMethodCheque,
  };

  String chequeStatus(ChequeStatus status) => switch (status) {
    ChequeStatus.pending => salesChequePending,
    ChequeStatus.cleared => salesChequeCleared,
    ChequeStatus.bounced => salesChequeBounced,
  };

  String ordinal(int n) => switch (n) {
    1 => salesOrdinal1,
    2 => salesOrdinal2,
    3 => salesOrdinal3,
    4 => salesOrdinal4,
    _ => salesOrdinalN('$n'),
  };

  /// `2nd instalment`, or the server's name for a receivable not split from
  /// a bill.
  String instalment(Instalment instalment) => switch (instalment.seq) {
    final seq? => salesInstalmentOf(ordinal(seq)),
    null => instalment.label,
  };

  String agingBucket(AgingBucket bucket) => switch (bucket) {
    AgingBucket.current => salesAgingCurrent,
    AgingBucket.upTo30 => salesAging0to30,
    AgingBucket.upTo60 => salesAging31to60,
    AgingBucket.upTo90 => salesAging61to90,
    AgingBucket.over90 => salesAging90plus,
  };

  String instalmentState(InstalmentState state) => switch (state) {
    InstalmentState.paid => salesInstalmentPaid,
    InstalmentState.partial => salesInstalmentPartial,
    InstalmentState.upcoming => salesInstalmentDue,
    InstalmentState.dueToday => salesInstalmentToday,
    InstalmentState.overdue => salesInstalmentOverdue,
  };
}

SrTone quotationTone(QuotationStatus status) => switch (status) {
  QuotationStatus.draft => SrTone.neutral,
  QuotationStatus.pendingApproval => SrTone.gold,
  QuotationStatus.approved => SrTone.ok,
  QuotationStatus.sent => SrTone.accent,
  QuotationStatus.viewed => SrTone.warn,
  QuotationStatus.accepted => SrTone.ok,
  QuotationStatus.rejected => SrTone.err,
  QuotationStatus.expired => SrTone.err,
};

SrTone instalmentTone(InstalmentState state) => switch (state) {
  InstalmentState.paid => SrTone.ok,
  InstalmentState.partial => SrTone.gold,
  InstalmentState.upcoming => SrTone.neutral,
  InstalmentState.dueToday => SrTone.warn,
  InstalmentState.overdue => SrTone.err,
};
