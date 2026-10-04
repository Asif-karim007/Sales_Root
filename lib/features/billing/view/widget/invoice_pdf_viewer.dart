import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/pdf/billing_pdf.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

extension InvoiceLabels on BuildContext {
  String invoiceStatus(InvoiceStatus status) => switch (status) {
    InvoiceStatus.paid => l10n.billingStatusPaid,
    InvoiceStatus.failed => l10n.billingStatusFailed,
    InvoiceStatus.refunded => l10n.billingStatusRefunded,
  };

  /// "Business · October 2026" for a renewal, else the item name.
  String invoiceTitle(Invoice invoice) {
    final item = invoice.item.of(isBangla);
    final period = invoice.periodStart;
    if (invoice.kind != InvoiceKind.plan || period == null) return item;
    return joinDot([item, fmt.monthYear(period)]);
  }

  /// Renders [invoices] in the current language.
  Future<Uint8List> invoicesPdf(List<Invoice> invoices, String workspace) {
    final method = l10n.billingPdfNoMethod;
    final text = InvoicePdfText(
      brand: l10n.appName,
      title: l10n.billingPdfTitle,
      billedTo: l10n.billingPdfBilledTo,
      workspace: workspace,
      date: (invoice) =>
          joinDot([invoiceTitle(invoice), fmt.date(invoice.issuedAt)]),
      status: (invoice) => invoiceStatus(invoice.status),
      method: (invoice) {
        final paid = invoice.method;
        return paid == null ? method : methodLine(paid);
      },
      item: l10n.billingPdfItem,
      amount: l10n.billingPdfAmount,
      credits: l10n.billingCreditsApplied,
      vat: (invoice) => l10n.billingVat(fmt.number(invoice.quote.vatPercent)),
      total: l10n.billingPdfTotal,
      thanks: l10n.billingPdfThanks,
    );
    return buildInvoicesPdf(
      invoices: invoices,
      text: text,
      lineLabel: orderLineLabel,
      money: signedMoney,
    );
  }

  /// Opens the PDF full screen with share.
  void openPdf({
    required String name,
    required String title,
    required Future<Uint8List> Function() load,
  }) {
    Navigator.of(this).push(
      MaterialPageRoute<void>(
        builder: (_) => SrFileViewer(
          name: name,
          kind: SrFileKind.pdf,
          title: title,
          load: load,
        ),
      ),
    );
  }
}
