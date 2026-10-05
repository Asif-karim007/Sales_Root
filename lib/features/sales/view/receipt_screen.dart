import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/pdf/sales_pdf.dart';
import 'package:salesroot/features/sales/providers/collection_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/sales_links.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/features/sales/view/widget/button_row.dart';
import 'package:salesroot/features/sales/view/widget/pdf_sheet.dart';
import 'package:salesroot/features/sales/view/widget/quotation_doc_card.dart';
import 'package:salesroot/features/sales/view/widget/reason_sheet.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #62: the money receipt, to share, keep as PDF or print.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.id});

  final String id;

  Future<PdfBuilder> _builder(
    BuildContext context,
    WidgetRef ref,
    Collection r,
  ) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final seller = await ref.read(sellerProfileProvider.future);
    return (format) => SalesPdf(l10n, fmt).receipt(r, seller, format: format);
  }

  String _shareText(BuildContext context, Collection r) =>
      context.l10n.salesReceiptShareText(
        r.number,
        context.fmt.money(r.amount),
        r.companyName,
      );

  Future<void> _share(BuildContext context, WidgetRef ref, Collection r) async {
    final l10n = context.l10n;
    final text = _shareText(context, r);
    try {
      final build = await _builder(context, ref, r);
      final bytes = await build(PdfPageFormat.a4);
      await shareSalesPdf(
        bytes: bytes,
        fileName: '${r.number}.pdf',
        text: text,
        subject: r.number,
      );
    } on Exception {
      if (context.mounted) showSrError(context, l10n.salesPdfFailed);
    }
  }

  Future<void> _pdf(BuildContext context, WidgetRef ref, Collection r) async {
    final text = _shareText(context, r);
    final build = await _builder(context, ref, r);
    if (!context.mounted) return;
    await showSalesPdfSheet(
      context,
      title: r.number,
      fileName: '${r.number}.pdf',
      shareText: text,
      build: build,
    );
  }

  Future<void> _print(BuildContext context, WidgetRef ref, Collection r) async {
    final build = await _builder(context, ref, r);
    await printSalesPdf(build: build, name: r.number);
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final reason = await askCancelReason(
      context,
      title: l10n.salesCancelReceipt,
      message: l10n.salesCancelReceiptBody,
    );
    if (reason == null) return;
    await ref.read(receiptActionsProvider(id).notifier).cancel(reason);
  }

  void _outcome(BuildContext context, AsyncValue<Collection?> next) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(:final value?) when value.cancelled:
        showSrSuccess(context, l10n.salesReceiptCancelled);
      case AsyncData(value: Collection(:final chequeStatus?)):
        showSrSuccess(context, l10n.chequeStatus(chequeStatus));
      case AsyncError(:final error):
        showSalesFailure(context, error);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(collectionProvider(id));
    final receipt = value.value;
    final access = ref.watch(moduleAccessProvider(AppModule.collection));
    final canAdd = access.canAdd;
    ref.listen(
      receiptActionsProvider(id),
      (_, next) => _outcome(context, next),
    );
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.salesReceipt,
        actions: [
          if (receipt != null && !receipt.cancelled && access.canDelete)
            SrIconButton(
              icon: Icons.block_rounded,
              tooltip: l10n.salesCancelReceipt,
              onTap: () => _cancel(context, ref),
            ),
        ],
      ),
      body: SrAsyncView<Collection>(
        value: value,
        onRetry: () => ref.invalidate(collectionProvider(id)),
        onUpgrade: upgradeFor(context, value.error),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, r) => ListView(
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            18,
            SrMetrics.gutter,
            32,
          ),
          children: [
            _Recorded(receipt: r),
            const SizedBox(height: 16),
            _ReceiptCard(receipt: r),
            if (r.method == PaymentMethod.cheque) ...[
              const SizedBox(height: 14),
              _ChequeCard(receipt: r),
            ],
            const SizedBox(height: 14),
            ButtonRow(
              buttons: [
                SrButton(
                  label: l10n.salesChannelWhatsApp,
                  icon: Icons.chat_outlined,
                  size: SrButtonSize.sm,
                  variant: SrButtonVariant.secondary,
                  onPressed: () => _share(context, ref, r),
                ),
                SrButton(
                  label: l10n.salesPdf,
                  icon: Icons.picture_as_pdf_outlined,
                  size: SrButtonSize.sm,
                  variant: SrButtonVariant.secondary,
                  onPressed: () => _pdf(context, ref, r),
                ),
                SrButton(
                  label: l10n.salesPrint,
                  icon: Icons.print_outlined,
                  size: SrButtonSize.sm,
                  variant: SrButtonVariant.secondary,
                  onPressed: () => _print(context, ref, r),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: receipt == null
          ? null
          : ButtonRow(
              buttons: [
                SrButton(
                  label: l10n.salesBackToHome,
                  variant: SrButtonVariant.secondary,
                  onPressed: () => context.go(Routes.home),
                ),
                if (canAdd)
                  SrButton(
                    label: l10n.salesRecordAnother,
                    onPressed: () => context.pushReplacement(
                      collectionNewFor(customerId: receipt.companyId),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Recorded extends StatelessWidget {
  const _Recorded({required this.receipt});

  final Collection receipt;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, size: 34, color: c.accent),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.salesAmountRecorded(context.fmt.money(receipt.amount)),
          style: AppText.pageTitle(c.ink),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.salesReceiptNumber(receipt.number),
          style: AppText.meta(c.ink2, size: 13),
        ),
        if (receipt.cancelled) ...[
          const SizedBox(height: 6),
          SrTag(l10n.salesCancelled, tone: SrTone.err),
        ],
      ],
    );
  }
}

class _ReceiptCard extends ConsumerWidget {
  const _ReceiptCard({required this.receipt});

  final Collection receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final r = receipt;
    final balance = r.balanceDue;
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DocLetterhead(
            seller: ref.watch(sellerProfileProvider).value,
            title: l10n.salesMoneyReceipt,
            meta:
                '${r.number} · ${fmt.date(r.collectedAt)} · ${fmt.time(r.collectedAt)}',
          ),
          const SizedBox(height: 10),
          AmountLine(label: l10n.salesReceivedFrom, value: r.companyName),
          AmountLine(label: l10n.salesAmount, value: fmt.money(r.amount)),
          AmountLine(label: l10n.salesMethod, value: receiptMethod(l10n, r)),
          for (final allocation in r.allocations)
            AmountLine(
              label: l10n.salesAgainst,
              value: allocationLabel(fmt, allocation),
            ),
          if (r.advance > 0)
            AmountLine(label: l10n.salesAdvance, value: fmt.money(r.advance)),
          if (balance != null)
            AmountLine(label: l10n.salesBalanceDue, value: fmt.money(balance)),
          if (r.receivedByName.isNotEmpty)
            AmountLine(label: l10n.salesReceivedBy, value: r.receivedByName),
        ],
      ),
    );
  }
}

