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
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #101 The purchase went through: what is on now and, when the server
/// raised one, the receipt.
class PlanActivatedScreen extends ConsumerWidget {
  const PlanActivatedScreen({super.key, this.invoiceId});

  final String? invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = invoiceId;
    final invoice = id == null ? null : ref.watch(invoiceProvider(id)).value;

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
        value: ref.watch(billingOverviewProvider),
        onRetry: () => ref.invalidate(billingOverviewProvider),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, overview) =>
            _ActivatedBody(overview: overview, invoice: invoice),
      ),
    );
  }
}

class _ActivatedBody extends ConsumerWidget {
  const _ActivatedBody({required this.overview, this.invoice});

  final BillingOverview overview;
  final Invoice? invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final plan = overview.plan;
    final renewsAt = overview.subscription.renewsAt;
    final invoice = this.invoice;
    final workspace = ref.watch(
      currentWorkspaceProvider.select((w) => w?.name ?? ''),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
      children: [
        const Center(child: BigCheck()),
        const SizedBox(height: 14),
        Text(
          l10n.billingIsOn(plan.name),
          textAlign: TextAlign.center,
          style: AppText.pageTitle(c.ink, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          joinDot([
            l10n.billingForUsers(fmt.number(overview.subscription.seats)),
            if (renewsAt != null) l10n.billingRenews(fmt.dayMonth(renewsAt)),
            if (invoice != null) l10n.billingReceiptSent,
          ]),
          textAlign: TextAlign.center,
          style: AppText.lead(c.ink2),
        ),
        const SizedBox(height: 20),
        SrCard(
          tone: SrCardTone.tint,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.billingWhatsNew, style: AppText.rowTitle(c.ink)),
              const SizedBox(height: 6),
              CheckList(
                items: [
                  for (final layer in overview.subscription.layers)
                    (context.layerLabel(layer), context.layerHint(layer)),
                ],
              ),
            ],
          ),
        ),
        if (invoice != null) ...[
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
      ],
    );
  }
}
