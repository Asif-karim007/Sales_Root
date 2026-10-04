import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/pdf/sales_pdf.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_wizard.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/features/sales/view/widget/items_table.dart';
import 'package:salesroot/features/sales/view/widget/pdf_sheet.dart';
import 'package:salesroot/features/sales/view/widget/sales_tile.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The draft as a quotation, for the preview and the PDF before it is saved.
Quotation previewQuotation(QuotationDraft draft, String number) {
  final customer = draft.customer;
  final revising = draft.revising;
  return Quotation(
    id: revising?.id ?? 0,
    number: revising?.number ?? number,
    version: (revising?.version ?? 0) + 1,
    companyId: customer?.companyId ?? 0,
    companyName: customer?.name ?? '',
    contactName: customer?.contactName ?? '',
    priceList: draft.priceList,
    lines: draft.lines,
    discountBps: draft.discountBps,
    vatBps: standardVatBps,
    validUntil: draft.validUntil,
    paymentTerms: draft.paymentTerms,
    deliveryDays: draft.deliveryDays,
    note: draft.note,
    status: QuotationStatus.draft,
    createdAt: DateTime.now(),
    ownerName: '',
  );
}

/// #54: the summary, how to send it, and a preview of the PDF.
class QuoteReviewStep extends ConsumerWidget {
  const QuoteReviewStep({super.key, required this.draft, required this.wizard});

  final QuotationDraft draft;
  final QuotationWizard wizard;

  Future<void> _preview(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final quotation = previewQuotation(draft, l10n.salesNewNumber);
    final seller = await ref.read(sellerProfileProvider.future);
    if (!context.mounted) return;
    await showSalesPdfSheet(
      context,
      title: quotation.number,
      fileName: '${quotation.number}.pdf',
      shareText: l10n.salesQuotationShareText(
        quotation.number,
        fmt.money(quotation.totals.total),
      ),
      build: (format) =>
          SalesPdf(l10n, fmt).quotation(quotation, seller, format: format),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final quotation = previewQuotation(draft, l10n.salesNewNumber);
    final channels = {
      SendChannel.whatsApp: Icons.chat_outlined,
      SendChannel.sms: Icons.sms_outlined,
      SendChannel.email: Icons.mail_outline_rounded,
      SendChannel.share: Icons.ios_share_rounded,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        14,
        SrMetrics.gutter,
        32,
      ),
      children: [
        SrCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SrAvatar(
                    icon: Icons.description_outlined,
                    size: 44,
                    square: true,
                    tone: SrAvatarTone.dark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.salesQuotationNumber(quotation.number),
                          style: AppText.rowTitle(c.ink),
                        ),
                        Text(
                          [
                            quotation.companyName,
                            fmt.money(quotation.totals.total),
                            l10n.salesValidTo(fmt.dayMonth(draft.validUntil)),
                          ].join(' · '),
                          style: AppText.meta(c.ink2),
                        ),
                      ],
                    ),
                  ),
                  SrIconButton(
                    icon: Icons.picture_as_pdf_outlined,
                    compact: true,
                    tooltip: l10n.salesPreviewPdf,
                    onTap: () => _preview(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ItemsTable(lines: draft.lines),
              const SizedBox(height: 4),
              SalesTotalsLines(
                totals: draft.totals,
                discountBps: draft.discountBps,
                vatBps: standardVatBps,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SrSectionHeader(title: l10n.salesHowToSend),
        const SizedBox(height: 8),
        SalesTileRow(
          tiles: [
            for (final MapEntry(key: channel, value: icon) in channels.entries)
              SalesTile(
                icon: icon,
                label: l10n.channel(channel),
                selected: draft.channel == channel,
                onTap: () => wizard.setChannel(channel),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SrNote(message: l10n.salesSendNote),
      ],
    );
  }
}
