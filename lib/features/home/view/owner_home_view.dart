import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/money_summary.dart';
import 'package:salesroot/features/home/view/widget/home_scroll_view.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #155: the owner's money dashboard — collection today or this month,
/// receivables, sales against target, the team's day and the top sellers.
class OwnerHomeView extends ConsumerStatefulWidget {
  const OwnerHomeView({super.key, required this.summary});

  final HomeSummary summary;

  @override
  ConsumerState<OwnerHomeView> createState() => _OwnerHomeViewState();
}

class _OwnerHomeViewState extends ConsumerState<OwnerHomeView> {
  bool _month = false;

  @override
  Widget build(BuildContext context) {
    final money =
        widget.summary.money ??
        const MoneySummary(
          today: CollectionPeriod(),
          month: CollectionPeriod(),
        );
    final team = ref.watch(moduleAccessProvider(AppModule.team));
    final plan = ref.watch(planProvider).value;
    final billing = ref.watch(
      moduleAccessProvider(AppModule.billing).select((a) => a.visible),
    );
    return HomeScrollView(
      children: [
        _SummaryTitle(
          month: _month,
          onChanged: (month) => setState(() => _month = month),
        ),
        _CollectionCard(
          period: _month ? money.month : money.today,
          month: _month,
        ),
        _MoneyTiles(money: money),
        if (money.teamToday.headcount > 0)
          _TeamTodayCard(
            team: money.teamToday,
            onTap: team.canView ? () => context.go(Routes.team) : null,
          ),
        if (money.topSellers.isNotEmpty) _TopSellers(sellers: money.topSellers),
        if (plan != null && billing) _PlanCard(plan: plan),
      ],
    );
  }
}

class _SummaryTitle extends StatelessWidget {
  const _SummaryTitle({required this.month, required this.onChanged});

  final bool month;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.fmt.weekdayDate(DateTime.now()),
                style: AppText.meta(c.ink2),
              ),
              Text(
                l10n.homeBusinessSummary,
                style: AppText.pageTitle(c.ink, size: 19),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 150,
          child: SrSegmented(
            compact: true,
            index: month ? 1 : 0,
            onChanged: (i) => onChanged(i == 1),
            segments: [
              SrSegment(l10n.commonToday),
              SrSegment(l10n.homePeriodMonth),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  const _CollectionCard({required this.period, required this.month});

  final CollectionPeriod period;
  final bool month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final canOpen = ref.watch(
      moduleAccessProvider(AppModule.collection).select((a) => a.canView),
    );
    final change = period.changePercent;
    final up = (change ?? 0) >= 0;
    final percent = fmt.percent(change?.abs() ?? 0);
    final delta = change == null
        ? null
        : switch ((month, up)) {
            (false, true) => l10n.homeAboveYesterday(percent),
            (false, false) => l10n.homeBelowYesterday(percent),
            (true, true) => l10n.homeAboveLastMonth(percent),
            (true, false) => l10n.homeBelowLastMonth(percent),
          };
    return SrCard(
      padding: const EdgeInsets.all(16),
      onTap: canOpen ? () => context.push(Routes.collection) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BigFigure(
                  label: month
                      ? l10n.homeCollectionMonth
                      : l10n.homeCollectionToday,
                  value: fmt.money(period.total),
                  delta: delta,
                  up: up,
                ),
              ),
              const SrAvatar(
                icon: Icons.payments_outlined,
                tone: SrAvatarTone.accent,
                square: true,
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: c.line),
          const SizedBox(height: 12),
          Row(
            children: [
              _SmallFigure(l10n.homeCash, fmt.moneyCompact(period.cash)),
              _SmallFigure(
                l10n.homeMobileMoney,
                fmt.moneyCompact(period.mobile),
              ),
              _SmallFigure(l10n.homeBank, fmt.moneyCompact(period.bank)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigFigure extends StatelessWidget {
  const _BigFigure({
    required this.label,
    required this.value,
    required this.delta,
    required this.up,
  });

  final String label;
  final String value;
  final String? delta;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final delta = this.delta;
    final tone = up ? c.success : c.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label(c.ink2)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(value, style: AppText.metric(c.ink, size: 30)),
        ),
        if (delta != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 15,
                color: tone,
              ),
              const SizedBox(width: 4),
              Flexible(child: Text(delta, style: AppText.label(tone))),
            ],
          ),
        ],
      ],
    );
  }
}

