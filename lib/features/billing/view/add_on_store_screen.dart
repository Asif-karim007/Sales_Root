import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/billing_overview.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #102 Add-on store.
class AddOnStoreScreen extends ConsumerWidget {
  const AddOnStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.billingStoreTitle,
        actions: const [BillingLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(billingOverviewProvider),
        onRetry: () => ref.invalidate(billingOverviewProvider),
        loading: (_) => const SrSkeletonList(count: 6),
        data: (context, overview) => _StoreBody(overview: overview),
      ),
    );
  }
}

class _StoreBody extends ConsumerWidget {
  const _StoreBody({required this.overview});

  final BillingOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit = ref.watch(
      moduleAccessProvider(AppModule.billing).select((a) => a.canEdit),
    );
    final items = overview.catalog.addOns.where((a) => a.inStore).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        SrNote(message: l10n.billingStoreNote),
        const SizedBox(height: 12),
        SrCard(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              for (final addOn in items)
                _StoreRow(
                  addOn: addOn,
                  overview: overview,
                  canEdit: canEdit,
                  last: addOn == items.last,
                ),
            ],
          ),
        ),
        if (!canEdit) ...[
          const SizedBox(height: 12),
          SrNote(message: l10n.billingOwnerOnly, tone: SrNoteTone.neutral),
        ],
      ],
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
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
    final bangla = context.isBangla;
    final included = addOn.includedIn;
    final subtitle = included != null && included != overview.plan.code
        ? joinDot([
            addOn.detail.of(bangla),
            l10n.billingIncludedIn(
              overview.catalog.planOrNull(included)?.name ?? included,
            ),
          ])
        : addOn.detail.of(bangla);

    return SrListRow(
      title: addOn.name.of(bangla),
      subtitle: subtitle,
      leading: SrAvatar(icon: addOnIcon(addOn.code), tone: SrAvatarTone.accent),
      divider: !last,
      trailing: _Trailing(addOn: addOn, action: _action(context)),
    );
  }

  Widget? _action(BuildContext context) {
    final l10n = context.l10n;
    final catalog = overview.catalog;
    if (overview.isOn(addOn) && !addOn.isPack) {
      return SrTag(
        addOn.includedIn == overview.plan.code
            ? l10n.billingIncluded
            : l10n.billingOn,
        tone: SrTone.ok,
      );
    }
    if (!canEdit) return null;
    if (!catalog.available(addOn, overview.plan)) {
      final min = catalog.planOrNull(addOn.minPlan);
      return SrButton(
        label: l10n.billingNeedsPlan(min?.name ?? ''),
        size: SrButtonSize.sm,
        variant: SrButtonVariant.secondary,
        onPressed: () => context.push(
          Uri(
            path: Routes.planChoose,
            queryParameters: {'plan': ?min?.code},
          ).toString(),
        ),
      );
    }
    final request = addOn.isPack
        ? CheckoutRequest(packs: [addOn.code])
        : CheckoutRequest(
            addOns: {...overview.subscription.addOns, addOn.code},
          );
    return SrButton(
      label: addOn.isPack ? l10n.billingBuy : l10n.billingAdd,
      size: SrButtonSize.sm,
      onPressed: () => context.push(request.checkoutLocation),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.addOn, required this.action});

  final AddOnOffer addOn;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final action = this.action;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PriceText(
          amount: addOn.price,
          unit: addOn.isPack ? l10n.billingPerOnce : l10n.billingPerUserMonth,
          size: 14,
        ),
        if (action != null) ...[const SizedBox(height: 6), action],
        if (action == null)
          Text(l10n.billingOwnerBuys, style: AppText.meta(c.ink3, size: 11)),
      ],
    );
  }
}
