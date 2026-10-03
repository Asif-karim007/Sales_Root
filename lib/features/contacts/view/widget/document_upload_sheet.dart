import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/contacts/models/customer.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Picks a file, a camera photo or a gallery photo, then asks for a title
/// and category. Null when the user backs out.
Future<DocumentUpload?> showDocumentUploadSheet(BuildContext context) =>
    showSrSheet<DocumentUpload>(
      context: context,
      builder: (_) => const _UploadSheet(),
    );

class _Picked {
  const _Picked(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

class _UploadSheet extends StatefulWidget {
  const _UploadSheet();

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _title = TextEditingController();
  _Picked? _picked;
  DocumentCategory _category = DocumentCategory.other;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick(Future<_Picked?> Function() source) async {
    setState(() => _busy = true);
    final message = context.l10n.contactsPickFailed;
    try {
      final picked = await source();
      if (!mounted || picked == null) return;
      final dot = picked.name.lastIndexOf('.');
      final image = srFileKindOf(picked.name) == SrFileKind.image;
      setState(() {
        _picked = picked;
        _category = image ? DocumentCategory.photo : DocumentCategory.other;
        _title.text = dot > 0 ? picked.name.substring(0, dot) : picked.name;
      });
    } on Exception {
      if (mounted) showSrError(context, message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static Future<_Picked?> _file() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    return _Picked(file.name, await file.readAsBytes());
  }

  static Future<_Picked?> _photo(ImageSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 2000,
    );
    if (photo == null) return null;
    return _Picked(photo.name, await photo.readAsBytes());
  }

  void _submit() {
    final picked = _picked;
    if (picked == null) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = context.l10n.contactsTitleRequired);
      return;
    }
    Navigator.of(context).pop(
      DocumentUpload(
        fileName: picked.name,
        bytes: picked.bytes,
        title: _title.text,
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final picked = _picked;
    return SrSheet(
      title: l10n.contactsUploadTitle,
      child: SingleChildScrollView(
        child: picked == null ? _sources(l10n) : _details(l10n, picked),
      ),
    );
  }

  Widget _sources(AppLocalizations l10n) {
    final enabled = !_busy;
    return SrRowGroup(
      dividerIndent: 64,
      rows: [
        SrListRow(
          title: l10n.contactsPickFile,
          subtitle: l10n.contactsPickFileHint,
          leading: const SrAvatar(
            icon: Icons.attach_file_rounded,
            tone: SrAvatarTone.accent,
          ),
          onTap: enabled ? () => _pick(_file) : null,
        ),
        SrListRow(
          title: l10n.contactsTakePhoto,
          leading: const SrAvatar(icon: Icons.photo_camera_outlined),
          onTap: enabled ? () => _pick(() => _photo(ImageSource.camera)) : null,
        ),
        SrListRow(
          title: l10n.contactsFromGallery,
          leading: const SrAvatar(icon: Icons.photo_library_outlined),
          onTap: enabled
              ? () => _pick(() => _photo(ImageSource.gallery))
              : null,
        ),
      ],
    );
  }

  Widget _details(AppLocalizations l10n, _Picked picked) {
    final c = SrColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 14,
      children: [
        Text(picked.name, style: AppText.meta(c.ink2)),
        SrTextField(
          controller: _title,
          label: l10n.contactsDocumentTitle,
          error: _error,
          textCapitalization: TextCapitalization.sentences,
        ),
        SrFieldLabel(l10n.contactsDocumentCategory),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final category in DocumentCategory.values)
              SrChip(
                label: _label(l10n, category),
                selected: category == _category,
                onTap: () => setState(() => _category = category),
              ),
          ],
        ),
        SrButton(
          label: l10n.contactsUpload,
          icon: Icons.cloud_upload_outlined,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }

  String _label(AppLocalizations l10n, DocumentCategory category) =>
      switch (category) {
        DocumentCategory.quotation => l10n.contactsQuotation,
        DocumentCategory.invoice => l10n.contactsInvoice,
        DocumentCategory.receipt => l10n.contactsReceipt,
        DocumentCategory.agreement => l10n.contactsAgreement,
        DocumentCategory.photo => l10n.contactsPhoto,
        DocumentCategory.other => l10n.contactsOtherDocument,
      };
}
