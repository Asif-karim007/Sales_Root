import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/billing_overview.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #103 Add-ons with the new plan, now or later. [request] is the plan the
/// user just chose.
class AddOnsLaterScreen extends ConsumerStatefulWidget {
  const AddOnsLaterScreen({super.key, required this.request});

  final CheckoutRequest request;

  @override
  ConsumerState<AddOnsLaterScreen> createState() => _AddOnsLaterScreenState();
}

class _AddOnsLaterScreenState extends ConsumerState<AddOnsLaterScreen> {
  Set<String>? _addOns;
  final Set<String> _packs = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = ref.watch(billingOverviewProvider);
    final overview = value.value;

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.billingAddOnsTitle,
        actions: const [BillingLanguageAction()],
      ),
      footer: overview == null ? null : _footer(overview),
      body: SrAsyncView(
        value: value,
        onRetry: () => ref.invalidate(billingOverviewProvider),
        loading: (_) => const SrSkeletonList(count: 2, cards: true),
        data: (context, overview) => _body(overview),
      ),
    );
  }

  PlanOffer _plan(BillingOverview overview) =>
      overview.catalog.planOrNull(widget.request.plan) ?? overview.plan;

  /// The add-ons the workspace keeps that the new plan doesn't include.
  Set<String> _kept(BillingOverview overview) {
    final catalog = overview.catalog;
    final plan = _plan(overview);
    return {
      for (final code in widget.request.addOns ?? overview.addOns)
        if (catalog.addOnOrNull(code) case final addOn?
            when !addOn.includedIn(plan))
          code,
    };
  }

  Set<String> _selected(BillingOverview overview) => _addOns ?? _kept(overview);

  Widget _footer(BillingOverview overview) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: SrButton(
            label: l10n.billingLater,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () => context.push(
              widget.request.copyWith(addOns: _kept(overview)).checkoutLocation,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SrButton(
            label: l10n.billingAddNow,
            expand: true,
            onPressed: () => context.push(
              widget.request
                  .copyWith(addOns: _selected(overview), packs: _packs.toList())
                  .checkoutLocation,
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(BillingOverview overview) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final catalog = overview.catalog;
    final plan = _plan(overview);
    final selected = _selected(overview);
    final recurring = catalog.addOns.where(
      (a) => !a.isPack && !a.includedIn(plan),
    );
    final packs = catalog.addOns.where(
      (a) => a.isPack && a.quota == QuotaKind.smsCredits,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text(
          l10n.billingAddOnsHeadline(plan.name),
          style: AppText.pageTitle(c.ink, size: 20),
        ),
        const SizedBox(height: 6),
        Text(l10n.billingAddOnsLead, style: AppText.lead(c.ink2)),
        const SizedBox(height: 14),
        SrCard(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              for (final addOn in recurring)
                _ToggleRow(
                  addOn: addOn,
                  value: selected.contains(addOn.code),
                  onChanged: (on) => setState(() {
                    final next = {...selected};
                    on ? next.add(addOn.code) : next.remove(addOn.code);
                    _addOns = next;
                  }),
                ),
              for (final pack in packs)
                _ToggleRow(
                  addOn: pack,
                  value: _packs.contains(pack.code),
                  onChanged: (on) => setState(
                    () => on ? _packs.add(pack.code) : _packs.remove(pack.code),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Summary(
          overview: overview,
          request: widget.request.copyWith(
            addOns: selected,
            packs: _packs.toList(),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.addOn,
    required this.value,
    required this.onChanged,
  });

  final AddOnOffer addOn;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final price = context.fmt.money(addOn.price);
    return SrListRow(
      title: addOn.name.of(context.isBangla),
      subtitle: switch (addOn.unit) {
        AddOnUnit.perUser => l10n.billingPricePerUserMonth(price),
        AddOnUnit.monthly => l10n.billingPricePerMonth(price),
        AddOnUnit.once => l10n.billingPriceOnce(price),
      },
      trailing: SrSwitch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.overview, required this.request});

  final BillingOverview overview;
  final CheckoutRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final catalog = overview.catalog;
    final plan = catalog.planOrNull(request.plan) ?? overview.plan;
    final seats = request.seats ?? overview.subscription.seats;
    final cycle = request.cycle ?? BillingCycle.monthly;
    final recurring = [
      for (final code in request.addOns ?? const <String>{})
        if (catalog.addOnOrNull(code) case final addOn?
            when !addOn.includedIn(plan))
          addOn,
    ];
    final planAmount = plan.seatPrice(cycle) * seats;
    final total = recurring.fold(
      planAmount,
      (sum, a) => sum + a.priceFor(seats, cycle),
    );
    final packs = [
      for (final code in request.packs) ?catalog.addOnOrNull(code),
    ];

    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          BillingLine(
            label: joinDot([plan.name, context.users(seats)]),
            value: fmt.money(planAmount),
          ),
          for (final addOn in recurring)
            BillingLine(
              label: joinDot([
                addOn.name.of(context.isBangla),
                fmt.number(seats),
              ]),
              value: fmt.money(addOn.priceFor(seats, cycle)),
            ),
          BillingLine(
            label: cycle == BillingCycle.yearly
                ? l10n.billingYearlyTotal
                : l10n.billingMonthlyTotal,
            value: fmt.money(total),
            total: true,
            last: packs.isEmpty,
          ),
          for (final pack in packs)
            BillingLine(
              label: pack.name.of(context.isBangla),
              value: l10n.billingPriceOnce(fmt.money(pack.price)),
              last: pack == packs.last,
            ),
        ],
      ),
    );
  }
}
