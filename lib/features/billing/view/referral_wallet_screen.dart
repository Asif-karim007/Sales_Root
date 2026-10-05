import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/features/billing/view/widget/referral_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #186 Credit wallet: balance, what expires, what is held and the
/// transactions.
class ReferralWalletScreen extends ConsumerWidget {
  const ReferralWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SrScaffold(
      appBar: SrAppBar(
        title: context.l10n.billingWalletTitle,
        actions: const [BillingLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(referralOverviewProvider),
        onRetry: () => ref.invalidate(referralOverviewProvider),
        loading: (_) => const SrSkeletonList(count: 3, cards: true),
        data: (context, overview) => _WalletBody(overview: overview),
      ),
    );
  }
}

class _WalletBody extends ConsumerWidget {
  const _WalletBody({required this.overview});

  final ReferralOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(walletEntriesProvider.notifier);
    final paged = ref.watch(walletEntriesProvider).value;

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(walletEntriesProvider)
          ..invalidate(referralOverviewProvider);
        await ref.read(referralOverviewProvider.future);
      },
      child: LoadMoreListener(
        onLoadMore: notifier.loadMore,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            WalletCard(overview: overview),
            const SizedBox(height: 10),
            _Kpis(overview: overview),
            const SizedBox(height: 10),
            SrCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SrSectionHeader(title: l10n.billingTransactions),
                  const SizedBox(height: 4),
                  const _Transactions(),
                ],
              ),
            ),
            if (paged != null)
              LoadMoreFooter(
                loading: paged.isLoadingMore,
                error: paged.loadMoreError,
                onRetry: notifier.loadMore,
              ),
            const SizedBox(height: 12),
            SrNote(message: l10n.billingCreditsRules),
          ],
        ),
      ),
    );
  }
}

class _Transactions extends ConsumerWidget {
  const _Transactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    return switch (ref.watch(walletEntriesProvider)) {
      AsyncValue(value: final paged?) when paged.isEmpty => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          context.l10n.billingNoTransactions,
          style: AppText.meta(c.ink2),
        ),
      ),
      AsyncValue(value: final paged?) => Column(
        children: [
          for (final entry in paged.items)
            _EntryLine(entry: entry, last: entry == paged.items.last),
        ],
      ),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SrErrorState(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(walletEntriesProvider),
        ),
      ),
      _ => const SrSkeletonList(
        count: 3,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
    };
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.overview});

  final ReferralOverview overview;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Kpi(
              label: l10n.billingExpiring,
              value: fmt.money(overview.expiringAmount),
              valueColor: overview.expiringAmount > 0 ? c.warning : c.ink,
              note: overview.expiringAmount > 0
                  ? l10n.billingUseNextBill
                  : l10n.billingNothingExpiring,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Kpi(
              label: l10n.billingOnHoldTitle,
              value: fmt.money(overview.onHold),
              valueColor: c.ink,
              note: l10n.billingHoldNote(fmt.number(overview.holdDays)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.note,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label(c.ink2)),
          const SizedBox(height: 4),
          Text(value, style: AppText.metric(valueColor, size: 20)),
          const SizedBox(height: 2),
          Text(note, style: AppText.meta(c.ink2, size: 12)),
        ],
      ),
    );
  }
}

class _EntryLine extends StatelessWidget {
  const _EntryLine({required this.entry, required this.last});

  final WalletEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final at = entry.at;
    final available = entry.availableAt;
    final spent = entry.amount < 0;
    return BillingLine(
      label: spent ? l10n.billingTxSpent : l10n.billingTxEarned,
      meta: joinDot([
        ?entry.reason,
        if (at != null) fmt.dayMonth(at),
        if (entry.held && available != null)
          l10n.billingTxHeld(fmt.dayMonth(available)),
      ]),
      value: spent
          ? context.signedMoney(entry.amount)
          : l10n.billingPlus(fmt.money(entry.amount)),
      valueColor: spent
          ? c.ink
          : entry.held
          ? c.warning
          : c.success,
      last: last,
    );
  }
}
