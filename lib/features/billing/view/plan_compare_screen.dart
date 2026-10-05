import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/billing_overview.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #97 What the next plan adds. [target] is a plan code; the next plan up is
/// used when it is null.
class PlanCompareScreen extends ConsumerWidget {
  const PlanCompareScreen({super.key, this.target});

  final String? target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(billingOverviewProvider);
    final canEdit = ref.watch(
      moduleAccessProvider(AppModule.billing).select((a) => a.canEdit),
    );
    final overview = value.value;
    final to = overview == null ? null : _target(overview);

    return SrScaffold(
      appBar: SrAppBar(
        title: context.l10n.billingCompareTitle,
        actions: const [BillingLanguageAction()],
      ),
      footer: canEdit && to != null
          ? SrButton(
              label: context.l10n.billingUpgradeTo(to.name),
              expand: true,
              onPressed: () => context.push(
                Uri(
                  path: Routes.planChoose,
                  queryParameters: {'plan': to.code},
                ).toString(),
              ),
            )
          : null,
      body: SrAsyncView(
        value: value,
        onRetry: () => ref.invalidate(billingOverviewProvider),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, overview) {
          final to = _target(overview);
          if (to == null) return const _TopPlan();
          return _CompareBody(overview: overview, to: to);
        },
      ),
    );
  }

  PlanOffer? _target(BillingOverview overview) {
    final chosen = overview.catalog.planOrNull(target);
    final to = chosen ?? overview.nextPlan;
    if (to == null || to.rank <= overview.plan.rank) return null;
    return to;
  }
}

class _TopPlan extends StatelessWidget {
  const _TopPlan();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SrEmptyState(
        icon: Icons.workspace_premium_outlined,
        title: l10n.billingTopPlanTitle,
        message: l10n.billingTopPlanBody,
        actionLabel: l10n.billingSeePlans,
        onAction: () => context.push(Routes.planChoose),
      ),
    );
  }
}

class _CompareBody extends StatelessWidget {
  const _CompareBody({required this.overview, required this.to});

  final BillingOverview overview;
  final PlanOffer to;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final from = overview.plan;
    final added = [
      for (final layer in to.layers)
        if (!from.layers.contains(layer)) layer,
    ];
    final seats = overview.subscription.seats;
    final difference = to.pricePerUser - from.pricePerUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text(
          l10n.billingCompareHeadline(from.name, to.name),
          style: AppText.pageTitle(c.ink, size: 20),
        ),
        const SizedBox(height: 12),
        SrCard(
          tone: SrCardTone.tint,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: CheckList(
            items: [
              for (final layer in added)
                (context.layerLabel(layer), context.layerHint(layer)),
              (
                l10n.billingCompareLimits,
                l10n.billingCompareLimitsBody(
                  fmt.number(to.records),
                  fmt.number(to.storageGb),
                  fmt.number(to.cardScans),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                children: [
                  PriceText(
                    amount: to.pricePerUser,
                    unit: l10n.billingPerUserMonth,
                    size: 22,
                  ),
                  Text(
                    l10n.billingCompareNow(
                      fmt.money(from.pricePerUser),
                      fmt.money(difference),
                    ),
                    style: AppText.lead(c.ink2, size: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.billingCompareMore(
                  fmt.money(difference * seats),
                  fmt.number(seats),
                ),
                style: AppText.meta(c.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: SrButton(
            label: l10n.billingFullTable,
            variant: SrButtonVariant.ghost,
            size: SrButtonSize.sm,
            onPressed: () => context.push(Routes.planChoose),
          ),
        ),
      ],
    );
  }
}