/// A cheque's state, and for whoever approves collections, marking it
/// cleared or bounced.
class _ChequeCard extends ConsumerWidget {
  const _ChequeCard({required this.receipt});

  final Collection receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final r = receipt;
    final status = r.chequeStatus ?? ChequeStatus.pending;
    final date = r.chequeDate;
    final actions = ref.read(receiptActionsProvider(r.id).notifier);
    final busy = ref.watch(receiptActionsProvider(r.id)).isLoading;
    final canDecide =
        status == ChequeStatus.pending &&
        !r.cancelled &&
        ref.watch(moduleAccessProvider(AppModule.collection)).canApprove;
    return SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  date == null
                      ? l10n.salesMethodCheque
                      : '${l10n.salesMethodCheque} · ${fmt.date(date)}',
                  style: AppText.rowTitle(SrColors.of(context).ink),
                ),
              ),
              SrTag(
                l10n.chequeStatus(status),
                tone: switch (status) {
                  ChequeStatus.pending => SrTone.gold,
                  ChequeStatus.cleared => SrTone.ok,
                  ChequeStatus.bounced => SrTone.err,
                },
              ),
            ],
          ),
          if (canDecide) ...[
            const SizedBox(height: 12),
            ButtonRow(
              buttons: [
                SrButton(
                  label: l10n.salesChequeBounced,
                  size: SrButtonSize.sm,
                  variant: SrButtonVariant.secondary,
                  onPressed: busy
                      ? null
                      : () => actions.setChequeStatus(ChequeStatus.bounced),
                ),
                SrButton(
                  label: l10n.salesChequeCleared,
                  size: SrButtonSize.sm,
                  loading: busy,
                  onPressed: busy
                      ? null
                      : () => actions.setChequeStatus(ChequeStatus.cleared),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
