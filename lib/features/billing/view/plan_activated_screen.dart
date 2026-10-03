import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/billing/models/billing_overview.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/features/billing/view/widget/invoice_pdf_viewer.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #101 The purchase went through: what is on now and the receipt.
class PlanActivatedScreen extends ConsumerWidget {
  const PlanActivatedScreen({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final invoice = ref.watch(invoiceProvider(invoiceId));
    final overview = ref.watch(billingOverviewProvider);

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.billingSuccessTitle,
        showBack: false,
        actions: const [BillingLanguageAction()],
      ),
      footer: SrButton(
        label: l10n.billingGoHome,
        expand: true,
        onPressed: () => context.go(Routes.home),
      ),
      body: SrAsyncView(
        value: invoice,
        onRetry: () => ref.invalidate(invoiceProvider(invoiceId)),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, invoice) =>
            _ActivatedBody(invoice: invoice, overview: overview.value),
      ),
    );
  }
}

class _ActivatedBody extends ConsumerWidget {
  const _ActivatedBody({required this.invoice, required this.overview});

  final Invoice invoice;
  final BillingOverview? overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final item = invoice.item.of(context.isBangla);
    final news = _news(context);
    final workspace = ref.watch(
      currentWorkspaceProvider.select((w) => w?.name ?? ''),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
      children: [
        const Center(child: BigCheck()),
        const SizedBox(height: 14),
        Text(
          invoice.kind == InvoiceKind.pack
              ? l10n.billingPackAdded(item)
              : l10n.billingIsOn(item),
          textAlign: TextAlign.center,
          style: AppText.pageTitle(c.ink, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          _subtitle(context),
          textAlign: TextAlign.center,
          style: AppText.lead(c.ink2),
        ),
        if (news.isNotEmpty) ...[
          const SizedBox(height: 20),
          SrCard(
            tone: SrCardTone.tint,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.billingWhatsNew, style: AppText.rowTitle(c.ink)),
                const SizedBox(height: 6),
                CheckList(items: news),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SrButton(
          label: l10n.billingViewReceipt,
          icon: Icons.receipt_long_outlined,
          variant: SrButtonVariant.secondary,
          expand: true,
          onPressed: () => context.openPdf(
            name: '${invoice.number}.pdf',
            title: invoice.number,
            load: () => context.invoicesPdf([invoice], workspace),
          ),
        ),
      ],
    );
  }

  String _subtitle(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final renewsAt = overview?.subscription.renewsAt;
    return joinDot([
      if (invoice.kind == InvoiceKind.plan && invoice.seats > 0)
        l10n.billingForUsers(fmt.number(invoice.seats)),
      if (invoice.kind != InvoiceKind.pack && renewsAt != null)
        l10n.billingRenews(fmt.dayMonth(renewsAt)),
      if (invoice.kind == InvoiceKind.pack) fmt.money(invoice.total),
      l10n.billingReceiptSent,
    ]);
  }

  List<(String, String?)> _news(BuildContext context) {
    final overview = this.overview;
    if (overview == null) return const [];
    final bangla = context.isBangla;
    final catalog = overview.catalog;
    final codes = invoice.quote.lines.map((l) => l.code).toSet();
    return [
      for (final plan in catalog.plans)
        if (codes.contains(plan.code) && invoice.kind == InvoiceKind.plan)
          for (final f in plan.features)
            (f.name.of(bangla), f.detail.of(bangla)),
      for (final addOn in catalog.addOns)
        if (codes.contains(addOn.code) && invoice.kind != InvoiceKind.plan)
          (addOn.name.of(bangla), addOn.detail.of(bangla)),
    ];
  }
}
