import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/translations/translations.dart';

/// Builds the quotation, bill and receipt PDFs in the app's language, set in
/// the bundled Anek Bangla so Bangla text and ৳ render.
class SalesPdf {
  SalesPdf(this.l10n, this.fmt);

  final AppLocalizations l10n;
  final AppFormat fmt;

  static Future<pw.ThemeData>? _theme;

  static Future<pw.ThemeData> _loadTheme() async {
    final regular = await rootBundle.load(
      'assets/fonts/AnekBangla-Regular.ttf',
    );
    final bold = await rootBundle.load('assets/fonts/AnekBangla-SemiBold.ttf');
    return pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }

  bool get _bangla => fmt.isBangla;

  static final PdfColor _accent = PdfColor.fromInt(
    SrColors.light.accent.toARGB32(),
  );
  static final PdfColor _ink2 = PdfColor.fromInt(
    SrColors.light.ink2.toARGB32(),
  );
  static final PdfColor _rule = PdfColor.fromInt(
    SrColors.light.line.toARGB32(),
  );
  static final PdfColor _tint = PdfColor.fromInt(
    SrColors.light.tint.toARGB32(),
  );

  Future<Uint8List> quotation(
    Quotation quotation,
    SellerProfile seller, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) => _document(
    format: format,
    seller: seller,
    title: l10n.salesPdfQuotation,
    number: quotation.number,
    date: quotation.createdAt,
    body: [
      _party(quotation.companyName, quotation.contactName),
      pw.SizedBox(height: 14),
      _items(quotation.lines),
      pw.SizedBox(height: 8),
      _totals(
        quotation.totals,
        discountBps: quotation.discountBps,
        vatBps: quotation.vatBps,
      ),
      pw.SizedBox(height: 14),
      _paragraph(
        [
          l10n.salesValidTo(fmt.date(quotation.validUntil)),
          l10n.paymentTerms(quotation.paymentTerms),
          l10n.salesDeliveryInDays(fmt.number(quotation.deliveryDays)),
        ].join(' · '),
      ),
      if (quotation.note.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        _paragraph(quotation.note),
      ],
    ],
  );

