import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_info_line.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The label for a visit outcome.
String outcomeLabel(AppLocalizations l10n, VisitOutcome outcome) =>
    switch (outcome) {
      VisitOutcome.interested => l10n.ffOutcomeInterested,
      VisitOutcome.order => l10n.ffOutcomeOrder,
      VisitOutcome.comeBackLater => l10n.ffOutcomeLater,
      VisitOutcome.notInterested => l10n.ffOutcomeNotInterested,
      VisitOutcome.ignored => l10n.ffOutcomeIgnored,
    };

/// A planned, missed or finished visit at a glance.
class VisitSummary extends StatelessWidget {
  const VisitSummary({super.key, required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final planned = visit.plannedAt;
    final checkedIn = visit.start?.time;
    final checkedOut = visit.end?.time;
    final outcome = visit.outcome;
    final note = visit.note;
    final distance = visit.checkInDistance;
    final lines = <(String, String, Color?)>[
      if (planned != null) (l10n.ffPlanned, fmt.dayTime(planned), null),
      if (visit.purpose case final purpose?) (l10n.ffPurpose, purpose, null),
      if (checkedIn != null)
        (
          l10n.ffCheckedInLabel,
          [
            fmt.time(checkedIn),
            if (distance != null) l10n.ffAway(context.ffDistance(distance)),
          ].join(' · '),
          visit.isFarCheckIn ? c.warning : null,
        ),
      if (visit.farReason case final reason?) (l10n.ffFarReason, reason, null),
      if (checkedOut != null)
        (l10n.ffCheckedOutLabel, fmt.time(checkedOut), null),
      if (visit.durationMinutes case final minutes?)
        (l10n.ffDurationLabel, context.ffDuration(minutes), null),
      if (outcome != null) (l10n.ffOutcome, outcomeLabel(l10n, outcome), null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < lines.length; i++)
                FfInfoLine(
                  label: lines[i].$1,
                  value: lines[i].$2,
                  valueColor: lines[i].$3,
                  last: i == lines.length - 1,
                ),
            ],
          ),
        ),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 12),
          SrCard(child: Text(note, style: AppText.body(c.ink, size: 14))),
        ],
        if (visit.status == VisitStatus.missed) ...[
          const SizedBox(height: 12),
          SrNote(message: l10n.ffMissedNote, tone: SrNoteTone.err),
        ],
      ],
    );
  }
}
