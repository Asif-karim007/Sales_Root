import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/home/models/home_summary.dart';
import 'package:salesroot/features/home/view/widget/agenda_card.dart';
import 'package:salesroot/features/home/view/widget/ai_guide.dart';
import 'package:salesroot/features/home/view/widget/home_scroll_view.dart';
import 'package:salesroot/features/home/view/widget/quick_actions.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #13: the Easy home — today's calls, follow-ups and visits, quick adds and
/// the day's plan.
class EasyHomeView extends StatelessWidget {
  const EasyHomeView({super.key, required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final mine = fmt.percent(summary.meetingRate);
    final team = fmt.percent(summary.teamMeetingRate);
    return HomeScrollView(
      children: [
        _DayTiles(summary: summary),
        const HomeQuickActions(),
        AgendaCard(items: summary.agenda),
        AiHintCard(
          message: summary.meetingRate >= summary.teamMeetingRate
              ? l10n.homeAiRateAhead(mine, team)
              : l10n.homeAiRateBehind(mine, team),
        ),
      ],
    );
  }
}

class _DayTiles extends ConsumerWidget {
  const _DayTiles({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final tasks = ref.watch(
      moduleAccessProvider(AppModule.task).select((a) => a.canView),
    );
    final visits = ref.watch(
      moduleAccessProvider(AppModule.visit).select((a) => a.visible),
    );
    final leads = ref.watch(
      moduleAccessProvider(AppModule.lead).select((a) => a.canView),
    );
    final overdue = summary.followUpsOverdue;
    final openTasks = tasks ? () => context.go(Routes.tasks) : null;
    return SrStatGrid(
      tiles: [
        SrKpiTile(
          label: l10n.homeCallsToday,
          value: fmt.number(summary.callsToday),
          delta: l10n.homeCallsYesterday(fmt.number(summary.callsYesterday)),
          deltaUp: summary.callsToday >= summary.callsYesterday,
          onTap: openTasks,
        ),
        SrKpiTile(
          label: l10n.homeFollowUpsDue,
          value: fmt.number(summary.followUpsDue),
          delta: overdue > 0
              ? l10n.homeFollowUpsOverdue(fmt.number(overdue))
              : l10n.homeFollowUpsNoneOverdue,
          deltaUp: overdue > 0 ? true : null,
          upIsGood: false,
          onTap: openTasks,
        ),
        if (visits)
          SrKpiTile(
            label: l10n.homeVisits,
            value: fmt.number(summary.visitsToday),
            delta: summary.visitsToday > 1
                ? l10n.homeRouteReady
                : summary.visitsToday == 0
                ? l10n.homeNoVisits
                : null,
            deltaUp: summary.visitsToday > 1 ? true : null,
            onTap: () => context.push(
              summary.visitsToday > 1 ? Routes.visitRoute : Routes.visits,
            ),
          )
        else
          SrKpiTile(
            label: l10n.homeOpenLeads,
            value: fmt.number(summary.openLeads),
            onTap: leads ? () => context.go(Routes.leads) : null,
          ),
      ],
    );
  }
}
