import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/referral_widgets.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #185 My referrals and how far each one got.
class ReferralListScreen extends ConsumerWidget {
  const ReferralListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(referralsProvider);
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.billingMyReferrals,
        actions: const [BillingLanguageAction()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: _Kpis(),
          ),
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
      ),
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
