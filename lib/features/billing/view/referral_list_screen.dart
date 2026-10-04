import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/features/billing/view/widget/referral_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #185 My referrals with status filters, and the team leaderboard.
class ReferralListScreen extends ConsumerStatefulWidget {
  const ReferralListScreen({super.key});

  @override
  ConsumerState<ReferralListScreen> createState() => _ReferralListState();
}

class _ReferralListState extends ConsumerState<ReferralListScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.billingMyReferrals,
        actions: const [BillingLanguageAction()],
        bottom: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: SrSegmented(
            segments: [
              SrSegment(l10n.billingMyReferrals),
              SrSegment(l10n.billingLeaderboard),
            ],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
      ),
      body: _tab == 0 ? const _MyReferrals() : const _Leaderboard(),
    );
  }
}

class _MyReferrals extends ConsumerWidget {
  const _MyReferrals();

  static const _filters = [
    null,
    ReferralStatus.pending,
    ReferralStatus.registered,
    ReferralStatus.bought,
    ReferralStatus.expired,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(referralFilterProvider);
    final list = ref.watch(referralsProvider);
    final counts = list.value?.facets['StatusCounts'] ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: _Kpis(),
        ),
        SrChipRow(
          chips: [
            for (final status in _filters)
              SrChipItem(
                status == null
                    ? l10n.commonAll
                    : context.referralStatus(status),
                count: status == null ? null : counts[status.wire],
              ),
          ],
          index: _filters.indexOf(filter).clamp(0, _filters.length - 1),
          onChanged: (i) =>
              ref.read(referralFilterProvider.notifier).set(_filters[i]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SrAsyncView(
            value: list,
            onRetry: () => ref.invalidate(referralsProvider),
            isEmpty: (paged) => paged.isEmpty,
            empty: (_) => Center(
              child: SrEmptyState(
                icon: Icons.group_add_outlined,
                title: l10n.billingReferEmpty,
                message: l10n.billingReferEmptyBody,
              ),
            ),
            data: (context, paged) => _List(paged: paged),
          ),
        ),
      ],
    );
  }
}

class _Kpis extends ConsumerWidget {
  const _Kpis();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final overview = ref.watch(referralOverviewProvider).value;
    String value(int? n) => n == null ? '' : fmt.number(n);
    return SrStatGrid(
      tiles: [
        SrKpiTile(
          label: l10n.billingKpiInvited,
          value: value(overview?.invited),
        ),
        SrKpiTile(label: l10n.billingKpiJoined, value: value(overview?.joined)),
        SrKpiTile(label: l10n.billingKpiBought, value: value(overview?.paid)),
      ],
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.paged});

  final Paged<Referral> paged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(referralsProvider.notifier);
    final items = paged.items;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(referralsProvider.future),
      child: LoadMoreListener(
        onLoadMore: notifier.loadMore,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            SrCard(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  for (final referral in items)
                    ReferralRow(
                      referral: referral,
                      divider: referral != items.last,
                    ),
                ],
              ),
            ),
            LoadMoreFooter(
              loading: paged.isLoadingMore,
              error: paged.loadMoreError,
              onRetry: notifier.loadMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaderboard extends ConsumerWidget {
  const _Leaderboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrAsyncView(
      value: ref.watch(referralLeaderboardProvider),
      onRetry: () => ref.invalidate(referralLeaderboardProvider),
      isEmpty: (rows) => rows.isEmpty,
      data: (context, rows) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          SrRowGroup(
            title: l10n.billingTeamThisMonth,
            rows: [
              for (var i = 0; i < rows.length; i++)
                _LeaderRow(rank: i + 1, entry: rows[i]),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final name = entry.name.of(context.isBangla);
    return SrListRow(
      title: entry.isMe ? l10n.billingYou(name) : name,
      leading: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: rank <= 3 ? c.goldTint : c.avatarBg,
          shape: BoxShape.circle,
        ),
        child: Text(
          fmt.number(rank),
          style: AppText.rowTitle(rank <= 3 ? c.gold : c.ink2, size: 14),
        ),
      ),
      trailing: SrTag(
        l10n.billingPaidCount(fmt.number(entry.paid)),
        tone: entry.isMe ? SrTone.ok : SrTone.neutral,
      ),
    );
  }
}
