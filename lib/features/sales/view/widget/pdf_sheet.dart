import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

typedef PdfBuilder = Future<Uint8List> Function(PdfPageFormat format);

/// Hands the PDF to the share sheet (WhatsApp, email, Drive…) with [text]
/// as the message.
Future<void> shareSalesPdf({
  required Uint8List bytes,
  required String fileName,
  required String text,
  String? subject,
}) => SharePlus.instance.share(
  ShareParams(
    text: text,
    subject: subject,
    files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName)],
    fileNameOverrides: [fileName],
  ),
);

Future<void> printSalesPdf({required PdfBuilder build, required String name}) =>
    Printing.layoutPdf(onLayout: build, name: name);

/// The rendered PDF in a sheet, with share and print.
Future<void> showSalesPdfSheet(
  BuildContext context, {
  required String title,
  required String fileName,
  required String shareText,
  required PdfBuilder build,
}) => showSrSheet<void>(
  context: context,
  builder: (_) => _PdfSheet(
    title: title,
    fileName: fileName,
    shareText: shareText,
    build: build,
  ),
);

class _PdfSheet extends StatefulWidget {
  const _PdfSheet({
    required this.title,
    required this.fileName,
    required this.shareText,
    required this.build,
  });

  final String title;
  final String fileName;
  final String shareText;
  final PdfBuilder build;

  @override
  State<_PdfSheet> createState() => _PdfSheetState();
}

class _PdfSheetState extends State<_PdfSheet> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await widget.build(PdfPageFormat.a4);
      await shareSalesPdf(
        bytes: bytes,
        fileName: widget.fileName,
        text: widget.shareText,
        subject: widget.title,
      );
    } on Exception {
      if (mounted) showSrError(context, context.l10n.salesPdfFailed);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return SrSheet(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.58,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
              child: PdfPreview(
                build: widget.build,
                initialPageFormat: PdfPageFormat.a4,
                useActions: false,
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                padding: EdgeInsets.zero,
                previewPageMargin: const EdgeInsets.all(8),
                scrollViewDecoration: BoxDecoration(color: c.canvas),
                loadingWidget: const SrSkeletonList(count: 4),
                onError: (context, _) =>
                    Center(child: SrEmptyState(title: l10n.salesPdfFailed)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SrButton(
                  label: l10n.salesPrint,
                  icon: Icons.print_outlined,
                  variant: SrButtonVariant.secondary,
                  onPressed: () =>
                      printSalesPdf(build: widget.build, name: widget.fileName),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SrButton(
                  label: l10n.commonShare,
                  icon: Icons.ios_share_rounded,
                  loading: _sharing,
                  onPressed: _share,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
