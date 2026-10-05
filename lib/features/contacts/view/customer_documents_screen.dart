import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/contacts/models/customer.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/features/contacts/providers/customer_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_feedback.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/document_upload_sheet.dart';
import 'package:salesroot/features/contacts/view/widget/paged_scroll_view.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

enum _Filter { all, photos, files }

String _filterLabel(AppLocalizations l10n, _Filter filter) => switch (filter) {
  _Filter.all => l10n.commonAll,
  _Filter.photos => l10n.contactsPhotos,
  _Filter.files => l10n.contactsOtherDocuments,
};

bool _matches(_Filter filter, CustomerDocument document) => switch (filter) {
  _Filter.all => true,
  _Filter.photos => document.isPhoto,
  _Filter.files => !document.isPhoto,
};

/// #49: the files kept on a customer, with upload and preview.
class CustomerDocumentsScreen extends ConsumerStatefulWidget {
  const CustomerDocumentsScreen({super.key, required this.companyId});

  final String companyId;

  @override
  ConsumerState<CustomerDocumentsScreen> createState() =>
      _CustomerDocumentsScreenState();
}

class _CustomerDocumentsScreenState
    extends ConsumerState<CustomerDocumentsScreen> {
  _Filter _filter = _Filter.all;

  Future<void> _upload() async {
    final upload = await showDocumentUploadSheet(context);
    if (upload == null) return;
    await ref
        .read(documentUploadProvider(widget.companyId).notifier)
        .upload(upload);
  }

  void _open(CustomerDocument document) {
    final repository = ref.read(customerRepositoryProvider);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => SrFileViewer(
          name: document.fileName,
          kind: srFileKindOf(document.fileName),
          title: document.fileName,
          load: () => repository.download(document),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final documents = ref.watch(customerDocumentsProvider(widget.companyId));
    final company = ref.watch(companyProvider(widget.companyId)).value;
    final canEdit = ref.watch(moduleAccessProvider(AppModule.company)).canEdit;
    final uploading = ref
        .watch(documentUploadProvider(widget.companyId))
        .isLoading;

    ref.listen(documentUploadProvider(widget.companyId), (_, next) {
      switch (next) {
        case AsyncData(value: true):
          showSrSuccess(context, l10n.contactsUploaded);
        case AsyncError(:final error):
          showFailure(context, error, quota: QuotaKind.storage);
        default:
      }
    });

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.contactsDocuments,
        subtitle: company?.name,
        actions: [
          const ContactsLanguageToggle(),
          if (canEdit)
            SrIconButton(
              icon: uploading ? Icons.hourglass_top_rounded : Icons.add_rounded,
              tooltip: l10n.contactsUpload,
              onTap: uploading ? null : _upload,
            ),
        ],
      ),
      body: SrAsyncView<List<CustomerDocument>>(
        value: documents,
        onRetry: () =>
            ref.invalidate(customerDocumentsProvider(widget.companyId)),
        onUpgrade: () => context.push(upgradeRoute(QuotaKind.storage)),
        data: (context, all) => _List(
          all: all,
          filter: _filter,
          onFilter: (filter) => setState(() => _filter = filter),
          onOpen: _open,
          onUpload: canEdit ? _upload : null,
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.all,
    required this.filter,
    required this.onFilter,
    required this.onOpen,
    required this.onUpload,
  });

  final List<CustomerDocument> all;
  final _Filter filter;
  final ValueChanged<_Filter> onFilter;
  final ValueChanged<CustomerDocument> onOpen;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = all.where((d) => _matches(filter, d)).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            16,
            SrMetrics.gutter,
            12,
          ),
          sliver: SliverToBoxAdapter(
            child: SrChipRow(
              padding: EdgeInsets.zero,
              chips: [
                for (final option in _Filter.values)
                  SrChipItem(
                    _filterLabel(l10n, option),
                    count: all.where((d) => _matches(option, d)).length,
                  ),
              ],
              index: filter.index,
              onChanged: (index) => onFilter(_Filter.values[index]),
            ),
          ),
        ),
        if (shown.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: SrEmptyState(
                icon: Icons.folder_open_outlined,
                title: l10n.contactsNoDocumentsTitle,
                message: l10n.contactsNoDocumentsBody,
                actionLabel: onUpload == null ? null : l10n.contactsUpload,
                onAction: onUpload,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              0,
              SrMetrics.gutter,
              24,
            ),
            sliver: SliverList.builder(
              itemCount: shown.length,
              itemBuilder: (context, index) => CardSegment(
                first: index == 0,
                last: index == shown.length - 1,
                child: _DocumentRow(
                  document: shown[index],
                  divider: index < shown.length - 1,
                  onOpen: () => onOpen(shown[index]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.divider,
    required this.onOpen,
  });

  final CustomerDocument document;
  final bool divider;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final size = document.sizeInBytes;
    final meta = [
      switch (srFileKindOf(document.fileName)) {
        SrFileKind.pdf => l10n.contactsPdf,
        SrFileKind.image => l10n.contactsImage,
        SrFileKind.other => l10n.contactsFile,
      },
      fmt.dayMonth(document.uploadedOn),
      if (size != null) _size(l10n, fmt, size),
    ];

    return SrListRow(
      title: document.fileName,
      subtitle: meta.join(' · '),
      leading: SrAvatar(
        icon: document.isPhoto
            ? Icons.photo_outlined
            : Icons.description_outlined,
      ),
      divider: divider,
      chevron: true,
      onTap: onOpen,
    );
  }

  String _size(AppLocalizations l10n, AppFormat fmt, int bytes) {
    final kb = (bytes / 1024).ceil();
    return kb >= 1024
        ? l10n.contactsSizeMb(fmt.number(kb / 1024, decimals: 1))
        : l10n.contactsSizeKb(fmt.number(kb));
  }
}
