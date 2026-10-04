import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

extension SalesFormat on AppFormat {
  /// 500 bps → 5%, 750 → 7.5%.
  String bps(int bps) =>
      '${number(bps / 100, decimals: bps % 100 == 0 ? 0 : 1)}%';

  String qty(int qty) => number(qty);
}

extension SalesLabels on AppLocalizations {
  String quotationStatus(QuotationStatus status) => switch (status) {
    QuotationStatus.draft => salesStatusDraft,
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
  };

  String category(ProductCategory category) => switch (category) {
    ProductCategory.solar => salesCategorySolar,
    ProductCategory.inverters => salesCategoryInverters,
    ProductCategory.batteries => salesCategoryBatteries,
    ProductCategory.accessories => salesCategoryAccessories,
    ProductCategory.lighting => salesCategoryLighting,
    ProductCategory.pumps => salesCategoryPumps,
    ProductCategory.services => salesCategoryServices,
  };

  String unit(String unit) => switch (unit) {
    'piece' => salesUnitPiece,
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

  String priceList(PriceList list) => switch (list) {
    PriceList.list => salesPriceListList,
    PriceList.dealer => salesPriceListDealer,
  };

  String paymentTerms(PaymentTerms terms) => switch (terms) {
    PaymentTerms.fullAdvance => salesTermsFullAdvance,
    PaymentTerms.advance50 => salesTermsAdvance50,
    PaymentTerms.advance50Split => salesTermsAdvance50Split,
    PaymentTerms.advance30 => salesTermsAdvance30,
    PaymentTerms.onDelivery => salesTermsOnDelivery,
    PaymentTerms.credit30 => salesTermsCredit30,
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

  String instalmentKind(InstalmentKind kind) => switch (kind) {
    InstalmentKind.advance => salesKindAdvance,
    InstalmentKind.onDelivery => salesKindOnDelivery,
    InstalmentKind.afterInstallation => salesKindAfterInstallation,
    InstalmentKind.onBill => salesKindOnBill,
  };

  String ordinal(int n) => switch (n) {
    1 => salesOrdinal1,
    2 => salesOrdinal2,
    3 => salesOrdinal3,
    4 => salesOrdinal4,
    _ => salesOrdinalN('$n'),
  };

  /// `2nd · on delivery`
  String instalment(Instalment instalment) =>
      '${ordinal(instalment.seq)} · ${instalmentKind(instalment.kind)}';

  String agingBucket(AgingBucket bucket) => switch (bucket) {
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