class _SmallFigure extends StatelessWidget {
  const _SmallFigure(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.label(c.ink2, size: 11.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(value, style: AppText.rowTitle(c.ink, size: 14)),
        ],
      ),
    );
  }
}

class _MoneyTiles extends ConsumerWidget {
  const _MoneyTiles({required this.money});

  final MoneySummary money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final collection = ref.watch(
      moduleAccessProvider(AppModule.collection).select((a) => a.canView),
    );
    final reports = ref.watch(
      moduleAccessProvider(AppModule.reports).select((a) => a.visible),
    );
    final target = money.targetPercent;
    return SrStatGrid(
      columns: 2,
      tiles: [
        SrKpiTile(
          label: l10n.homeReceivable,
          value: fmt.moneyCompact(money.receivable),
          delta: l10n.homeOverdueAmount(fmt.moneyCompact(money.overdue)),
          deltaUp: money.overdue > 0 ? true : null,
          upIsGood: false,
          onTap: collection ? () => context.push(Routes.outstanding) : null,
        ),
        SrCard(
          padding: const EdgeInsets.all(12),
          onTap: reports ? () => context.push(Routes.reportSales) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeSalesMonth, style: AppText.label(c.ink2)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  fmt.moneyCompact(money.salesMonth),
                  style: AppText.metric(c.ink),
                ),
              ),
              const SizedBox(height: 8),
              SrProgressBar(value: target / 100),
              const SizedBox(height: 4),
              Text(
                l10n.homeOfTarget(fmt.percent(target)),
                style: AppText.meta(c.ink2, size: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamTodayCard extends StatelessWidget {
  const _TeamTodayCard({required this.team, required this.onTap});

  final TeamToday team;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.groups_outlined, size: 20, color: c.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.homeTeamTodayLine(
                fmt.number(team.calls),
                fmt.number(team.visits),
                fmt.number(team.newLeads),
                '${fmt.number(team.present)}/${fmt.number(team.headcount)}',
              ),
              style: AppText.lead(c.ink, size: 13.5),
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, size: 20, color: c.ink3),
        ],
      ),
    );
  }
}

class _TopSellers extends ConsumerWidget {
  const _TopSellers({required this.sellers});

  final List<TopSeller> sellers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reports = ref.watch(
      moduleAccessProvider(AppModule.reports).select((a) => a.visible),
    );
    final team = ref.watch(
      moduleAccessProvider(AppModule.team).select((a) => a.canView),
    );
    final top = sellers.first.amount;
    return SrRowGroup(
      title: l10n.homeTopSellers,
      seeAllLabel: l10n.homeFullReport,
      onSeeAll: reports ? () => context.push(Routes.reportSales) : null,
      rows: [
        for (var i = 0; i < sellers.length; i++)
          _SellerRow(
            rank: i + 1,
            seller: sellers[i],
            share: top == 0 ? 0 : sellers[i].amount / top,
            onTap: team
                ? () => context.push(Routes.memberFor(sellers[i].memberId))
                : null,
          ),
      ],
    );
  }
}

class _SellerRow extends StatelessWidget {
  const _SellerRow({
    required this.rank,
    required this.seller,
    required this.share,
    required this.onTap,
  });

  final int rank;
  final TopSeller seller;
  final double share;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final name = seller.name.of(fmt.isBangla);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              child: Text(
                fmt.number(rank),
                textAlign: TextAlign.center,
                style: AppText.rowTitle(rank == 1 ? c.gold : c.ink3, size: 13),
              ),
            ),
            const SizedBox(width: 10),
            SrAvatar(name: name, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppText.rowTitle(c.ink, size: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        fmt.moneyCompact(seller.amount),
                        style: AppText.rowTitle(c.ink, size: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SrProgressBar(value: share),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final line = l10n.homePlanLine(
      plan.name,
      '${fmt.number(plan.usersUsed)}/${fmt.number(plan.users)}',
    );
    return SrCard(
      tone: SrCardTone.dashed,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => context.push(Routes.planUsage),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, size: 18, color: c.ink2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              plan.has(AddOn.fieldForce)
                  ? '$line · ${l10n.homeFieldForceOn}'
                  : line,
              style: AppText.meta(c.ink2),
            ),
          ),
          const SizedBox(width: 8),
          Text(l10n.homeManage, style: AppText.chip(c.accent, size: 13)),
        ],
      ),
    );
  }
}
