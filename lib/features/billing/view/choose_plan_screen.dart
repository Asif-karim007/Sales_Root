import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/billing_overview.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/usage.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/features/billing/view/widget/limit_header.dart';
import 'package:salesroot/features/billing/view/widget/plan_option_card.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #99 Choose a plan. With [quota] it opens on #98, the limit that was hit.
class ChoosePlanScreen extends ConsumerStatefulWidget {
  const ChoosePlanScreen({super.key, this.quota, this.preselect});

  final QuotaKind? quota;
  final String? preselect;

  @override
  ConsumerState<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

/// The user's picks over the defaults the data suggests.
class _Choice {
  const _Choice({
    required this.plan,
    required this.cycle,
    required this.seats,
    required this.limit,
    required this.quickFix,
  });

  final PlanOffer plan;
  final BillingCycle cycle;
  final int seats;
  final LimitOffer? limit;
  final bool quickFix;
}

class _ChoosePlanScreenState extends ConsumerState<ChoosePlanScreen> {
  String? _plan;
  BillingCycle? _cycle;
  int? _seats;
  bool _quickFix = true;

  _Choice _choiceOf(BillingOverview overview) {
    final subscription = overview.subscription;
    final quota = widget.quota;
    final limit = quota == null
        ? null
        : LimitOffer.of(quota, overview.catalog, subscription);
    final catalog = overview.catalog;
    final plan =
        catalog.planOrNull(_plan) ??
        catalog.planOrNull(widget.preselect) ??
        limit?.upgrade ??
        overview.nextPlan ??
        overview.plan;
    final wanted =
        _seats ??
        (quota == QuotaKind.users
            ? subscription.seats + 1
            : subscription.seats);
    return _Choice(
      plan: plan,
      cycle: _cycle ?? BillingCycle.monthly,
      seats: _clampSeats(wanted, plan, subscription.activeUsers),
      limit: limit,
      quickFix: (limit?.hasQuickFix ?? false) && _quickFix,
    );
  }

  static int _clampSeats(int seats, PlanOffer plan, int activeUsers) {
    final least = _leastSeats(plan, activeUsers);
    return seats < least ? least : seats;
  }

  /// A plan is sold with its minimum seats, and never fewer than the people
  /// already in the workspace.
  static int _leastSeats(PlanOffer plan, int activeUsers) =>
      activeUsers > plan.minUsers ? activeUsers : plan.minUsers;

  CheckoutRequest _request(BillingOverview overview, _Choice choice) {
    final subscription = overview.subscription;
    final limit = choice.limit;
    if (choice.quickFix && limit != null) {
      final fix = limit.quickFix(subscription);
      if (fix != null) return fix;
    }
    return CheckoutRequest(
      plan: choice.plan.code,
      seats: choice.seats,
      cycle: choice.cycle,
    );
  }

  void _continue(BillingOverview overview, _Choice choice) {
    final request = _request(overview, choice);
    final catalog = overview.catalog;
    final offersAddOns = catalog.addOns.any(
      (a) => !a.isPack && !a.includedIn(choice.plan),
    );
    final later = !choice.quickFix && !choice.plan.isFree && offersAddOns;
    context.push(
      later ? request.locationOf(Routes.addOnsLater) : request.checkoutLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(moduleAccessProvider(AppModule.billing));
    final quota = widget.quota;
    if (!access.canView && quota != null) return _AskOwner(quota: quota);
    final canEdit = access.canEdit;
    final value = ref.watch(billingOverviewProvider);
    final overview = value.value;

    return SrScaffold(
      appBar: SrAppBar(
        title: context.l10n.billingChooseTitle,
        actions: const [BillingLanguageAction()],
      ),
      footer: overview == null || !canEdit
          ? null
          : _footer(overview, _choiceOf(overview)),
      body: SrAsyncView(
        value: value,
        onRetry: () => ref.invalidate(billingOverviewProvider),
        loading: (_) => const SrSkeletonList(count: 4, cards: true),
        data: (context, overview) => _body(overview, canEdit),
      ),
    );
  }

  Widget _footer(BillingOverview overview, _Choice choice) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final subscription = overview.subscription;
    final limit = choice.limit;
    final pack = limit?.pack;
    final isCurrent =
        choice.plan.code == subscription.planCode &&
        choice.cycle == BillingCycle.monthly &&
        choice.seats == subscription.seats;
    final String label;
    if (choice.quickFix && limit != null) {
      label = pack != null
          ? l10n.billingBuyPack(
              pack.name.of(context.isBangla),
              fmt.money(pack.price),
            )
          : l10n.billingAddSeats(
              fmt.number(limit.extraSeats),
              fmt.money(limit.quickFixPrice),
            );
    } else if (isCurrent) {
      label = l10n.billingCurrentPlan;
    } else {
      label = l10n.billingChoosePlan(choice.plan.name);
    }
    return SrButton(
      label: label,
      expand: true,
      onPressed: isCurrent && !choice.quickFix
          ? null
          : () => _continue(overview, choice),
    );
  }

