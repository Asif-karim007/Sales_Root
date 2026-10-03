import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/amount_lines.dart';
import 'package:salesroot/features/sales/view/widget/items_table.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The quotation as the customer sees it: letterhead, items, totals and
/// terms (#56).
class QuotationDocCard extends StatelessWidget {
  const QuotationDocCard({
    super.key,
    required this.quotation,
    required this.seller,
  });

  final Quotation quotation;
  final SellerProfile? seller;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final q = quotation;
    final terms = [
      l10n.salesValidTo(fmt.dayMonth(q.validUntil)),
      l10n.paymentTerms(q.paymentTerms),
      l10n.salesDeliveryInDays(fmt.number(q.deliveryDays)),
      if (q.note.isNotEmpty) q.note,
    ].join(' · ');
    return SrCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DocLetterhead(
            seller: seller,
            title: l10n.salesPdfQuotation,
            meta: '${q.number} · ${fmt.date(q.createdAt)}',
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${l10n.salesPdfTo} ',
                  style: AppText.rowTitle(c.ink, size: 12.5),
                ),
                TextSpan(
                  text: q.contactName.isEmpty
                      ? q.companyName
                      : '${q.companyName} · ${q.contactName}',
                ),
              ],
            ),
            style: AppText.meta(c.ink, size: 12.5),
          ),
          const SizedBox(height: 10),
          ItemsTable(lines: q.lines),
          const SizedBox(height: 6),
          SalesTotalsLines(
            totals: q.totals,
            discountBps: q.discountBps,
            vatBps: q.vatBps,
          ),
          const SizedBox(height: 8),
          Text(terms, style: AppText.meta(c.ink2, size: 11.5)),
        ],
      ),
    );
  }
}

/// The seller's mark and name on the left, the document title and number on
/// the right.
class DocLetterhead extends StatelessWidget {
  const DocLetterhead({
    super.key,
    required this.seller,
    required this.title,
    required this.meta,
  });

  final SellerProfile? seller;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final profile = seller;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: profile == null
              ? const SrSkeletonBox(widthFactor: 0.6, height: 32)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SrAvatar(
                          name: profile.name,
                          size: 32,
                          square: true,
                          tone: SrAvatarTone.dark,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            profile.name,
                            style: AppText.rowTitle(c.ink, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.address} · ${fmt.phone(profile.phone)}',
                      style: AppText.meta(c.ink2, size: 11.5),
                    ),
                  ],
                ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.end,
                style: AppText.sectionTitle(c.ink),
              ),
              Text(
                meta,
                textAlign: TextAlign.end,
                style: AppText.meta(c.ink2, size: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
