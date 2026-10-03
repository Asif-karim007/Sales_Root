import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/service/route_plan.dart';
import 'package:salesroot/features/field_force/view/widget/duty_card.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/features/field_force/view/widget/new_visit_sheet.dart';
import 'package:salesroot/features/field_force/view/widget/visit_row.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #120 visits: the duty card, today's numbers and today's visit list.
/// `?new=1&leadId=` opens the new-visit sheet, prefilled with the lead.
class VisitsScreen extends ConsumerStatefulWidget {
  const VisitsScreen({super.key, this.openNew = false, this.leadId});

  final bool openNew;
  final int? leadId;

  @override
  ConsumerState<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends ConsumerState<VisitsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _newVisit());
    }
  }

  Future<void> _newVisit() async {
    final access = ref.read(moduleAccessProvider(AppModule.visit));
    if (!access.canAdd || !mounted) return;
    final result = await showNewVisitSheet(context, leadId: widget.leadId);
    if (result == null || !mounted) return;
    if (result.checkInNow) {
      context.push(Routes.visitCheckInFor(result.visit.id));
    } else {
      showSrSuccess(context, context.l10n.ffVisitPlanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attendance = ref.watch(moduleAccessProvider(AppModule.attendance));
    final visit = ref.watch(moduleAccessProvider(AppModule.visit));
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffVisitsTitle,
        actions: [
          const FfLanguageToggle(),
          if (visit.visible)
            SrIconButton(
              icon: Icons.insights_outlined,
              tooltip: l10n.ffReportTitle,
              onTap: () => context.push(Routes.visitReport),
            ),
          if (attendance.visible)
            SrIconButton(
              icon: Icons.calendar_month_outlined,
              tooltip: l10n.ffAttendanceTitle,
              onTap: () => context.push(Routes.attendance),
            ),
        ],
      ),
      body: FieldForceGate(
        module: AppModule.visit,
        child: _VisitsBody(onNew: _newVisit, showDuty: attendance.canView),
      ),
    );
  }
}

class _VisitsBody extends ConsumerWidget {
  const _VisitsBody({required this.onNew, required this.showDuty});

  final VoidCallback onNew;
  final bool showDuty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(visitsProvider);
    final notifier = ref.read(visitsProvider.notifier);
    final canAdd = ref.watch(
      moduleAccessProvider(AppModule.visit).select((a) => a.canAdd),
    );

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (note) {
          if (note.metrics.extentAfter < 300) notifier.loadMore();
          return false;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: SrScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            if (showDuty) ...[const DutyCard(), const SizedBox(height: 12)],
            switch (visits) {
              AsyncValue(:final value?) => _VisitsContent(
                visits: value,
                canAdd: canAdd,
                onNew: onNew,
              ),
              AsyncError(:final error) => SrErrorState(
                error: error,
                onRetry: () => ref.invalidate(visitsProvider),
              ),
              _ => const SrSkeletonList(
                count: 4,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _VisitsContent extends ConsumerWidget {
  const _VisitsContent({
    required this.visits,
    required this.canAdd,
    required this.onNew,
  });

  final Paged<Visit> visits;
  final bool canAdd;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final items = visits.items;
    final done = items.where((v) => v.isDone).length;
    final plan = RoutePlan.of(items);
    final slots = visitSlots(items);
    final loadMoreError = visits.loadMoreError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrStatGrid(
          tiles: [
            SrKpiTile(
              label: l10n.ffKpiVisitsToday,
              value: fmt.number(visits.totalCount),
            ),
            SrKpiTile(label: l10n.ffKpiDone, value: fmt.number(done)),
            SrKpiTile(label: l10n.ffKpiDistance, value: context.ffKm(plan.km)),
          ],
        ),
        const SizedBox(height: 12),
        SrButton(
          label: l10n.ffRouteMapButton,
          icon: Icons.map_outlined,
          variant: SrButtonVariant.secondary,
          expand: true,
          onPressed: items.isEmpty
              ? null
              : () => context.push(Routes.visitRoute),
        ),
        const SizedBox(height: 16),
        SrSectionHeader(
          title: l10n.ffVisitList,
          actionLabel: canAdd ? l10n.ffVisitNew : null,
          onAction: canAdd ? onNew : null,
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          SrCard(
            child: SrEmptyState(
              icon: Icons.route_outlined,
              title: l10n.ffVisitsEmptyTitle,
              message: l10n.ffVisitsEmptyBody,
              actionLabel: canAdd ? l10n.ffVisitNew : null,
              onAction: canAdd ? onNew : null,
            ),
          )
        else
          SrRowGroup(
            rows: [
              for (var i = 0; i < items.length; i++)
                VisitRow(
                  visit: items[i],
                  slot: slots[i],
                  onTap: () => context.push(
                    slots[i] == VisitSlot.next || slots[i] == VisitSlot.later
                        ? Routes.visitCheckInFor(items[i].id)
                        : Routes.visitFor(items[i].id),
                  ),
                ),
            ],
          ),
        if (visits.isLoadingMore) ...[
          const SizedBox(height: 12),
          const SrSkeletonRow(),
        ],
        if (loadMoreError != null)
          SrErrorState(
            error: loadMoreError,
            compact: true,
            onRetry: ref.read(visitsProvider.notifier).loadMore,
          ),
      ],
    );
  }
}
