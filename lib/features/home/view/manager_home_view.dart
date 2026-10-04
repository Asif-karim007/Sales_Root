import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/models/money_summary.dart';
import 'package:salesroot/features/home/view/widget/home_scroll_view.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #156: the manager's home — sales, collection and overdue money, the
/// month's forecast, each team's progress and what needs a decision.
class ManagerHomeView extends StatelessWidget {
  const ManagerHomeView({super.key, required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final money =
        summary.money ??
        const MoneySummary(
          today: CollectionPeriod(),
          month: CollectionPeriod(),
        );
    return HomeScrollView(
      children: [
        _MoneyTiles(money: money),
        _ForecastCard(money: money),
        if (money.departments.isNotEmpty)
          _Departments(departments: money.departments),
        _NeedsAttention(money: money),
      ],
    );
  }
}

class _MoneyTiles extends ConsumerWidget {
  const _MoneyTiles({required this.money});

  final MoneySummary money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final reports = ref.watch(
      moduleAccessProvider(AppModule.reports).select((a) => a.visible),
    );
    final collection = ref.watch(
      moduleAccessProvider(AppModule.collection).select((a) => a.canView),
    );
    final salesChange = money.salesLastMonth == 0
        ? null
        : ((money.salesMonth - money.salesLastMonth) *
                  100 /
                  money.salesLastMonth)
              .round();
    final collectionChange = money.month.changePercent;
    return SrStatGrid(
      tiles: [
        SrKpiTile(
          label: l10n.homeSales,
          value: fmt.moneyCompact(money.salesMonth),
          delta: salesChange == null ? null : fmt.percent(salesChange.abs()),
          deltaUp: salesChange == null ? null : salesChange >= 0,
          onTap: reports ? () => context.push(Routes.reportSales) : null,
        ),
        SrKpiTile(
          label: l10n.homeCollection,
          value: fmt.moneyCompact(money.month.total),
          delta: collectionChange == null
              ? null
              : fmt.percent(collectionChange.abs()),
          deltaUp: collectionChange == null ? null : collectionChange >= 0,
          onTap: collection ? () => context.push(Routes.collection) : null,
        ),
        SrKpiTile(
          label: l10n.homeOverdue,
          value: fmt.moneyCompact(money.overdue),
          delta: l10n.homeOverdueCustomers(fmt.number(money.overdueCustomers)),
          deltaUp: money.overdueCustomers > 0 ? true : null,
          upIsGood: false,
          onTap: collection ? () => context.push(Routes.outstanding) : null,
        ),
      ],
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.money});

  final MoneySummary money;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SrSectionHeader(
            title: l10n.homeForecast(fmt.monthYear(DateTime.now())),
            actionLabel: l10n.homeWeighted,
          ),
          const SizedBox(height: 12),
          SrColumnChart(
            series: [
              for (var i = 0; i < money.forecastWeeks.length; i++)
                SrSeries(
                  label: l10n.homeWeek(fmt.number(i + 1)),
                  value: money.forecastWeeks[i].toDouble(),
                ),
              SrSeries(
                label: l10n.homePipe,
                value: money.forecastPipeline.toDouble(),
                dim: true,
              ),
              SrSeries(
                label: l10n.homeRisk,
                value: money.forecastAtRisk.toDouble(),
                color: c.danger,
                dim: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Departments extends StatelessWidget {
  const _Departments({required this.departments});

  final List<DepartmentScore> departments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrSectionHeader(title: l10n.homeByDepartment),
        const SizedBox(height: 8),
        SrCard(
          child: Column(
            children: [
              for (var i = 0; i < departments.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                SrBarRow(
                  label: l10n.homeTeamOf(departments[i].name.of(fmt.isBangla)),
                  value: departments[i].percent.toDouble(),
                  max: 100,
                  valueLabel: fmt.percent(departments[i].percent),
                  labelWidth: 120,
                  valueWidth: 44,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NeedsAttention extends ConsumerWidget {
  const _NeedsAttention({required this.money});

  final MoneySummary money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final leads = ref.watch(
      moduleAccessProvider(AppModule.lead).select((a) => a.canView),
    );
    final collection = ref.watch(
      moduleAccessProvider(AppModule.collection).select((a) => a.canView),
    );
    final attendance = ref.watch(
      moduleAccessProvider(AppModule.teamAttendance).select((a) => a.canView),
    );
    final staleTeam = money.staleLeadsTeam;
    final overdue = money.overdueCustomer;
    final absent = money.teamToday.absent;
    final rows = [
      if (money.staleLeads > 0)
        SrListRow(
          title: l10n.homeStaleLeads(fmt.number(money.staleLeads)),
          subtitle: staleTeam == null
              ? null
              : '${l10n.homeTeamOf(staleTeam.name.of(fmt.isBangla))} · '
                    '${fmt.number(staleTeam.count)}',
          leading: const SrAvatar(
            icon: Icons.schedule_rounded,
            tone: SrAvatarTone.danger,
          ),
          chevron: leads,
          onTap: leads ? () => context.go(Routes.leads) : null,
        ),
      if (overdue != null)
        SrListRow(
          title: l10n.homeOverdueDays(overdue.name, fmt.number(overdue.days)),
          subtitle:
              '${fmt.moneyCompact(overdue.amount)} · '
              '${overdue.ownerName.of(fmt.isBangla)}',
          leading: const SrAvatar(
            icon: Icons.receipt_long_outlined,
            tone: SrAvatarTone.gold,
          ),
          chevron: collection,
          onTap: collection ? () => context.push(Routes.outstanding) : null,
        ),
      if (absent > 0)
        SrListRow(
          title: l10n.homeNotCheckedIn(fmt.number(absent)),
          leading: const SrAvatar(icon: Icons.person_off_outlined),
          chevron: attendance,
          onTap: attendance ? () => context.push(Routes.attendanceTeam) : null,
        ),
    ];
    if (rows.isEmpty) {
      return SrNote(
        message: l10n.homeAllClear,
        icon: Icons.check_circle_outline_rounded,
      );
    }
    return SrRowGroup(title: l10n.homeNeedsAttention, rows: rows);
  }
}
