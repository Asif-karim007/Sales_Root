import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/providers/tracker_providers.dart';
import 'package:salesroot/features/field_force/view/widget/duty_actions.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/minute_builder.dart';
import 'package:salesroot/features/field_force/view/widget/tracking_status_sheet.dart';
import 'package:salesroot/features/field_force/view/widget/worked_ring.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The visits screen's duty card: worked time, the attendance punch and
/// whether live tracking is on.
class DutyCard extends ConsumerWidget {
  const DutyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(attendanceTodayProvider);
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: switch (today) {
        AsyncValue(:final value?) => FfClockBuilder(
          builder: (context, now) => _DutyRow(today: value, now: now),
        ),
        AsyncError(:final error) => SrErrorState(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(attendanceTodayProvider),
        ),
        _ => const SrSkeletonRow(),
      },
    );
  }
}

class _DutyRow extends ConsumerWidget {
  const _DutyRow({required this.today, required this.now});

  final AttendanceToday today;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final log = today.log;
    final tracker = ref.watch(trackerProvider).value;
    final checkInAt = log?.checkInAt;
    final checkedOut = log?.isCheckedOut ?? false;

    return Row(
      children: [
        WorkedRing(minutes: log?.workedUntil(now) ?? 0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (checkInAt == null)
                SrTag(l10n.ffNotCheckedIn)
              else if (checkedOut)
                SrTag(l10n.ffDayDone, tone: SrTone.neutral)
              else
                SrTag(
                  l10n.ffCheckedInPlace(
                    context.fmt.time(checkInAt),
                    placeLabel(l10n, log?.inOffice),
                  ),
                  tone: SrTone.ok,
                ),
              const SizedBox(height: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showTrackingStatusSheet(context),
                child: Text(
                  l10n.ffDutyTrackingLine(trackingLabel(l10n, tracker)),
                  style: AppText.meta(c.ink2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (checkInAt == null)
          SrButton(
            label: l10n.ffCheckIn,
            size: SrButtonSize.sm,
            onPressed: () => dutyCheckIn(context, ref),
          )
        else if (!checkedOut)
          SrButton(
            label: l10n.ffCheckOut,
            size: SrButtonSize.sm,
            variant: SrButtonVariant.secondary,
            onPressed: () => dutyCheckOut(context, ref),
          ),
      ],
    );
  }
}
