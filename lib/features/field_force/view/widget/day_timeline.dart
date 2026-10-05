import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A day's events as a timeline.
class DayTimeline extends StatelessWidget {
  const DayTimeline({super.key, required this.events});

  final List<DayEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          DayEventItem(event: events[i], last: i == events.length - 1),
      ],
    );
  }
}

/// One check-in, visit or check-out on a timeline. A visit opens its
/// screen, or the Field Force upsell when the plan lacks it.
class DayEventItem extends ConsumerWidget {
  const DayEventItem({super.key, required this.event, this.last = false});

  final DayEvent event;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final time = fmt.time(event.time);
    final minutes = context.ffDuration(event.minutes ?? 0);
    final visitId = event.visitId;

    return switch (event.kind) {
      DayEventKind.checkIn => SrTimelineItem(
        icon: Icons.login_rounded,
        iconColor: c.accent,
        title: l10n.ffEventCheckIn(placeLabel(l10n, event.inOffice)),
        subtitle: event.detail,
        time: time,
        last: last,
      ),
      DayEventKind.visit => SrTimelineItem(
        icon: Icons.storefront_outlined,
        iconColor: c.accent,
        title: event.inProgress
            ? l10n.ffEventVisitOpen(event.title ?? '')
            : l10n.ffEventVisit(event.title ?? '', minutes),
        subtitle: event.detail,
        time: time,
        last: last,
        onTap: visitId == null
            ? null
            : () => openVisitRoute(context, ref, Routes.visitFor(visitId)),
      ),
      DayEventKind.checkOut => SrTimelineItem(
        icon: Icons.logout_rounded,
        title: l10n.ffEventCheckOut,
        time: time,
        last: last,
      ),
    };
  }
}
