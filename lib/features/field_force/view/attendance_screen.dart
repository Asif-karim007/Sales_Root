import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/view/widget/attendance_calendar.dart';
import 'package:salesroot/features/field_force/view/widget/day_timeline.dart';
import 'package:salesroot/features/field_force/view/widget/duty_actions.dart';
import 'package:salesroot/features/field_force/view/widget/ff_count_tile.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/features/field_force/view/widget/minute_builder.dart';
import 'package:salesroot/features/field_force/view/widget/worked_ring.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #131 attendance: today's punch with worked time, this month's counts,
/// this week and today's timeline.
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final today = ref.watch(attendanceTodayProvider);
    final value = today.value;
    final team = ref.watch(moduleAccessProvider(AppModule.teamAttendance));

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.ffAttendanceTitle,
        subtitle: value == null ? null : fmt.weekdayDate(value.date),
        actions: [
          const FfLanguageToggle(),
          if (team.visible)
            SrIconButton(
              icon: Icons.groups_outlined,
              tooltip: l10n.ffTeamTitle,
              onTap: () => context.push(Routes.attendanceTeam),
            ),
          SrIconButton(
            icon: Icons.calendar_month_outlined,
            tooltip: l10n.ffMonthCalendar,
            onTap: () => context.push(Routes.attendanceCalendar),
          ),
        ],
      ),
      body: FieldForceGate(
        module: AppModule.attendance,
        child: RefreshIndicator(
          onRefresh: () {
            ref
              ..invalidate(attendanceWeekProvider)
              ..invalidate(attendanceThisMonthProvider);
            return ref.refresh(attendanceTodayProvider.future);
          },
          child: switch (today) {
            AsyncValue(:final value?) => _AttendanceBody(today: value),
            AsyncError(:final error) => SrErrorState(
              error: error,
              onRetry: () => ref.invalidate(attendanceTodayProvider),
            ),
            _ => const SrSkeletonList(count: 4, cards: true),
          },
        ),
      ),
    );
  }
}

class _AttendanceBody extends ConsumerWidget {
  const _AttendanceBody({required this.today});

  final AttendanceToday today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final month = ref.watch(attendanceThisMonthProvider).value;
    final week = ref.watch(attendanceWeekProvider).value?.days;
    String count(int? n) => n == null ? '—' : fmt.number(n);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: SrScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _PunchCard(today: today),
        const SizedBox(height: 12),
        FfCountRow(
          tiles: [
            FfCountTile(
              value: count(month?.present),
              label: l10n.ffPresent,
              color: c.success,
            ),
            FfCountTile(
              value: count(month?.late),
              label: l10n.ffLate,
              color: c.gold,
            ),
            FfCountTile(
              value: count(month?.leave),
              label: l10n.ffLeave,
              color: c.ink2,
            ),
            FfCountTile(
              value: count(month?.absent),
              label: l10n.ffAbsent,
              color: c.danger,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SrCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              SrSectionHeader(
                title: l10n.ffThisWeek,
                actionLabel: l10n.ffMonthCalendar,
                onAction: () => context.push(Routes.attendanceCalendar),
              ),
              const SizedBox(height: 10),
              if (week == null)
                const SrSkeletonBox(height: 48, radius: 10)
              else
                AttendanceWeekStrip(days: week),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SrSectionHeader(title: l10n.ffToday),
        const SizedBox(height: 8),
        if (today.events.isEmpty)
          SrCard(
            child: Text(
              l10n.ffTodayEmpty,
              textAlign: TextAlign.center,
              style: AppText.meta(c.ink2),
            ),
          )
        else
          SrCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: DayTimeline(events: today.events),
          ),
      ],
    );
  }
}

class _PunchCard extends ConsumerWidget {
  const _PunchCard({required this.today});

  final AttendanceToday today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final log = today.log;
    final canPunch = ref.watch(
      moduleAccessProvider(
        AppModule.attendance,
      ).select((a) => a.allows(ModuleRight.add)),
    );
    final checkedIn = log?.isCheckedIn ?? false;

    return SrCard(
      padding: const EdgeInsets.all(16),
      child: FfClockBuilder(
        builder: (context, now) => Column(
          children: [
            _PunchSummary(today: today, now: now),
            if (canPunch && !(log?.isCheckedOut ?? false)) ...[
              const SizedBox(height: 14),
              if (checkedIn)
                SrButton(
                  label: l10n.ffCheckOut,
                  icon: Icons.logout_rounded,
                  expand: true,
                  onPressed: () => dutyCheckOut(context, ref),
                )
              else
                SrButton(
                  label: l10n.ffCheckIn,
                  icon: Icons.login_rounded,
                  expand: true,
                  onPressed: () => dutyCheckIn(context, ref),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PunchSummary extends StatelessWidget {
  const _PunchSummary({required this.today, required this.now});

  final AttendanceToday today;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final log = today.log;
    final checkInAt = log?.checkInAt;
    final checkOutAt = log?.checkOutAt;
    final place = checkInAt == null ? null : placeLabel(l10n, log?.inOffice);

    final (tag, tone) = checkOutAt != null
        ? (l10n.ffCheckedOutAt(fmt.time(checkOutAt)), SrTone.neutral)
        : checkInAt != null
        ? (l10n.ffCheckedInAt(fmt.time(checkInAt)), SrTone.ok)
        : (l10n.ffNotCheckedIn, SrTone.neutral);
    final line = checkInAt == null
        ? l10n.ffTodayEmpty
        : l10n.ffWorkedToday(context.ffDuration(log?.workedUntil(now) ?? 0));

    return Row(
      children: [
        WorkedRing(minutes: log?.workedUntil(now) ?? 0, size: 88),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SrTag(tag, tone: tone),
              if (place != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 16, color: c.accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place,
                        style: AppText.rowTitle(c.ink, size: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Text(line, style: AppText.meta(c.ink2, size: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
