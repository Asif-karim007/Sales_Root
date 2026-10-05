import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_info_line.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A finished visit at a glance.
class VisitSummary extends ConsumerWidget {
  const VisitSummary({super.key, required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final checkedIn = visit.startedAt;
    final checkedOut = visit.endedAt;
    final note = visit.note;
    final outcome = visit.outcome;
    final choices = ref.watch(visitOutcomesProvider).value ?? const [];
    final outcomeName = choices
        .where((choice) => choice.key == outcome)
        .firstOrNull
        ?.name
        .of(fmt.isBangla);
    final lines = <(String, String, Color?)>[
      if (visit.memberName case final member?) (l10n.ffVisitBy, member, null),
      if (checkedIn != null)
        (
          l10n.ffCheckedInLabel,
          fmt.time(checkedIn),
          visit.locationMismatch ? c.warning : null,
        ),
      if (checkedOut != null)
        (l10n.ffCheckedOutLabel, fmt.time(checkedOut), null),
      if (visit.durationMinutes case final minutes?)
        (l10n.ffDurationLabel, context.ffDuration(minutes), null),
      if (outcome != null) (l10n.ffOutcome, outcomeName ?? outcome, null),
      if (visit.photos.isNotEmpty)
        (l10n.ffPhotos, fmt.number(visit.photos.length), null),
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
        if (visit.locationMismatch) ...[
          const SizedBox(height: 12),
          SrNote(
            message: l10n.ffFarFlagged,
            tone: SrNoteTone.gold,
            icon: Icons.wrong_location_outlined,
          ),
        ],
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 12),
          SrCard(child: Text(note, style: AppText.body(c.ink, size: 14))),
        ],
      ],
    );
  }
}
