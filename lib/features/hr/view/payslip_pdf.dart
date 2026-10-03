import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/models/payroll.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/l10n/l10n.dart';

/// Builds the payslip as an A4 PDF in Anek Bangla and opens the share sheet.
Future<void> sharePayslipPdf({
  required Payslip slip,
  required AppLocalizations l10n,
  required AppFormat fmt,
  required String workspace,
}) async {
  final bytes = await buildPayslipPdf(slip, l10n, fmt, workspace);
  final month = '${slip.year}-${slip.month.toString().padLeft(2, '0')}';
  await Printing.sharePdf(bytes: bytes, filename: 'payslip-$month.pdf');
}

/// The payslip as A4 PDF bytes.
Future<Uint8List> buildPayslipPdf(
  Payslip slip,
  AppLocalizations l10n,
  AppFormat fmt,
  String workspace,
) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/AnekBangla-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/AnekBangla-SemiBold.ttf'),
  );
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final palette = _Palette(SrColors.light);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(slip, l10n, fmt, workspace, palette),
          pw.SizedBox(height: 24),
          _section(l10n.hrPayslipEarnings, palette),
          for (final line in slip.earnings)
            _row(line.label(l10n, fmt), fmt.money(line.amount), palette),
          _row(
            l10n.hrPayslipTotal,
            fmt.money(slip.totalEarnings),
            palette,
            strong: true,
          ),
          pw.SizedBox(height: 16),
          _section(l10n.hrPayslipDeductions, palette),
          for (final line in slip.deductions)
            _row(line.label(l10n, fmt), '− ${fmt.money(line.amount)}', palette),
          _row(
            l10n.hrPayslipTotal,
            '− ${fmt.money(slip.totalDeductions)}',
            palette,
            strong: true,
          ),
          pw.SizedBox(height: 16),
          _row(
            l10n.hrPayslipNet,
            fmt.money(slip.netPay),
            palette,
            strong: true,
          ),
          pw.SizedBox(height: 16),
          _row(
            l10n.hrPayslipPresent,
            '${fmt.number(slip.presentDays)} / ${fmt.number(slip.workingDays)}',
            palette,
          ),
          _row(l10n.hrPayslipPaidVia, payoutText(slip, fmt), palette),
        ],
      ),
    ),
  );
  return doc.save();
}

/// "bKash 01811••••33 · 30 Sep"
String payoutText(Payslip slip, AppFormat fmt) {
  final paidOn = slip.paidOn;
  return [
    [slip.payoutMethod, slip.payoutAccount].whereType<String>().join(' '),
    if (paidOn != null) fmt.dayMonth(paidOn),
  ].where((part) => part.isNotEmpty).join(' · ');
}

class _Palette {
  _Palette(SrColors c)
    : ink = PdfColor.fromInt(c.ink.toARGB32()),
      muted = PdfColor.fromInt(c.ink2.toARGB32()),
      line = PdfColor.fromInt(c.line.toARGB32()),
      accent = PdfColor.fromInt(c.accent.toARGB32()),
      tint = PdfColor.fromInt(c.tint.toARGB32());

  final PdfColor ink;
  final PdfColor muted;
  final PdfColor line;
  final PdfColor accent;
  final PdfColor tint;
}

pw.Widget _header(
  Payslip slip,
  AppLocalizations l10n,
  AppFormat fmt,
  String workspace,
  _Palette palette,
) {
  final designation = slip.designation;
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: palette.tint,
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                workspace,
                style: pw.TextStyle(fontSize: 11, color: palette.muted),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${l10n.hrPayslipTitle} · ${fmt.monthYear(slip.period)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: palette.ink,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                [slip.employeeName.of(fmt.isBangla), ?designation].join(' · '),
                style: pw.TextStyle(fontSize: 11, color: palette.muted),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              l10n.hrPayslipNet,
              style: pw.TextStyle(fontSize: 10, color: palette.muted),
            ),
            pw.Text(
              fmt.money(slip.netPay),
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _section(String title, _Palette palette) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 4),
  child: pw.Text(
    title,
    style: pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: palette.ink,
    ),
  ),
);

pw.Widget _row(
  String label,
  String value,
  _Palette palette, {
  bool strong = false,
}) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(vertical: 6),
  decoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: palette.line, width: 0.5)),
  ),
  child: pw.Row(
    children: [
      pw.Expanded(
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11,
            color: strong ? palette.ink : palette.muted,
            fontWeight: strong ? pw.FontWeight.bold : null,
          ),
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 11,
          color: palette.ink,
          fontWeight: strong ? pw.FontWeight.bold : null,
        ),
      ),
    ],
  ),
);
