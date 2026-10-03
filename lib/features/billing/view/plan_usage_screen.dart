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
import 'package:salesroot/features/billing/models/usage.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #96 Plan and usage.
class PlanUsageScreen extends ConsumerWidget {
  const PlanUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SrScaffold(
      appBar: SrAppBar(
        title: context.l10n.billingPlanTitle,
        actions: const [BillingLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(billingOverviewProvider),
        onRetry: () => ref.invalidate(billingOverviewProvider),
        loading: (_) => const SrSkeletonList(count: 3, cards: true),
        data: (context, overview) => _PlanUsageBody(overview: overview),
      ),
    );
  }
}

class _PlanUsageBody extends ConsumerWidget {
  const _PlanUsageBody({required this.overview});

  final BillingOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit = ref.watch(
      moduleAccessProvider(AppModule.billing).select((a) => a.canEdit),
    );
    final recurring = overview.catalog.addOns.where(
      (a) => !a.isPack && a.inStore,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(planProvider)
          ..invalidate(subscriptionProvider);
        await ref.read(billingOverviewProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          const _CreditsNote(),
          _PlanCard(overview: overview),
          const SizedBox(height: 18),
          SrSectionHeader(title: l10n.billingUsageSection),
          const SizedBox(height: 8),
          _UsageCard(meters: overview.meters, canEdit: canEdit),
          const SizedBox(height: 18),
          SrSectionHeader(
            title: l10n.billingAddOnsSection,
            actionLabel: l10n.billingStore,
            onAction: () => context.push(Routes.addOns),
          ),
          const SizedBox(height: 8),
          SrCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                for (final addOn in recurring)
                  _AddOnRow(
                    addOn: addOn,
                    overview: overview,
                    canEdit: canEdit,
                    last: addOn == recurring.last,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Links(canEdit: canEdit),
        ],
      ),
    );
  }
}

class _CreditsNote extends ConsumerWidget {
  const _CreditsNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(
      moduleAccessProvider(AppModule.referral).select((a) => a.visible),
    );
    if (!visible) return const SizedBox.shrink();
    final balance = ref.watch(
      referralOverviewProvider.select((o) => o.value?.balance ?? 0),
    );
    if (balance <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.push(Routes.referWallet),
        child: SrNote(
          tone: SrNoteTone.gold,
          icon: Icons.card_giftcard_rounded,
          title: context.l10n.billingCreditsNote(context.fmt.money(balance)),
          message: context.l10n.billingCreditsNoteBody,
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.overview});

  final BillingOverview overview;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final subscription = overview.subscription;
    final plan = overview.plan;
    final renewsAt = subscription.renewsAt;
    final line = plan.isFree
        ? joinDot([context.users(subscription.seats), l10n.billingFreeForever])
        : joinDot([
            context.users(subscription.seats),
            context.cycleLabel(subscription.cycle),
            if (renewsAt != null) l10n.billingRenews(fmt.dayMonth(renewsAt)),
            fmt.money(overview.renewal),
          ]);

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const SrAvatar(
            icon: Icons.workspace_premium_outlined,
            size: 44,
            square: true,
            tone: SrAvatarTone.dark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: AppText.pageTitle(c.ink, size: 17)),
                Text(line, style: AppText.meta(c.ink2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SrTag(l10n.billingActive, tone: SrTone.ok),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.meters, required this.canEdit});

  final List<UsageMeter> meters;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return SrCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        children: [
          for (final meter in meters)
            _MeterRow(
              meter: meter,
              onTap: canEdit && meter.nearLimit
                  ? () => context.push(
                      Uri(
                        path: Routes.planChoose,
                        queryParameters: {
                          'reason': 'quota',
                          'kind': meter.kind.name,
                        },
                      ).toString(),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({required this.meter, required this.onTap});

  final UsageMeter meter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final onTap = this.onTap;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.quotaLabel(meter.kind),
                    style: AppText.lead(c.ink, size: 13),
                  ),
                ),
                if (onTap != null) ...[
                  Text(
                    context.l10n.billingGetMore,
                    style: AppText.chip(c.accent),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  context.usageValue(meter),
                  style: AppText.rowTitle(c.ink, size: 13),
                ),
              ],
            ),
            if (meter.limit != null) ...[
              const SizedBox(height: 5),
              SrProgressBar(
                value: meter.ratio,
                color: meter.nearLimit ? c.danger : c.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddOnRow extends StatelessWidget {
  const _AddOnRow({
    required this.addOn,
    required this.overview,
    required this.canEdit,
    required this.last,
  });

  final AddOnOffer addOn;
  final BillingOverview overview;
  final bool canEdit;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = overview.isOn(addOn);
    final seats = overview.subscription.seats;
    final included = addOn.includedIn == overview.plan.code;
    final subtitle = switch ((on, included)) {
      (_, true) => l10n.billingIncludedIn(overview.plan.name),
      (true, false) => joinDot([
        context.users(seats),
        l10n.billingPricePerMonth(context.fmt.money(addOn.price * seats)),
      ]),
      (false, false) => l10n.billingNotOn,
    };
    return SrListRow(
      title: addOn.name.of(context.isBangla),
      subtitle: subtitle,
      leading: SrAvatar(
        icon: addOnIcon(addOn.code),
        tone: on ? SrAvatarTone.accent : SrAvatarTone.neutral,
      ),
      trailing: on
          ? SrTag(l10n.billingOn, tone: SrTone.ok)
          : canEdit
          ? SrTag(l10n.billingAdd, tone: SrTone.accent)
          : null,
      chevron: true,
      divider: !last,
      onTap: () => context.push(Routes.addOns),
    );
  }
}

class _Links extends StatelessWidget {
  const _Links({required this.canEdit});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SrButton(
                label: l10n.billingCompare,
                icon: Icons.compare_arrows_rounded,
                variant: SrButtonVariant.secondary,
                size: SrButtonSize.sm,
                expand: true,
                onPressed: () => context.push(Routes.planCompare),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrButton(
                label: l10n.billingHistory,
                icon: Icons.receipt_long_outlined,
                variant: SrButtonVariant.secondary,
                size: SrButtonSize.sm,
                expand: true,
                onPressed: () => context.push(Routes.billingHistory),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (canEdit)
          SrButton(
            label: l10n.billingChangePlan,
            variant: SrButtonVariant.ghost,
            expand: true,
            onPressed: () => context.push(Routes.planChoose),
          )
        else
          SrNote(message: l10n.billingOwnerOnly, tone: SrNoteTone.neutral),
      ],
    );
  }
}
