import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/pdf/sales_pdf.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/sales_links.dart';
import 'package:salesroot/features/sales/view/widget/button_row.dart';
import 'package:salesroot/features/sales/view/widget/pdf_sheet.dart';
import 'package:salesroot/features/sales/view/widget/quotation_doc_card.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/features/sales/view/widget/sales_rows.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #56: the quotation as sent, its PDF, and what to do next: send, revise,
/// duplicate, mark accepted (which makes the order) or rejected.
class QuotationScreen extends ConsumerWidget {
  const QuotationScreen({super.key, required this.id});

  final int id;

  Future<void> _pdf(BuildContext context, WidgetRef ref, Quotation q) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final seller = await ref.read(sellerProfileProvider.future);
    if (!context.mounted) return;
    await showSalesPdfSheet(
      context,
      title: q.number,
      fileName: '${q.number}.pdf',
      shareText: l10n.salesQuotationShareText(
        q.number,
        fmt.money(q.totals.total),
      ),
      build: (format) =>
          SalesPdf(l10n, fmt).quotation(q, seller, format: format),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref, Quotation q) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final channel = await showSrSheet<SendChannel>(
      context: context,
      builder: (_) => SrOptionSheet<SendChannel>(
        title: l10n.salesHowToSend,
        options: SendChannel.values,
        labelOf: l10n.channel,
        isSelected: (c) => c == q.sentVia,
      ),
    );
    if (channel == null || !context.mounted) return;
    try {
      final seller = await ref.read(sellerProfileProvider.future);
      final bytes = await SalesPdf(l10n, fmt).quotation(q, seller);
      await shareSalesPdf(
        bytes: bytes,
        fileName: '${q.number}.pdf',
        text: l10n.salesQuotationShareText(q.number, fmt.money(q.totals.total)),
        subject: l10n.salesQuotationNumber(q.number),
      );
    } on Exception {
      if (context.mounted) showSrError(context, l10n.salesPdfFailed);
      return;
    }
    await ref.read(quotationActionsProvider(id).notifier).send(channel);
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final makeOrder = ref.read(moduleAccessProvider(AppModule.order)).canAdd;
    final ok = await showSrConfirm(
      context,
      title: l10n.salesAcceptTitle,
      message: makeOrder ? l10n.salesAcceptBody : l10n.salesAcceptOnlyBody,
      confirmLabel: makeOrder
          ? l10n.salesConvertToOrder
          : l10n.salesMarkAccepted,
      icon: Icons.handshake_outlined,
    );
    if (!ok) return;
    final actions = ref.read(quotationActionsProvider(id).notifier);
    await (makeOrder ? actions.convertToOrder() : actions.markAccepted());
  }

  Future<void> _more(BuildContext context, WidgetRef ref, Quotation q) async {
    final l10n = context.l10n;
    final access = ref.read(moduleAccessProvider(AppModule.quotation));
    final actions = ref.read(quotationActionsProvider(id).notifier);
    final options = <(String, IconData, Future<void> Function())>[
      (
        l10n.salesPreviewPdf,
        Icons.picture_as_pdf_outlined,
        () => _pdf(context, ref, q),
      ),
      if (access.canAdd)
        (
          l10n.salesDuplicate,
          Icons.copy_all_outlined,
          () async => context.push(quotationNewFor(fromId: q.id)),
        ),
      if (access.canEdit && q.status.isAwaiting)
        (
          l10n.salesSendAgain,
          Icons.send_outlined,
          () => _send(context, ref, q),
        ),
      if (access.canEdit && q.status.isOpen && q.canEdit)
        (l10n.salesMarkRejected, Icons.block_rounded, actions.markRejected),
      if (access.canDelete && q.canDelete)
        (
          l10n.salesDeleteDraft,
          Icons.delete_outline_rounded,
          () => _delete(context, ref),
        ),
    ];
    final picked = await showSrSheet<int>(
      context: context,
      builder: (_) => SrSheet(
        title: q.number,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < options.length; i++)
              SrListRow(
                leading: SrAvatar(
                  icon: options[i].$2,
                  tone: SrAvatarTone.accent,
                ),
                title: options[i].$1,
                onTap: () => Navigator.of(context).pop(i),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await options[picked].$3();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showSrConfirm(
      context,
      title: l10n.salesDeleteDraft,
      message: l10n.salesDeleteDraftBody,
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (ok) await ref.read(quotationActionsProvider(id).notifier).delete();
  }

  void _outcome(BuildContext context, AsyncValue<QuotationOutcome?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(value: QuotationConverted(:final order)):
        showSrSuccess(context, l10n.salesOrderCreated(order.number));
        context.pushReplacement(Routes.orderFor(order.id));
      case AsyncData(value: QuotationUpdated(:final quotation)):
        showSrSuccess(
          context,
          l10n.salesQuotationNowStatus(l10n.quotationStatus(quotation.status)),
        );
      case AsyncData(value: QuotationDeleted()):
        showSrSuccess(context, l10n.salesDraftDeleted);
        context.pop();
      case AsyncError(:final error):
        showSalesFailure(context, error);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final value = ref.watch(quotationProvider(id));
    final quotation = value.value;
    ref.listen(
      quotationActionsProvider(id),
      (_, next) => _outcome(context, next),
    );
    final buttons = quotation == null
        ? const <Widget>[]
        : _footerButtons(
            context,
            ref,
            quotation,
            onSend: () => _send(context, ref, quotation),
            onAccept: () => _accept(context, ref),
          );
    return SrScaffold(
      appBar: SrAppBar(
        title: quotation?.number ?? l10n.salesQuotation,
        subtitle: quotation == null
            ? null
            : '${quotation.companyName} · ${l10n.salesVersion(fmt.number(quotation.version))}',
        actions: [
          if (quotation != null) ...[
            SrIconButton(
              icon: Icons.picture_as_pdf_outlined,
              tooltip: l10n.salesPreviewPdf,
              onTap: () => _pdf(context, ref, quotation),
            ),
            SrIconButton(
              icon: Icons.more_vert_rounded,
              tooltip: l10n.commonMore,
              onTap: () => _more(context, ref, quotation),
            ),
          ],
        ],
      ),
      body: SrAsyncView<Quotation>(
        value: value,
        onRetry: () => ref.invalidate(quotationProvider(id)),
        onUpgrade: upgradeFor(context, value.error),
        loading: (_) => const SrSkeletonList(count: 1, cards: true),
        data: (context, q) => _QuotationBody(quotation: q),
      ),
      footer: buttons.isEmpty ? null : ButtonRow(buttons: buttons),
    );
  }
}

class _QuotationBody extends ConsumerWidget {
  const _QuotationBody({required this.quotation});

  final Quotation quotation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final q = quotation;
    final seller = ref.watch(sellerProfileProvider).value;
    final viewed = q.lastViewedAt;
    final order = q.orderNumber;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(quotationProvider(q.id).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          SrMetrics.gutter,
          14,
          SrMetrics.gutter,
          32,
        ),
        children: [
          Row(
            children: [
              SrTag(
                l10n.quotationStatus(q.status),
                tone: quotationTone(q.status),
              ),
              const Spacer(),
              Text(
                l10n.salesByOwner(q.ownerName),
                style: AppText.meta(SrColors.of(context).ink2),
              ),
            ],
          ),
          const SizedBox(height: 10),
          QuotationDocCard(quotation: q, seller: seller),
          if (viewed != null) ...[
            const SizedBox(height: 12),
            SrNote(
              tone: SrNoteTone.gold,
              icon: Icons.visibility_outlined,
              message: l10n.salesViewedNote(
                fmt.number(q.viewCount),
                '${salesDay(context, viewed)} ${fmt.time(viewed)}',
              ),
            ),
          ],
          if (order != null) ...[
            const SizedBox(height: 12),
            SrNote(
              icon: Icons.inventory_2_outlined,
              message: l10n.salesOrderMade(order),
            ),
          ],
        ],
      ),
    );
  }
}