  Future<Uint8List> invoice(
    Invoice invoice,
    SellerProfile seller, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) => _document(
    format: format,
    seller: seller,
    title: seller.taxInvoices ? l10n.salesPdfTaxInvoice : l10n.salesPdfBill,
    number: invoice.number,
    date: invoice.issuedAt,
    body: [
      _party(invoice.companyName, invoice.contactName),
      pw.SizedBox(height: 4),
      _paragraph(l10n.salesAgainstOrder(invoice.orderNumber)),
      pw.SizedBox(height: 14),
      _items(invoice.lines),
      pw.SizedBox(height: 8),
      _totals(
        invoice.totals,
        discountBps: invoice.discountBps,
        vatBps: invoice.vatBps,
        collected: invoice.paid,
      ),
      if (invoice.instalments.isNotEmpty) ...[
        pw.SizedBox(height: 16),
        pw.Text(
          l10n.salesInstalments,
          style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        for (final row in invoice.instalments)
          _line(
            '${l10n.instalment(row)} · ${fmt.date(row.dueDate)}',
            '${fmt.money(row.amount)} · ${l10n.instalmentState(row.state)}',
          ),
      ],
    ],
  );

  Future<Uint8List> receipt(
    Collection collection,
    SellerProfile seller, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) => _document(
    format: format,
    seller: seller,
    title: l10n.salesPdfReceipt,
    number: collection.number,
    date: collection.collectedAt,
    withTime: true,
    body: [
      _line(l10n.salesReceivedFrom, collection.companyName),
      _line(l10n.salesAmount, fmt.money(collection.amount), strong: true),
      _line(l10n.salesMethod, receiptMethod(l10n, collection)),
      for (final allocation in collection.allocations)
        _line(l10n.salesAgainst, allocationLabel(l10n, fmt, allocation)),
      _line(l10n.salesBalanceDue, fmt.money(collection.balanceDue)),
      _line(l10n.salesReceivedBy, collection.receivedByIn(bangla: _bangla)),
      pw.SizedBox(height: 48),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 160,
          padding: const pw.EdgeInsets.only(top: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _ink2)),
          ),
          child: pw.Text(
            l10n.salesSignature,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 9, color: _ink2),
          ),
        ),
      ),
    ],
  );

  Future<Uint8List> _document({
    required PdfPageFormat format,
    required SellerProfile seller,
    required String title,
    required String number,
    required DateTime date,
    required List<pw.Widget> body,
    bool withTime = false,
  }) async {
    final theme = await (_theme ??= _loadTheme());
    final document = pw.Document(theme: theme, title: number);
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => _header(seller, title, number, date, withTime),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            l10n.salesPdfFooter,
            style: pw.TextStyle(fontSize: 8, color: _ink2),
          ),
        ),
        build: (_) => body,
      ),
    );
    return document.save();
  }

  pw.Widget _header(
    SellerProfile seller,
    String title,
    String number,
    DateTime date,
    bool withTime,
  ) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 18),
    padding: const pw.EdgeInsets.only(bottom: 12),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _rule)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                seller.name,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${seller.address} · ${fmt.phone(seller.phone)}',
                style: pw.TextStyle(fontSize: 9, color: _ink2),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              withTime
                  ? '$number · ${fmt.date(date)} · ${fmt.time(date)}'
                  : '$number · ${fmt.date(date)}',
              style: pw.TextStyle(fontSize: 9, color: _ink2),
            ),
          ],
        ),
      ],
    ),
  );

  pw.Widget _party(String company, String contact) => pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '${l10n.salesPdfTo} ',
          style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.TextSpan(text: contact.isEmpty ? company : '$company · $contact'),
      ],
    ),
  );

  pw.Widget _items(List<SalesLine> lines) {
    pw.Widget cell(String text, {bool head = false, bool end = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            text,
            textAlign: end ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: head ? 9 : 10,
              fontWeight: head ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: head ? _ink2 : null,
            ),
          ),
        );
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(2.2),
        3: pw.FlexColumnWidth(2.4),
      },
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _rule, width: 0.6),
        bottom: pw.BorderSide(color: _rule, width: 0.6),
      ),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _tint),
          children: [
            cell(l10n.salesColItem, head: true),
            cell(l10n.salesColQty, head: true, end: true),
            cell(l10n.salesColRate, head: true, end: true),
            cell(l10n.salesColAmount, head: true, end: true),
          ],
        ),
        for (final line in lines)
          pw.TableRow(
            children: [
              cell(
                line.discountBps > 0
                    ? '${line.nameIn(bangla: _bangla)} '
                          '(${l10n.salesLineDiscount(fmt.bps(line.discountBps))})'
                    : line.nameIn(bangla: _bangla),
              ),
              cell('${fmt.qty(line.qty)} ${l10n.unit(line.unit)}', end: true),
              cell(fmt.money(line.unitPrice), end: true),
              cell(fmt.money(line.net), end: true),
            ],
          ),
      ],
    );
  }

  pw.Widget _totals(
    SalesTotals totals, {
    required int discountBps,
    required int vatBps,
    int? collected,
  }) => pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.SizedBox(
      width: 240,
      child: pw.Column(
        children: [
          _line(l10n.salesSubtotal, fmt.money(totals.subtotal)),
          if (totals.discount > 0)
            _line(
              l10n.salesDiscountPercent(fmt.bps(discountBps)),
              '− ${fmt.money(totals.discount)}',
            ),
          _line(l10n.salesVatPercent(fmt.bps(vatBps)), fmt.money(totals.vat)),
          _line(l10n.salesTotal, fmt.money(totals.total), strong: true),
          if (collected != null) ...[
            _line(l10n.salesCollected, '− ${fmt.money(collected)}'),
            _line(
              l10n.salesDue,
              fmt.money(totals.total - collected),
              strong: true,
            ),
          ],
        ],
      ),
    ),
  );

  pw.Widget _line(String label, String value, {bool strong = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: pw.TextStyle(fontSize: 10, color: _ink2),
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: strong ? 12 : 10,
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  pw.Widget _paragraph(String text) =>
      pw.Text(text, style: pw.TextStyle(fontSize: 9.5, color: _ink2));
}

/// `bKash · BKX7H2K9Q1`, `Cheque 4012345 · City Bank`.
String receiptMethod(AppLocalizations l10n, Collection collection) {
  final parts = [
    l10n.method(collection.method),
    ?collection.chequeNumber,
    ?collection.reference,
    ?collection.bankName,
  ];
  return parts.join(' · ');
}

/// `INV-2026-0912 · 2nd instalment`, or the order for an advance.
String allocationLabel(
  AppLocalizations l10n,
  AppFormat fmt,
  Allocation allocation,
) =>
    '${allocation.invoiceNumber ?? allocation.orderNumber} · '
    '${l10n.salesInstalmentOf(l10n.ordinal(allocation.seq))} · '
    '${fmt.money(allocation.amount)}';
