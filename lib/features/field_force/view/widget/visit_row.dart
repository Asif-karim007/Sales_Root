import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Where a stop stands on today's list.
enum VisitSlot { done, inProgress, next, later }

/// Slots for a day's stops in order: the first one still to visit is
/// "next", the rest "later".
List<VisitSlot> visitSlots(List<PlanStop> stops) {
  final slots = <VisitSlot>[];
  var nextTaken = false;
  for (final stop in stops) {
    slots.add(switch (stop.status) {
      VisitStatus.done => VisitSlot.done,
      VisitStatus.inProgress => VisitSlot.inProgress,
      VisitStatus.planned => nextTaken ? VisitSlot.later : VisitSlot.next,
    });
    if (stop.status == VisitStatus.planned) nextTaken = true;
  }
  return slots;
}

class VisitRow extends StatelessWidget {
  const VisitRow({
    super.key,
    required this.stop,
    required this.slot,
    required this.onTap,
  });

  final PlanStop stop;
  final VisitSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final time = stop.time;
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
    };
    return SrListRow(
      leading: SrAvatar(icon: icon, tone: tone),
      title: stop.title,
      subtitle: stop.area,
      onTap: onTap,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (time != null)
            Text(context.fmt.time(time), style: AppText.rowTitle(c.ink)),
          const SizedBox(height: 4),
          SrTag(tag, tone: tagTone),
        ],
      ),
    );
  }
}