/// The footer actions the status and the user's rights allow.
List<Widget> _footerButtons(
  BuildContext context,
  WidgetRef ref,
  Quotation q, {
  required VoidCallback onSend,
  required VoidCallback onAccept,
}) {
  final l10n = context.l10n;
  final access = ref.watch(moduleAccessProvider(AppModule.quotation));
  final orders = ref.watch(moduleAccessProvider(AppModule.order));
  final busy = ref.watch(quotationActionsProvider(q.id)).isLoading;
  final orderId = q.orderId;
  if (orderId != null) {
    return [
      if (orders.canView)
        SrButton(
          label: l10n.salesOpenOrder,
          icon: Icons.inventory_2_outlined,
          onPressed: () => context.push(Routes.orderFor(orderId)),
        ),
    ];
  }
  if (q.status == QuotationStatus.accepted) {
    return [
      if (orders.canAdd)
        SrButton(
          label: l10n.salesConvertToOrder,
          loading: busy,
          onPressed: busy
              ? null
              : ref
                    .read(quotationActionsProvider(q.id).notifier)
                    .convertToOrder,
        ),
    ];
  }
  return [
    if (access.canEdit && q.canEdit)
      SrButton(
        label: q.status == QuotationStatus.draft
            ? l10n.commonEdit
            : l10n.salesNewVersion,
        icon: Icons.edit_note_rounded,
        variant: SrButtonVariant.secondary,
        onPressed: () =>
            context.push(quotationNewFor(fromId: q.id, revise: true)),
      ),
    if (access.canEdit && q.status == QuotationStatus.draft)
      SrButton(
        label: l10n.commonSend,
        icon: Icons.send_outlined,
        onPressed: onSend,
      )
    else if (access.canEdit && q.status.isAwaiting)
      SrButton(
        label: l10n.salesMarkAccepted,
        loading: busy,
        onPressed: busy ? null : onAccept,
      ),
  ];
}
