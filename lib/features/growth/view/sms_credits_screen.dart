import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/providers/campaign_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #147 Buy SMS credits.
class SmsCreditsScreen extends ConsumerStatefulWidget {
  const SmsCreditsScreen({super.key});

  @override
  ConsumerState<SmsCreditsScreen> createState() => _SmsCreditsScreenState();
}

class _SmsCreditsScreenState extends ConsumerState<SmsCreditsScreen> {
  int? _packId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final packs = ref.watch(creditPacksProvider);
    final purchase = ref.watch(creditPurchaseProvider);
    ref.listen(creditPurchaseProvider, _onPurchase);
    final canBuy = ref.watch(moduleAccessProvider(AppModule.campaign)).canAdd;
    final list = packs.value ?? const <CreditPack>[];
    final pack =
        list.where((p) => p.id == _packId).firstOrNull ??
        list.where((p) => p.popular).firstOrNull ??
        list.firstOrNull;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthCreditsTitle,
        actions: const [GrowthLanguageAction()],
      ),
      body: SrAsyncView(
        value: packs,
        onRetry: () => ref.invalidate(creditPacksProvider),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 4, cards: true),
        isEmpty: (packs) => packs.isEmpty,
        data: (context, packs) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            const _Lead(),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < packs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _PackCard(
                      pack: packs[i],
                      selected: packs[i].id == pack?.id,
                      onTap: () => setState(() => _packId = packs[i].id),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const _BalanceCard(),
            const SizedBox(height: 12),
            SrNote(message: l10n.growthCreditsRule),
          ],
        ),
      ),
      footer: !canBuy || pack == null
          ? null
          : SrButton(
              label: l10n.growthCreditsBuy(
                fmt.number(pack.credits),
                fmt.money(pack.price),
              ),
              expand: true,
              loading: purchase.isLoading,
              onPressed: () => _confirm(pack),
            ),
    );
  }

  Future<void> _confirm(CreditPack pack) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.growthCreditsConfirmTitle(fmt.number(pack.credits)),
      message: l10n.growthCreditsConfirmBody(fmt.money(pack.price)),
      confirmLabel: l10n.growthCreditsPay(fmt.money(pack.price)),
      icon: Icons.account_balance_wallet_outlined,
    );
    if (!confirmed || !mounted) return;
    await ref.read(creditPurchaseProvider.notifier).buy(pack.id);
  }

  void _onPurchase(
    AsyncValue<MessagingBalance?>? _,
    AsyncValue<MessagingBalance?> next,
  ) {
    switch (next) {
      case AsyncError(:final error):
        showSrError(context, growthFailureText(context, error));
      case AsyncData(:final value?):
        showSrSuccess(
          context,
          context.l10n.growthCreditsDone(context.fmt.number(value.smsCredits)),
        );
        if (context.canPop()) context.pop();
      default:
        return;
    }
  }
}

class _Lead extends ConsumerWidget {
  const _Lead();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final sender = ref.watch(messagingBalanceProvider).value?.senderId;
    if (sender == null) return const SizedBox.shrink();
    return Text(
      context.l10n.growthCreditsLead(sender),
      style: AppText.lead(c.ink2),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.selected,
    required this.onTap,
  });

  final CreditPack pack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? c.tint : c.surface,
            borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
            border: Border.all(
              color: selected ? c.accent : c.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                fmt.number(pack.credits),
                style: AppText.metric(c.ink, size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                fmt.money(pack.price),
                style: AppText.rowTitle(c.accent, size: 16),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.growthCreditsEach(fmt.number(pack.unitPrice, decimals: 2)),
                style: AppText.meta(c.ink2, size: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return switch (ref.watch(messagingBalanceProvider)) {
      AsyncData(:final value) => GrowthInfoCard(
        lines: [
          (l10n.growthCreditsBalance, fmt.number(value.smsCredits)),
          (l10n.growthCreditsUsed, fmt.number(value.smsUsedThisMonth)),
          (
            l10n.growthCreditsAverage,
            l10n.growthCreditsAverageValue(
              fmt.number(value.averageSegments, decimals: 1),
            ),
          ),
        ],
      ),
      AsyncError(:final error) => SrErrorState(
        error: error,
        compact: true,
        onRetry: () => ref.invalidate(messagingBalanceProvider),
      ),
      _ => const SrSkeletonBox(height: 120, radius: 14),
    };
  }
}
