import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/pdf/sales_pdf.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/sales_links.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/features/sales/view/widget/button_row.dart';
import 'package:salesroot/features/sales/view/widget/instalment_list.dart';
import 'package:salesroot/features/sales/view/widget/pdf_sheet.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #59: the bill, what is collected and due, sending it, and recording a
/// payment against it.
class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(invoiceProvider(id));
    final invoice = value.value;
    final seller = ref.watch(sellerProfileProvider).value;
    final collect = ref.watch(moduleAccessProvider(AppModule.collection));
    return SrScaffold(
      appBar: SrAppBar(
        title: _title(l10n, seller),
        actions: [
          if (invoice != null)
            SrIconButton(
              icon: Icons.picture_as_pdf_outlined,
              tooltip: l10n.salesPreviewPdf,
              onTap: () => _pdf(context, ref, invoice),
            ),
        ],
      ),
      body: SrAsyncView<Invoice>(
        value: value,
        onRetry: () => ref.invalidate(invoiceProvider(id)),
        onUpgrade: upgradeFor(context, value.error),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, invoice) => _InvoiceBody(
          invoice: invoice,
          seller: seller,
          onPdf: () => _pdf(context, ref, invoice),
          onShare: (text) => _share(context, ref, invoice, text),
        ),
      ),
      footer: invoice != null && collect.canAdd && invoice.due > 0
          ? SrButton(
              label: l10n.salesRecordCollection,
              icon: Icons.payments_outlined,
              expand: true,
              onPressed: () => context.push(
                collectionNewFor(
                  customerId: invoice.companyId,
                  invoiceId: invoice.id,
                ),
              ),
            )
          : null,
    );
  }

  static String _title(AppLocalizations l10n, SellerProfile? seller) =>
      seller?.taxInvoices ?? false ? l10n.salesTaxInvoice : l10n.salesBill;

  Future<void> _pdf(BuildContext context, WidgetRef ref, Invoice i) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final seller = await ref.read(sellerProfileProvider.future);
    if (!context.mounted) return;
    await showSalesPdfSheet(
      context,
      title: i.number,
      fileName: '${i.number}.pdf',
      shareText: l10n.salesBillShareText(i.number, fmt.money(i.due)),
      build: (format) => SalesPdf(l10n, fmt).invoice(i, seller, format: format),
    );
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    Invoice i,
    String text,
  ) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    try {
      final seller = await ref.read(sellerProfileProvider.future);
      final bytes = await SalesPdf(l10n, fmt).invoice(i, seller);
      await shareSalesPdf(
        bytes: bytes,
        fileName: '${i.number}.pdf',
        text: text,
        subject: i.number,
      );
    } on Exception {
      if (context.mounted) showSrError(context, l10n.salesPdfFailed);
    }
  }
}

class _InvoiceBody extends ConsumerWidget {
  const _InvoiceBody({
    required this.invoice,
    required this.seller,
    required this.onPdf,
    required this.onShare,
  });

  final Invoice invoice;
  final SellerProfile? seller;
  final VoidCallback onPdf;
  final ValueChanged<String> onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final i = invoice;
    final reminder = l10n.salesBillReminderText(
      i.companyName,
      i.number,
      fmt.money(i.due),
    );
    return RefreshIndicator(
      onRefresh: () => ref.refresh(invoiceProvider(i.id).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          SrMetrics.gutter,
          14,
          SrMetrics.gutter,
          32,
        ),
        children: [
          _InvoiceCard(invoice: i, taxInvoice: seller?.taxInvoices ?? false),
          if (!(seller?.taxInvoices ?? true)) ...[
            const SizedBox(height: 12),
            SrNote(
              message: l10n.salesBillNote,
              action: SrButton(
                label: l10n.salesSettings,
                size: SrButtonSize.sm,
                variant: SrButtonVariant.ghost,
                onPressed: () => context.push(Routes.settings),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SrSectionHeader(title: l10n.salesSend),
          const SizedBox(height: 8),
          ButtonRow(
            buttons: [
              SrButton(
                label: l10n.salesChannelWhatsApp,
                icon: Icons.chat_outlined,
                size: SrButtonSize.sm,
                variant: SrButtonVariant.secondary,
                onPressed: () => onShare(reminder),
              ),
              SrButton(
                label: l10n.salesChannelSmsShort,
                icon: Icons.sms_outlined,
                size: SrButtonSize.sm,
                variant: SrButtonVariant.secondary,
                onPressed: () => onShare(reminder),
              ),
              SrButton(
                label: l10n.salesPdf,
                icon: Icons.picture_as_pdf_outlined,
                size: SrButtonSize.sm,
                variant: SrButtonVariant.secondary,
                onPressed: onPdf,
              ),
            ],
          ),
          if (i.instalments.isNotEmpty) ...[
            const SizedBox(height: 18),
            SrSectionHeader(title: l10n.salesInstalments),
            const SizedBox(height: 8),
            InstalmentList(instalments: i.instalments),
          ],
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.taxInvoice});

  final Invoice invoice;
  final bool taxInvoice;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final i = invoice;
    final totals = i.totals;
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taxInvoice
                          ? l10n.salesTaxInvoiceNumber(i.number)
                          : l10n.salesBillNumber(i.number),
                      style: AppText.rowTitle(c.ink),
                    ),
                    Text(
                      l10n.salesCompanyOrder(i.companyName, i.orderNumber),
                      style: AppText.meta(c.ink2),
                    ),
                    Text(fmt.date(i.issuedAt), style: AppText.meta(c.ink3)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.money(totals.total),
                    style: AppText.metric(c.ink, size: 18),
                  ),
                  const SizedBox(height: 4),
                  i.due > 0
                      ? SrTag(
                          l10n.salesDueAmountLabel(fmt.money(i.due)),
                          tone: SrTone.err,
                        )
                      : SrTag(l10n.salesPaidInFull, tone: SrTone.ok),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          AmountLine(
            label: l10n.salesItemsAndServices,
            value: fmt.money(totals.subtotal),
          ),
          if (totals.discount > 0)
            AmountLine(
              label: l10n.salesDiscountPercent(fmt.bps(i.discountBps)),
              value: '− ${fmt.money(totals.discount)}',
            ),
          AmountLine(
            label: l10n.salesVatPercent(fmt.bps(i.vatBps)),
            value: fmt.money(totals.vat),
          ),
          AmountLine(
            label: l10n.salesCollected,
            value: '− ${fmt.money(i.paid)}',
          ),
        ],
      ),
    );
  }
}
