import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/invoice.dart';

/// The bundled Anek Bangla for Latin text and ৳.
abstract final class BillingPdfTheme {
  static Future<pw.ThemeData>? _theme;

  static Future<pw.ThemeData> load() => _theme ??= _build();

  static Future<pw.ThemeData> _build() async {
    final regular = await rootBundle.load(
      'assets/fonts/AnekBangla-Regular.ttf',
    );
    final bold = await rootBundle.load('assets/fonts/AnekBangla-SemiBold.ttf');
    return pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }

  static PdfColor pdf(Color color) => PdfColor.fromInt(color.toARGB32());
}

/// Writes one run of text into a PDF. The pdf package does not shape Bangla
/// (vowel signs land on the wrong letter), so a run with Bangla letters is
/// laid out by Flutter in Anek Bangla and embedded as an image.
abstract final class PdfText {
  static final RegExp _needsShaping = RegExp('[\u0981-\u09E3]');
  static const double _scale = 3;

  static Future<pw.Widget> of(
    String value, {
    double size = 11,
    bool bold = false,
    required Color color,
    double maxWidth = 515,
    bool center = false,
  }) async {
    if (!_needsShaping.hasMatch(value)) {
      return pw.Text(
        value,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: size,
          color: BillingPdfTheme.pdf(color),
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      );
    }
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: AppText.style(
          size: size * _scale,
          weight: bold ? FontWeight.w600 : FontWeight.w400,
          color: color,
        ),
      ),
      textAlign: center ? TextAlign.center : TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth * _scale);
    final width = painter.width.ceil();
    final height = painter.height.ceil();
    final recorder = ui.PictureRecorder();
    painter
      ..paint(Canvas(recorder), Offset.zero)
      ..dispose();
    final image = await recorder.endRecording().toImage(width, height);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (png == null) return pw.Text(value);
    return pw.Align(
      alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Image(
        pw.MemoryImage(png.buffer.asUint8List()),
        width: width / _scale,
        height: height / _scale,
      ),
    );
  }
}

/// Every string an invoice page prints, already in the user's language.
class InvoicePdfText {
  const InvoicePdfText({
    required this.brand,
    required this.title,
    required this.billedTo,
    required this.workspace,
    required this.date,
    required this.status,
    required this.method,
    required this.item,
    required this.amount,
    required this.credits,
    required this.vat,
    required this.total,
    required this.thanks,
  });

  final String brand;
  final String title;
  final String billedTo;
  final String workspace;
  final String Function(Invoice) date;
  final String Function(Invoice) status;
  final String Function(Invoice) method;
  final String item;
  final String amount;
  final String credits;
  final String Function(Invoice) vat;
  final String total;
  final String thanks;
}

/// One A4 page per invoice. [lineLabel] and [money] format as on screen.
Future<Uint8List> buildInvoicesPdf({
  required List<Invoice> invoices,
  required InvoicePdfText text,
  required String Function(OrderLine) lineLabel,
  required String Function(int) money,
  required SrColors colors,
}) async {
  final theme = await BillingPdfTheme.load();
  final doc = pw.Document(theme: theme, title: text.title);
  for (final invoice in invoices) {
    final page = await _invoicePage(invoice, text, lineLabel, money, colors);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => page,
      ),
    );
  }
  return doc.save();
}

Future<pw.Widget> _invoicePage(
  Invoice invoice,
  InvoicePdfText text,
  String Function(OrderLine) lineLabel,
  String Function(int) money,
  SrColors colors,
) async {
  final quote = invoice.quote;
  final muted = colors.ink2;
  final rows = [
    await _row(text.item, text.amount, colors, header: true),
    for (final line in quote.lines)
      await _row(lineLabel(line), money(line.amount), colors),
    if (quote.credits > 0)
      await _row(text.credits, money(-quote.credits), colors),
    await _row(text.vat(invoice), money(quote.vat), colors),
    await _row(text.total, money(quote.total), colors, total: true),
  ];
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: await PdfText.of(
              text.brand,
              size: 24,
              bold: true,
              color: colors.accent,
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              await PdfText.of(
                text.title,
                size: 16,
                bold: true,
                color: colors.ink,
              ),
              await PdfText.of(invoice.number, color: muted),
              await PdfText.of(text.date(invoice), color: muted),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 28),
      await PdfText.of(text.billedTo, size: 10, color: muted),
      await PdfText.of(text.workspace, size: 13, bold: true, color: colors.ink),
      pw.SizedBox(height: 4),
      await PdfText.of(text.method(invoice), color: muted),
      pw.SizedBox(height: 22),
      ...rows,
      pw.SizedBox(height: 18),
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(
            color: BillingPdfTheme.pdf(colors.tint),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: await PdfText.of(
            text.status(invoice),
            bold: true,
            color: colors.accent,
          ),
        ),
      ),
      pw.Spacer(),
      pw.Divider(color: BillingPdfTheme.pdf(colors.line)),
      await PdfText.of(text.thanks, size: 10, color: muted),
    ],
  );
}

Future<pw.Widget> _row(
  String label,
  String value,
  SrColors colors, {
  bool header = false,
  bool total = false,
}) async {
  final size = total ? 14.0 : 11.5;
  final color = header ? colors.ink2 : colors.ink;
  final bold = header || total;
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 7),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(
          color: BillingPdfTheme.pdf(total ? colors.ink : colors.line),
        ),
      ),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: await PdfText.of(
            label,
            size: size,
            bold: bold,
            color: color,
            maxWidth: 380,
          ),
        ),
        await PdfText.of(value, size: size, bold: bold, color: color),
      ],
    ),
  );
}
