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
import 'package:salesroot/features/sales/view/sales_links.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/features/sales/view/widget/button_row.dart';
import 'package:salesroot/features/sales/view/widget/pdf_sheet.dart';
import 'package:salesroot/features/sales/view/widget/quotation_doc_card.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #62: the money receipt, to share, keep as PDF or print.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.id});

  final int id;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(collectionProvider(id));
    final receipt = value.value;
    final canAdd = ref.watch(moduleAccessProvider(AppModule.collection)).canAdd;
    return SrScaffold(
      appBar: SrAppBar(title: l10n.salesReceipt),
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
          receipt.smsSent
              ? l10n.salesReceiptSmsSent(receipt.number)
              : l10n.salesReceiptNumber(receipt.number),
          style: AppText.meta(c.ink2, size: 13),
        ),
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
              value: allocationLabel(l10n, fmt, allocation),
            ),
          AmountLine(
            label: l10n.salesBalanceDue,
            value: fmt.money(r.balanceDue),
          ),
          AmountLine(
            label: l10n.salesReceivedBy,
            value: r.receivedByIn(bangla: fmt.isBangla),
          ),
        ],
      ),
    );
  }
}
