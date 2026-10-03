import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/features/billing/view/widget/milestone_track.dart';
import 'package:salesroot/features/billing/view/widget/referral_widgets.dart';
import 'package:salesroot/features/billing/view/widget/reward_sheet.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #186 Credit wallet: balance, what expires, milestones and transactions.
class ReferralWalletScreen extends ConsumerWidget {
  const ReferralWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenForReward(context, ref);
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SrSectionHeader(title: l10n.billingMilestones),
                  const SizedBox(height: 12),
                  MilestoneTrack(
                    milestones: overview.milestones,
                    paid: overview.paid,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SrCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SrSectionHeader(title: l10n.billingTransactions),
                  const SizedBox(height: 4),
                  _Transactions(percent: overview.conversionPercent),
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
  const _Transactions({required this.percent});

  final int percent;

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
            _EntryLine(
              entry: entry,
              percent: percent,
              last: entry == paged.items.last,
            ),
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
    final expiringAt = overview.expiringAt;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Kpi(
              label: l10n.billingExpiring,
              value: fmt.money(overview.expiringAmount),
              valueColor: overview.expiringAmount > 0 ? c.warning : c.ink,
              note: expiringAt == null
                  ? l10n.billingNothingExpiring
                  : joinDot([
                      fmt.dayMonth(expiringAt),
                      l10n.billingUseNextBill,
                    ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Kpi(
              label: l10n.billingOnHoldTitle,
              value: fmt.money(overview.onHold),
              valueColor: c.ink,
              note: l10n.billingHoldNote(fmt.number(overview.holdCount)),
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
  const _EntryLine({
    required this.entry,
    required this.percent,
    required this.last,
  });

  final WalletEntry entry;
  final int percent;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final name = entry.name.of(context.isBangla);
    final date = fmt.dayMonth(entry.at);
    final available = entry.availableAt;
    final (title, meta) = switch (entry.kind) {
      WalletEntryKind.welcome => (
        l10n.billingTxWelcome,
        joinDot([l10n.billingTxJoinedVia(name), date]),
      ),
      WalletEntryKind.registration => (
        l10n.billingTxRegistered(name),
        entry.held && available != null
            ? l10n.billingTxHeld(fmt.dayMonth(available))
            : date,
      ),
      WalletEntryKind.conversion => (
        l10n.billingTxBought(name),
        joinDot([l10n.billingTxConversion(fmt.number(percent)), date]),
      ),
      WalletEntryKind.milestone => (
        l10n.billingTxMilestone(fmt.number(entry.milestone)),
        joinDot([l10n.billingMilestone, date]),
      ),
      WalletEntryKind.redeemed => (
        l10n.billingTxInvoice(entry.invoiceNumber ?? ''),
        joinDot([l10n.billingTxUsed(entry.planName ?? ''), date]),
      ),
      WalletEntryKind.reversed => (
        l10n.billingTxReversed(name),
        joinDot([l10n.billingTxReversedNote, date]),
      ),
    };
    final color = entry.amount < 0
        ? c.ink
        : entry.held
        ? c.warning
        : c.success;
    return BillingLine(
      label: title,
      meta: meta,
      value: entry.amount < 0
          ? context.signedMoney(entry.amount)
          : l10n.billingPlus(fmt.money(entry.amount)),
      valueColor: color,
      last: last,
    );
  }
}
