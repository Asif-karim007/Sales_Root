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
import 'package:salesroot/features/contacts/view/widget/contacts_sheets.dart';
import 'package:salesroot/features/contacts/view/widget/document_upload_sheet.dart';
import 'package:salesroot/features/contacts/view/widget/paged_scroll_view.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

const _filters = [
  null,
  DocumentCategory.quotation,
  DocumentCategory.invoice,
  DocumentCategory.receipt,
  DocumentCategory.agreement,
  DocumentCategory.photo,
];

String documentCategoryLabel(AppLocalizations l10n, DocumentCategory? kind) =>
    switch (kind) {
      null => l10n.commonAll,
      DocumentCategory.quotation => l10n.contactsQuotes,
      DocumentCategory.invoice => l10n.contactsInvoices,
      DocumentCategory.receipt => l10n.contactsReceipts,
      DocumentCategory.agreement => l10n.contactsAgreements,
      DocumentCategory.photo => l10n.contactsPhotos,
      DocumentCategory.other => l10n.contactsOtherDocuments,
    };

/// #49: a customer's quotations, invoices, receipts, agreements and photos,
/// with upload and preview.
class CustomerDocumentsScreen extends ConsumerStatefulWidget {
  const CustomerDocumentsScreen({super.key, required this.companyId});

  final int companyId;

  @override
  ConsumerState<CustomerDocumentsScreen> createState() =>
      _CustomerDocumentsScreenState();
}

class _CustomerDocumentsScreenState
    extends ConsumerState<CustomerDocumentsScreen> {
  int _filter = 0;

  Future<void> _upload() async {
    final upload = await showDocumentUploadSheet(context);
    if (upload == null) return;
    await ref
        .read(documentMutationProvider(widget.companyId).notifier)
        .upload(upload);
  }

  Future<void> _delete(CustomerDocument document) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.contactsDeleteDocumentTitle,
      message: l10n.contactsDeleteDocumentBody(document.title),
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed) return;
    await ref
        .read(documentMutationProvider(widget.companyId).notifier)
        .delete(document.id);
  }

  void _open(CustomerDocument document) {
    final repository = ref.read(customerRepositoryProvider);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => SrFileViewer(
          name: document.fileName,
          kind: srFileKindOf(document.fileName),
          title: document.title,
          load: () => repository.download(document.id),
        ),
      ),
    );
  }

  void _menu(CustomerDocument document, bool canEdit) {
    final l10n = context.l10n;
    showActionSheet(
      context,
      title: document.title,
      actions: [
        SheetAction(
          icon: Icons.visibility_outlined,
          label: l10n.contactsOpen,
          onTap: () => _open(document),
        ),
        if (canEdit && document.canDelete)
          SheetAction(
            icon: Icons.delete_outline_rounded,
            label: l10n.commonDelete,
            destructive: true,
            onTap: () => _delete(document),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final documents = ref.watch(customerDocumentsProvider(widget.companyId));
    final company = ref.watch(companyProvider(widget.companyId)).value;
    final canEdit = ref.watch(moduleAccessProvider(AppModule.company)).canEdit;
    final uploading = ref
        .watch(documentMutationProvider(widget.companyId))
        .isLoading;

    ref.listen(documentMutationProvider(widget.companyId), (_, next) {
      switch (next) {
        case AsyncData(value: DocumentChange.uploaded):
          showSrSuccess(context, l10n.contactsUploaded);
        case AsyncData(value: DocumentChange.deleted):
          showSrSuccess(context, l10n.contactsDocumentDeleted);
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
          onFilter: (index) => setState(() => _filter = index),
          onOpen: _open,
          onMenu: (document) => _menu(document, canEdit),
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
    required this.onMenu,
    required this.onUpload,
  });

  final List<CustomerDocument> all;
  final int filter;
  final ValueChanged<int> onFilter;
  final ValueChanged<CustomerDocument> onOpen;
  final ValueChanged<CustomerDocument> onMenu;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = _filters[filter];
    final shown = kind == null
        ? all
        : all.where((d) => d.category == kind).toList();

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
                for (final option in _filters)
                  SrChipItem(
                    documentCategoryLabel(l10n, option),
                    count: option == null
                        ? all.length
                        : all.where((d) => d.category == option).length,
                  ),
              ],
              index: filter,
              onChanged: onFilter,
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
                  onMenu: () => onMenu(shown[index]),
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
    required this.onMenu,
  });

  final CustomerDocument document;
  final bool divider;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final amount = document.amount;
    final size = document.sizeInKb;
    final by = document.uploadedBy;
    final kind = srFileKindOf(document.fileName);
    final (icon, tone) = switch (document.category) {
      DocumentCategory.quotation => (
        Icons.request_quote_outlined,
        SrAvatarTone.accent,
      ),
      DocumentCategory.invoice => (
        Icons.receipt_long_outlined,
        SrAvatarTone.neutral,
      ),
      DocumentCategory.receipt => (Icons.payments_outlined, SrAvatarTone.gold),
      DocumentCategory.agreement => (
        Icons.handshake_outlined,
        SrAvatarTone.neutral,
      ),
      DocumentCategory.photo => (Icons.photo_outlined, SrAvatarTone.neutral),
      DocumentCategory.other => (
        Icons.description_outlined,
        SrAvatarTone.neutral,
      ),
    };
    final title = [
      _title(l10n, document),
      if (amount != null) fmt.moneyCompact(amount),
    ].join(' · ');
    final meta = [
      switch (kind) {
        SrFileKind.pdf => l10n.contactsPdf,
        SrFileKind.image => l10n.contactsImage,
        SrFileKind.other => l10n.contactsFile,
      },
      if (document.source == 'Sms') l10n.contactsSentBySms,
      if (document.source == 'Visit') l10n.contactsVisit,
      fmt.dayMonth(document.uploadedOn),
      if (size != null && amount == null) _size(l10n, fmt, size),
      if (by != null) l10n.contactsUploadedBy(by),
      if (document.viewed) l10n.contactsViewed,
    ];

    return SrListRow(
      title: title,
      subtitle: meta.join(' · '),
      leading: SrAvatar(icon: icon, tone: tone),
      divider: divider,
      onTap: onOpen,
      trailing: SrIconButton(
        icon: Icons.more_horiz_rounded,
        compact: true,
        tooltip: l10n.commonMore,
        onTap: onMenu,
      ),
    );
  }

  String _title(AppLocalizations l10n, CustomerDocument document) =>
      switch (document.category) {
        DocumentCategory.quotation => l10n.contactsQuotationNumber(
          document.title,
        ),
        DocumentCategory.invoice => l10n.contactsInvoiceNumber(document.title),
        DocumentCategory.receipt => l10n.contactsReceiptNumber(document.title),
        _ => document.title,
      };

  String _size(AppLocalizations l10n, AppFormat fmt, int kb) => kb >= 1024
      ? l10n.contactsSizeMb(fmt.number(kb / 1024, decimals: 1))
      : l10n.contactsSizeKb(fmt.number(kb));
}
