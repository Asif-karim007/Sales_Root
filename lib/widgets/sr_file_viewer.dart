import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/sr_button.dart';
import 'package:salesroot/widgets/sr_scaffold.dart';
import 'package:salesroot/widgets/sr_states.dart';

enum SrFileKind { image, pdf, other }

const Set<String> _imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'heif',
};

/// What a file name or path says about how the file can be shown.
SrFileKind srFileKindOf(String? nameOrPath) {
  final value = (nameOrPath ?? '').split('?').first;
  final dot = value.lastIndexOf('.');
  final extension = dot < 0 ? '' : value.substring(dot + 1).toLowerCase();
  if (extension == 'pdf') return SrFileKind.pdf;
  if (_imageExtensions.contains(extension)) return SrFileKind.image;
  return SrFileKind.other;
}

/// A file full screen: a photo zooms, a PDF scrolls page by page, anything
/// else can be shared or opened in the browser.
class SrFileViewer extends StatefulWidget {
  const SrFileViewer({
    super.key,
    required this.name,
    required this.kind,
    required this.load,
    this.title,
    this.meta = '',
    this.webUrl,
  });

  final String name;
  final SrFileKind kind;
  final Future<Uint8List> Function() load;
  final String? title;
  final String meta;
  final String? webUrl;

  @override
  State<SrFileViewer> createState() => _SrFileViewerState();
}

class _SrFileViewerState extends State<SrFileViewer> {
  late Future<Uint8List> _bytes = widget.load();

  String get _fileName => switch (widget.name) {
    '' when widget.kind == SrFileKind.pdf => 'file.pdf',
    '' when widget.kind == SrFileKind.image => 'file.jpg',
    '' => 'file',
    final name => name,
  };

  String get _mimeType => switch (widget.kind) {
    SrFileKind.pdf => 'application/pdf',
    SrFileKind.image => 'image/*',
    SrFileKind.other => 'application/octet-stream',
  };

  void _retry() => setState(() => _bytes = widget.load());

  Future<void> _share(Uint8List bytes) => SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: _mimeType)],
      fileNameOverrides: [_fileName],
    ),
  );

  Future<void> _openInBrowser() async {
    final url = widget.webUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final subtitle = [
          widget.name,
          widget.meta,
        ].where((part) => part.isNotEmpty).join(' · ');

        return SrScaffold(
          appBar: SrAppBar(
            title: widget.title ?? l10n.dsFileTitle,
            subtitle: subtitle.isEmpty ? null : subtitle,
            actions: [
              if (data != null)
                SrIconButton(
                  icon: Icons.ios_share_rounded,
                  tooltip: l10n.commonShare,
                  onTap: () => _share(data),
                ),
            ],
          ),
          body: _body(snapshot),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<Uint8List> snapshot) {
    final data = snapshot.data;
    final browser = widget.webUrl == null ? null : _openInBrowser;
    final error = snapshot.error;
    final l10n = context.l10n;

    if (data != null) {
      return switch (widget.kind) {
        SrFileKind.image => _Photo(bytes: data),
        SrFileKind.pdf => _Pdf(bytes: data),
        SrFileKind.other => _Notice(
          onBrowser: browser,
          card: SrEmptyState(
            title: l10n.dsFileNoPreview,
            message: l10n.dsFileNoPreviewBody,
            icon: Icons.insert_drive_file_outlined,
            actionLabel: l10n.commonShare,
            onAction: () => _share(data),
          ),
        ),
      };
    }
    if (error != null) {
      return _Notice(
        onBrowser: browser,
        card: SrErrorState(error: error, onRetry: _retry),
      );
    }
    return const _Loading();
  }
}

/// A state card with an optional way out to the browser under it.
class _Notice extends StatelessWidget {
  const _Notice({required this.card, this.onBrowser});

  final Widget card;
  final VoidCallback? onBrowser;

  @override
  Widget build(BuildContext context) {
    final onBrowser = this.onBrowser;
    return ListView(
      padding: const EdgeInsets.all(SrMetrics.gutter),
      children: [
        card,
        if (onBrowser != null) ...[
          const SizedBox(height: 12),
          SrButton(
            label: context.l10n.dsFileOpenBrowser,
            icon: Icons.open_in_browser_rounded,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: onBrowser,
          ),
        ],
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return InteractiveViewer(
      maxScale: 5,
      child: Center(
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              Icon(Icons.broken_image_outlined, size: 40, color: c.ink3),
        ),
      ),
    );
  }
}

class _Pdf extends StatelessWidget {
  const _Pdf({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return PdfPreview(
      build: (_) => bytes,
      useActions: false,
      allowPrinting: false,
      allowSharing: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      padding: const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
      previewPageMargin: const EdgeInsets.symmetric(vertical: 10),
      scrollViewDecoration: BoxDecoration(color: c.canvas),
      pdfPreviewPageDecoration: BoxDecoration(
        color: c.onDeep,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        boxShadow: c.cardShadow,
      ),
      loadingWidget: const _Loading(),
      onError: (_, _) => Center(
        child: Icon(Icons.broken_image_outlined, size: 40, color: c.ink3),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(
            SrColors.of(context).accent,
          ),
        ),
      ),
    );
  }
}
