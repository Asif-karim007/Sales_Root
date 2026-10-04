import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
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
        subtitle: value == null
            ? null
            : l10n.ffAttendanceSubtitle(
                fmt.weekdayDate(value.date),
                context.ffWindow(value.shiftStart, value.shiftEnd),
              ),
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
          onRefresh: () => ref.refresh(attendanceTodayProvider.future),
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
    final month = today.month;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: SrScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _PunchCard(today: today),
        const SizedBox(height: 12),
        FfCountRow(
          tiles: [
            FfCountTile(
              value: fmt.number(month.present),
              label: l10n.ffPresent,
              color: c.success,
            ),
            FfCountTile(
              value: fmt.number(month.late),
              label: l10n.ffLate,
              color: c.gold,
            ),
            FfCountTile(
              value: fmt.number(month.leave),
              label: l10n.ffLeave,
              color: c.ink2,
            ),
            FfCountTile(
              value: fmt.number(month.absent),
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
              AttendanceWeekStrip(days: today.week),
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

class _PunchCard extends ConsumerStatefulWidget {
  const _PunchCard({required this.today});

  final AttendanceToday today;

  @override
  ConsumerState<_PunchCard> createState() => _PunchCardState();
}

class _PunchCardState extends ConsumerState<_PunchCard> {
  bool _busy = false;

  Future<void> _toggleBreak() async {
    setState(() => _busy = true);
    try {
      await ref.read(attendanceTodayProvider.notifier).toggleBreak();
    } on ApiFailure catch (failure) {
      if (mounted) showSrError(context, failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = widget.today;
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
              Row(
                children: [
                  Expanded(
                    child: checkedIn
                        ? SrButton(
                            label: l10n.ffCheckOut,
                            icon: Icons.logout_rounded,
                            expand: true,
                            onPressed: () => dutyCheckOut(context, ref),
                          )
                        : SrButton(
                            label: l10n.ffCheckIn,
                            icon: Icons.login_rounded,
                            expand: true,
                            onPressed: () => dutyCheckIn(context, ref),
                          ),
                  ),
                  if (checkedIn) ...[
                    const SizedBox(width: 8),
                    SrButton(
                      label: log?.onBreak ?? false
                          ? l10n.ffEndBreak
                          : l10n.ffBreak,
                      variant: SrButtonVariant.secondary,
                      loading: _busy,
                      onPressed: _busy ? null : _toggleBreak,
                    ),
                  ],
                ],
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
    final start = clockOn(today.date, today.shiftStart);
    final end = today.shiftEndsAt;
    final left = end.difference(now).inMinutes;
    final place = log?.checkInPlace?.location;

    final (tag, tone) = checkOutAt != null
        ? (l10n.ffCheckedOutAt(fmt.time(checkOutAt)), SrTone.neutral)
        : checkInAt != null
        ? (l10n.ffCheckedInAt(fmt.time(checkInAt)), SrTone.ok)
        : (l10n.ffNotCheckedIn, SrTone.neutral);
    final line = checkOutAt != null
        ? l10n.ffWorkedToday(context.ffDuration(log?.workedUntil(now) ?? 0))
        : checkInAt == null
        ? l10n.ffShiftStarts(fmt.time(start))
        : left > 0
        ? l10n.ffShiftEndsIn(fmt.time(end), context.ffDuration(left))
        : l10n.ffShiftOver(fmt.time(end));

    return Row(
      children: [
        WorkedRing(
          minutes: log?.workedUntil(now) ?? 0,
          shiftMinutes: end.difference(start).inMinutes,
          size: 88,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SrTag(tag, tone: tone),
              if (log?.onBreak ?? false) ...[
                const SizedBox(height: 6),
                SrTag(
                  l10n.ffOnBreak,
                  tone: SrTone.gold,
                  icon: Icons.coffee_outlined,
                ),
              ],
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
