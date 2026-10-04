import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Where a visit stands on today's list.
enum VisitSlot { done, inProgress, next, later, missed }

/// Slots for a day's visits in route order: the first one still to do is
/// "next", the rest "later".
List<VisitSlot> visitSlots(List<Visit> visits) {
  final slots = <VisitSlot>[];
  var nextTaken = false;
  for (final visit in visits) {
    slots.add(switch (visit.status) {
      VisitStatus.done => VisitSlot.done,
      VisitStatus.inProgress => VisitSlot.inProgress,
      VisitStatus.missed => VisitSlot.missed,
      VisitStatus.planned => nextTaken ? VisitSlot.later : VisitSlot.next,
    });
    if (visit.status == VisitStatus.planned) nextTaken = true;
  }
  return slots;
}

class VisitRow extends StatelessWidget {
  const VisitRow({
    super.key,
    required this.visit,
    required this.slot,
    required this.onTap,
  });

  final Visit visit;
  final VisitSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final bangla = context.fmt.isBangla;
    final planned = visit.plannedAt;
    final (icon, tone, tag, tagTone) = switch (slot) {
      VisitSlot.done => (
        Icons.check_rounded,
        SrAvatarTone.accent,
        l10n.ffSlotDone,
        SrTone.ok,
      ),
      VisitSlot.inProgress => (
        Icons.timelapse_rounded,
        SrAvatarTone.gold,
        l10n.ffSlotInProgress,
        SrTone.gold,
      ),
      VisitSlot.next => (
        Icons.near_me_outlined,
        SrAvatarTone.accent,
        l10n.ffSlotNext,
        SrTone.accent,
      ),
      VisitSlot.later => (
        Icons.place_outlined,
        SrAvatarTone.neutral,
        l10n.ffSlotLater,
        SrTone.neutral,
      ),
      VisitSlot.missed => (
        Icons.event_busy_outlined,
        SrAvatarTone.danger,
        l10n.ffSlotMissed,
        SrTone.err,
      ),
    };
    final subtitle = [?visit.area?.of(bangla), ?visit.purpose].join(' · ');

    return SrListRow(
      leading: SrAvatar(icon: icon, tone: tone),
      title: visit.title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (planned != null)
            Text(context.fmt.time(planned), style: AppText.rowTitle(c.ink)),
          const SizedBox(height: 4),
          SrTag(tag, tone: tagTone),
        ],
      ),
    );
  }
}
