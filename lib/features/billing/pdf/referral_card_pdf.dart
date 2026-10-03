import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:salesroot/features/billing/pdf/billing_pdf.dart';

/// The shop-counter card (#187) as an A5 page: brand, QR of [link], the code
/// and how the reward works.
Future<Uint8List> buildReferralCardPdf({
  required String brand,
  required String code,
  required String link,
  required String body,
  required String tip,
}) async {
  final theme = await BillingPdfTheme.load();
  final muted = BillingPdfTheme.muted;
  final children = [
    await PdfText.of(
      brand,
      size: 22,
      bold: true,
      color: BillingPdfTheme.accent,
    ),
    pw.SizedBox(height: 20),
    pw.BarcodeWidget(
      barcode: pw.Barcode.qrCode(),
      data: link,
      width: 200,
      height: 200,
      drawText: false,
      color: BillingPdfTheme.pdf(BillingPdfTheme.ink),
    ),
    pw.SizedBox(height: 18),
    await PdfText.of(code, size: 28, bold: true),
    pw.SizedBox(height: 10),
    await PdfText.of(body, size: 13, maxWidth: 340, center: true),
    pw.SizedBox(height: 8),
    await PdfText.of(link, color: muted),
    pw.SizedBox(height: 24),
    await PdfText.of(tip, size: 10, color: muted, maxWidth: 340, center: true),
  ];
  final doc = pw.Document(theme: theme, title: code);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: children,
      ),
    ),
  );
  return doc.save();
}
