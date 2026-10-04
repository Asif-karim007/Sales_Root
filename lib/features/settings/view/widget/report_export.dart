import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/settings/models/report_models.dart';
import 'package:salesroot/translations/translations.dart';

String productCategoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'Solar' => l10n.settingsCategorySolar,
      'Inverters' => l10n.settingsCategoryInverters,
      'Batteries' => l10n.settingsCategoryBatteries,
      'Accessories' => l10n.settingsCategoryAccessories,
      'Lighting' => l10n.settingsCategoryLighting,
      'Pumps' => l10n.settingsCategoryPumps,
      'Services' => l10n.settingsCategoryServices,
      _ => category,
    };

/// RFC 4180 text: cells holding a comma, quote or line break are quoted.
String toCsv(List<List<Object?>> rows) => rows
    .map((row) => row.map((cell) => _cell('${cell ?? ''}')).join(','))
    .join('\r\n');

String _cell(String value) => value.contains(RegExp('[",\r\n]'))
    ? '"${value.replaceAll('"', '""')}"'
    : value;

String _day(DateTime d) => ReportQuery.dayString(d);

/// The sales report as spreadsheet rows; amounts stay plain numbers.
List<List<Object?>> salesReportRows(
  AppLocalizations l10n,
  ReportQuery query,
  SalesReport report,
  bool bangla,
) => [
  [l10n.settingsReportSalesTitle, _day(query.from), _day(query.to)],
  [],
  [l10n.settingsReportSalesTotal, report.total],
  [l10n.settingsReportPrevious, report.previousTotal],
  [l10n.settingsReportTarget, report.target],
  [],
  [l10n.settingsReportMonth, l10n.settingsReportValue],
  for (final m in report.months) [_day(m.month), m.value],
  [],
  [
    l10n.settingsReportMember,
    l10n.settingsReportLeads,
    l10n.settingsReportWon,
    l10n.settingsReportWonValue,
    l10n.settingsReportOpenValue,
  ],
  for (final m in report.members)
    [m.name.of(bangla), m.leads, m.won, m.wonValue, m.openValue],
  [],
  [l10n.settingsReportCategory, l10n.settingsReportValue],
  for (final c in report.categories)
    [productCategoryLabel(l10n, c.category), c.value],
];

List<List<Object?>> overviewRows(
  AppLocalizations l10n,
  ReportQuery query,
  ReportOverview overview,
) => [
  [l10n.settingsReportsTitle, _day(query.from), _day(query.to)],
  [],
  [l10n.settingsReportWon, overview.won],
  [l10n.settingsReportLost, overview.lost],
  [l10n.settingsReportOpen, overview.open],
  [l10n.settingsReportWinRate, (overview.winRate * 100).round()],
  [],
  [l10n.settingsReportWeek, l10n.settingsReportNewLeads],
  for (var i = 0; i < overview.weeklyNewLeads.length; i++)
    [i + 1, overview.weeklyNewLeads[i]],
  [],
  [l10n.settingsReportSource, l10n.settingsReportLeads, l10n.settingsReportWon],
  for (final s in overview.sources) [s.source, s.leads, s.won],
];

/// Saves [bytes] as [name] in the temp folder and opens the share sheet.
Future<void> shareFile(String name, List<int> bytes, String mimeType) async {
  final folder = await getTemporaryDirectory();
  final file = File('${folder.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: mimeType)]),
  );
}

/// CSV bytes with a BOM, so spreadsheet apps read Bangla correctly.
List<int> csvBytes(List<List<Object?>> rows) => [
  0xEF,
  0xBB,
  0xBF,
  ...utf8.encode(toCsv(rows)),
];

/// The sales report as a one-page PDF. It is always in English: the PDF
/// engine can't shape Bangla conjuncts.
Future<Uint8List> salesReportPdf(ReportQuery query, SalesReport report) async {
  final l10n = lookupAppLocalizations(english);
  final fmt = AppFormat(l10n, english);
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/AnekBangla-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/AnekBangla-SemiBold.ttf'),
  );
  final accent = PdfColor.fromInt(SrColors.light.accent.toARGB32());
  final period = query.isMonth
      ? fmt.monthYear(query.from)
      : '${fmt.date(query.from)} – ${fmt.date(query.to)}';
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  pw.Widget table(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(color: PdfColors.white, font: bold),
        headerDecoration: pw.BoxDecoration(color: accent),
        cellAlignment: pw.Alignment.centerLeft,
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfColors.grey300),
        ),
      );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text(
          l10n.settingsReportSalesTitle,
          style: pw.TextStyle(fontSize: 22, font: bold, color: accent),
        ),
        pw.Text(period),
        pw.SizedBox(height: 16),
        table(
          [
            l10n.settingsReportSalesTotal,
            l10n.settingsReportPrevious,
            l10n.settingsReportTarget,
          ],
          [
            [
              fmt.money(report.total),
              fmt.money(report.previousTotal),
              fmt.money(report.target),
            ],
          ],
        ),
        pw.SizedBox(height: 16),
        table(
          [
            l10n.settingsReportMember,
            l10n.settingsReportLeads,
            l10n.settingsReportWon,
            l10n.settingsReportWonValue,
          ],
          [
            for (final m in report.members)
              [
                m.name.en,
                fmt.number(m.leads),
                fmt.number(m.won),
                fmt.money(m.wonValue),
              ],
          ],
        ),
        pw.SizedBox(height: 16),
        table(
          [l10n.settingsReportCategory, l10n.settingsReportValue],
          [
            for (final c in report.categories)
              [productCategoryLabel(l10n, c.category), fmt.money(c.value)],
          ],
        ),
        pw.SizedBox(height: 16),
        table(
          [l10n.settingsReportMonth, l10n.settingsReportValue],
          [
            for (final m in report.months)
              [fmt.monthYear(m.month), fmt.money(m.value)],
          ],
        ),
      ],
    ),
  );
  return doc.save();
}
