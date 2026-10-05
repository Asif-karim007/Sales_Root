import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/service/geo.dart';
import 'package:salesroot/features/field_force/service/route_plan.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/ff_map.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #121 routemap: today's stops on the map, and navigation through the
/// ones still to do.
class RouteMapScreen extends ConsumerWidget {
  const RouteMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plan = ref.watch(todayPlanProvider);
    final items = plan.value ?? const <PlanStop>[];
    final route = RoutePlan.of(items);
    final remaining = [
      for (final stop in items)
        if (!stop.isDone && stop.latitude != null && stop.longitude != null)
          stop,
    ];

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffRouteTitle,
        subtitle: plan.hasValue
            ? l10n.ffRouteSubtitle(
                context.fmt.number(items.length),
                context.ffKm(route.km),
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
        child: switch (plan) {
          AsyncValue(:final value?) when value.isEmpty => SrEmptyState(
            icon: Icons.route_outlined,
            title: l10n.ffVisitsEmptyTitle,
            message: l10n.ffVisitsEmptyBody,
          ),
          AsyncValue(:final value?) => _RouteBody(plan: RoutePlan.of(value)),
          AsyncError(:final error) => SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(attendanceTodayProvider),
          ),
          _ => const SrSkeletonList(count: 4),
        },
      ),
    );
  }

  Future<void> _navigate(BuildContext context, List<PlanStop> stops) async {
    String spot(PlanStop s) => '${s.latitude},${s.longitude}';
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

class _RouteBody extends StatelessWidget {
  const _RouteBody({required this.plan});

  final RoutePlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stops = plan.stops;
    final fmt = context.fmt;

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
                    id: stops[i].key,
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
          child: Column(
            children: [
              for (var i = 0; i < stops.length; i++)
                _StopRow(
                  index: i,
                  stop: stops[i],
                  leg: plan.legs[i],
                  last: i == stops.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SrNote(message: l10n.ffRouteMapsHint, icon: Icons.map_outlined),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.index,
    required this.stop,
    required this.leg,
    required this.last,
  });

  final int index;
  final PlanStop stop;
  final RouteLeg? leg;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final time = stop.time;
    final leg = this.leg;
    final meta = [
      if (time != null) fmt.time(time),
      if (stop.isDone)
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
            tone: index == 0 || stop.isDone
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
                  Text(stop.title, style: AppText.rowTitle(c.ink)),
                  Text(meta, style: AppText.meta(c.ink2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