  Widget _body(BillingOverview overview, bool canEdit) {
    final l10n = context.l10n;
    final choice = _choiceOf(overview);
    final limit = choice.limit;
    final subscription = overview.subscription;
    final plan = choice.plan;
    final ownerName = ref.watch(
      currentWorkspaceProvider.select((w) => w?.ownerName),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        if (limit != null) ...[
          LimitHeader(
            offer: limit,
            quickFixSelected: choice.quickFix,
            ownerName: ownerName,
            onSelect: canEdit
                ? (quick) => setState(() {
                    _quickFix = quick;
                    if (!quick) _plan = limit.upgrade?.code ?? _plan;
                  })
                : null,
          ),
          const SizedBox(height: 18),
          SrSectionHeader(title: l10n.billingAllPlans),
          const SizedBox(height: 10),
        ],
        SrSegmented(
          segments: [
            SrSegment(l10n.billingMonthly),
            SrSegment(l10n.billingYearlyFree),
          ],
          index: choice.cycle == BillingCycle.yearly ? 1 : 0,
          onChanged: (i) => setState(
            () => _cycle = i == 1 ? BillingCycle.yearly : BillingCycle.monthly,
          ),
        ),
        const SizedBox(height: 12),
        for (final offer in overview.catalog.plans) ...[
          _PlanTile(
            plan: offer,
            cycle: choice.cycle,
            selected: !choice.quickFix && offer.code == plan.code,
            current: offer.code == subscription.planCode,
            onTap: () => setState(() {
              _plan = offer.code;
              _quickFix = false;
            }),
          ),
          const SizedBox(height: 10),
        ],
        if (!choice.quickFix && !plan.isFree) ...[
          _SeatsCard(
            plan: plan,
            cycle: choice.cycle,
            seats: choice.seats,
            activeUsers: subscription.activeUsers,
            onChanged: (seats) => setState(() => _seats = seats),
          ),
          const SizedBox(height: 12),
        ],
        SrNote(message: l10n.billingPricesNote),
      ],
    );
  }
}

/// A member hit a limit: only the owner can buy, so no billing data loads.
class _AskOwner extends ConsumerWidget {
  const _AskOwner({required this.quota});

  final QuotaKind quota;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final owner = ref.watch(
      currentWorkspaceProvider.select((w) => w?.ownerName),
    );
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.billingChooseTitle,
        actions: const [BillingLanguageAction()],
      ),
      body: Center(
        child: SrEmptyState(
          icon: quotaIcon(quota),
          title: limitTitle(l10n, quota),
          message: owner == null
              ? l10n.billingAskOwner
              : l10n.billingAskOwnerNamed(owner),
          actionLabel: l10n.billingNotNow,
          onAction: () => context.pop(),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.cycle,
    required this.selected,
    required this.current,
    required this.onTap,
  });

  final PlanOffer plan;
  final BillingCycle cycle;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final unit = plan.isFree ? l10n.billingPerMonth : l10n.billingPerUserMonth;

    return PlanOptionCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: AppText.rowTitle(c.ink, size: 15.5),
                ),
              ),
              PriceText(amount: plan.pricePerUser, unit: unit),
            ],
          ),
          const SizedBox(height: 2),
          Text(context.layersLine(plan), style: AppText.meta(c.ink2)),
          if (cycle == BillingCycle.yearly && !plan.isFree)
            Text(
              l10n.billingYearlyPrice(fmt.money(plan.seatPrice(cycle))),
              style: AppText.meta(c.accent),
            ),
          if (plan.minUsers > 1 && !plan.isFree)
            Text(
              l10n.billingMinUsers(fmt.number(plan.minUsers)),
              style: AppText.meta(c.ink2),
            ),
          if (current) ...[
            const SizedBox(height: 6),
            SrTag(l10n.billingCurrent, tone: SrTone.ok),
          ],
        ],
      ),
    );
  }
}

class _SeatsCard extends StatelessWidget {
  const _SeatsCard({
    required this.plan,
    required this.cycle,
    required this.seats,
    required this.activeUsers,
    required this.onChanged,
  });

  final PlanOffer plan;
  final BillingCycle cycle;
  final int seats;
  final int activeUsers;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final total = plan.seatPrice(cycle) * seats;
    final saving = plan.yearlySaving(seats);
    final perSeat = cycle == BillingCycle.yearly
        ? plan.yearlyPerUser
        : plan.pricePerUser;

    return SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.billingSeatsTitle, style: AppText.fieldLabel(c.ink2)),
          const SizedBox(height: 8),
          SeatStepper(
            value: seats,
            label: context.users(seats),
            min: _ChoosePlanScreenState._leastSeats(plan, activeUsers),
            onChanged: onChanged,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.billingSeatsActive(fmt.number(activeUsers)),
            textAlign: TextAlign.center,
            style: AppText.meta(c.ink2),
          ),
          const Divider(height: 22),
          BillingLine(
            label: l10n.billingSeatsTotal(
              context.users(seats),
              fmt.money(perSeat),
            ),
            value: '${fmt.money(total)}${context.perCycleUnit(cycle)}',
            meta: cycle == BillingCycle.yearly
                ? l10n.billingYearlySaving(fmt.money(saving))
                : null,
            last: true,
          ),
        ],
      ),
    );
  }
}
