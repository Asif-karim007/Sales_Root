import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/service/geo.dart';
import 'package:salesroot/features/field_force/service/route_plan.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/ff_map.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #121 routemap: today's stops on the map, in an order the user can drag,
/// and navigation through the ones still to do.
class RouteMapScreen extends ConsumerWidget {
  const RouteMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final visits = ref.watch(visitsProvider);
    final items = visits.value?.items ?? const <Visit>[];
    final plan = RoutePlan.of(items);
    final remaining = [
      for (final visit in items)
        if (!visit.isDone &&
            visit.status != VisitStatus.missed &&
            visit.latitude != null &&
            visit.longitude != null)
          visit,
    ];

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffRouteTitle,
        subtitle: visits.hasValue
            ? l10n.ffRouteSubtitle(
                context.fmt.number(items.length),
                context.ffKm(plan.km),
              )
            : null,
        actions: const [FfLanguageToggle()],
      ),
      footer: SrButton(
        label: l10n.ffRouteNavigate,
        icon: Icons.navigation_outlined,
        expand: true,
        onPressed: remaining.isEmpty
            ? null
            : () => _navigate(context, remaining),
      ),
      body: FieldForceGate(
        module: AppModule.visit,
        child: switch (visits) {
          AsyncValue(:final value?) when value.items.isEmpty => SrEmptyState(
            icon: Icons.route_outlined,
            title: l10n.ffVisitsEmptyTitle,
            message: l10n.ffVisitsEmptyBody,
          ),
          AsyncValue(:final value?) => _RouteBody(
            plan: RoutePlan.of(value.items),
          ),
          AsyncError(:final error) => SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(visitsProvider),
          ),
          _ => const SrSkeletonList(count: 4),
        },
      ),
    );
  }

  Future<void> _navigate(BuildContext context, List<Visit> stops) async {
    String spot(Visit v) => '${v.latitude},${v.longitude}';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': spot(stops.last),
      if (stops.length > 1)
        'waypoints': stops.take(stops.length - 1).map(spot).join('|'),
      'travelmode': 'driving',
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showSrError(context, context.l10n.ffRouteNoMaps);
    }
  }
}

class _RouteBody extends ConsumerWidget {
  const _RouteBody({required this.plan});

  final RoutePlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stops = plan.stops;
    final fmt = context.fmt;

    Future<void> reorder(int from, int to) async {
      try {
        await ref.read(visitsProvider.notifier).move(from, to);
      } on ApiFailure catch (failure) {
        if (context.mounted) showSrError(context, failure.message);
      }
    }

    return ListView(
      physics: const SrScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        FfMap(
          height: 300,
          pins: [
            for (var i = 0; i < stops.length; i++)
              if (stops[i].latitude case final lat?)
                if (stops[i].longitude case final lng?)
                  FfMapPin(
                    id: 'visit${stops[i].id}',
                    latitude: lat,
                    longitude: lng,
                    title: '${fmt.number(i + 1)}. ${stops[i].title}',
                    tone: stops[i].isDone ? FfPinTone.muted : FfPinTone.accent,
                  ),
          ],
          lines: [
            [
              for (final stop in stops)
                if (stop.latitude case final lat?)
                  if (stop.longitude case final lng?) (lat, lng),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: stops.length,
            onReorderItem: reorder,
            itemBuilder: (context, i) => _StopRow(
              key: ValueKey(stops[i].id),
              index: i,
              visit: stops[i],
              leg: plan.legs[i],
              last: i == stops.length - 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SrNote(message: l10n.ffRouteHint, icon: Icons.drag_indicator_rounded),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    super.key,
    required this.index,
    required this.visit,
    required this.leg,
    required this.last,
  });

  final int index;
  final Visit visit;
  final RouteLeg? leg;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final planned = visit.plannedAt;
    final leg = this.leg;
    final meta = [
      if (planned != null) fmt.time(planned),
      if (visit.isDone)
        l10n.ffRouteDone
      else if (leg != null) ...[
        context.ffKm(leg.km),
        context.ffDuration(leg.minutes),
      ],
    ].join(' · ');

    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: c.surface,
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          SrAvatar(
            name: fmt.number(index + 1),
            size: 28,
            tone: index == 0 || visit.isDone
                ? SrAvatarTone.accent
                : SrAvatarTone.neutral,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(visit.title, style: AppText.rowTitle(c.ink)),
                  Text(meta, style: AppText.meta(c.ink2)),
                ],
              ),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.drag_indicator_rounded, color: c.ink3),
            ),
          ),
        ],
      ),
    );
  }
}
