import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/models/day_analytics.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/providers/tracking_providers.dart';
import 'package:salesroot/features/field_force/view/widget/day_timeline.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/features/field_force/view/widget/ff_language_toggle.dart';
import 'package:salesroot/features/field_force/view/widget/ff_map.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #128 memberday: one member's day on the map, with the visits, stops,
/// trips and pauses worked out from the trail.
class MemberDayScreen extends ConsumerStatefulWidget {
  const MemberDayScreen({super.key, required this.memberId, this.date});

  final String memberId;

  /// Opens on this day instead of today, as `?date=2026-10-01` does.
  final DateTime? date;

  @override
  ConsumerState<MemberDayScreen> createState() => _MemberDayScreenState();
}

class _MemberDayScreenState extends ConsumerState<MemberDayScreen> {
  String get memberId => widget.memberId;

  @override
  void initState() {
    super.initState();
    final date = widget.date;
    if (date != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(memberDayDateProvider(memberId).notifier).set(date);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final date = ref.watch(memberDayDateProvider(memberId));
    final day = ref.watch(memberDayProvider(memberId));
    final today = AppDateUtils.isSameDay(date, DateTime.now());
    final dayLabel = today
        ? l10n.ffTodayWeekday(fmt.weekdayDate(date))
        : fmt.weekdayDate(date);

    return SrScaffold(
      appBar: SrAppBar(
        title: switch (day.value?.name) {
          final name? when name.isNotEmpty => name,
          _ => l10n.ffMemberDayTitle,
        },
        subtitle: dayLabel,
        actions: [
          const FfLanguageToggle(),
          SrIconButton(
            icon: Icons.event_outlined,
            tooltip: l10n.ffPickDay,
            onTap: () async {
              final picked = await showSrDatePicker(
                context: context,
                initial: date,
                first: DateTime.now().subtract(const Duration(days: 90)),
                last: DateTime.now(),
              );
              if (picked != null) {
                ref.read(memberDayDateProvider(memberId).notifier).set(picked);
              }
            },
          ),
        ],
      ),
      body: FieldForceGate(
        module: AppModule.liveTracking,
        child: switch (day) {
          AsyncValue(:final value?) => RefreshIndicator(
            onRefresh: () => ref.refresh(memberDayProvider(memberId).future),
            child: _DayBody(day: value),
          ),
          AsyncError(:final error) => SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(memberDayProvider(memberId)),
          ),
          _ => const SrSkeletonList(count: 4, cards: true),
        },
      ),
    );
  }
}

class _DayBody extends ConsumerWidget {
  const _DayBody({required this.day});

  final MemberDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final analytics = DayAnalytics.from(day.points);
    final last = day.points.lastOrNull;
    final items = _timeline(day, analytics);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: SrScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        FfMap(
          height: 220,
          lines: [
            [for (final p in analytics.routePoints) (p.latitude, p.longitude)],
          ],
          pins: [
            for (final stop in analytics.stops)
              FfMapPin(
                id: 'stop${stop.start.millisecondsSinceEpoch}',
                latitude: stop.latitude,
                longitude: stop.longitude,
                title: l10n.ffStopFor(context.ffDuration(stop.minutes)),
                subtitle: fmt.time(stop.start),
                tone: FfPinTone.muted,
              ),
            if (last != null)
              FfMapPin(
                id: 'last',
                latitude: last.latitude,
                longitude: last.longitude,
                title: l10n.ffLastSeenHere,
                subtitle: switch (last.time) {
                  final time? => fmt.time(time),
                  _ => null,
                },
                tone: FfPinTone.me,
              ),
          ],
        ),
        const SizedBox(height: 12),
        SrStatGrid(
          tiles: [
            SrKpiTile(
              label: l10n.ffKpiVisits,
              value: fmt.number(day.visitCount),
            ),
            SrKpiTile(
              label: l10n.ffKpiDistance,
              value: context.ffKm(analytics.km),
            ),
            SrKpiTile(
              label: l10n.ffKpiMoving,
              value: context.ffClockDuration(analytics.movingMinutes),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          SrCard(
            child: SrEmptyState(
              icon: Icons.location_off_outlined,
              title: l10n.ffDayEmptyTitle,
              message: l10n.ffDayEmptyBody,
            ),
          )
        else
          SrCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  _TimelineEntry(entry: items[i], last: i == items.length - 1),
              ],
            ),
          ),
        if (analytics.lastBattery case final battery?) ...[
          const SizedBox(height: 12),
          SrNote(
            icon: Icons.battery_std_rounded,
            tone: SrNoteTone.neutral,
            message: l10n.ffLastBattery(fmt.percent(battery)),
          ),
        ],
      ],
    );
  }

  /// The day's events, plus trips and unplanned stops from the trail.
  List<_Entry> _timeline(MemberDay day, DayAnalytics analytics) {
    final entries = <_Entry>[
      for (final event in day.events) _Entry.event(event),
      for (final trip in analytics.trips) _Entry.trip(trip),
      for (final stop in analytics.stops)
        if (!day.events.any((e) => _overlaps(e, stop))) _Entry.stop(stop),
    ]..sort((a, b) => a.time.compareTo(b.time));
    return entries;
  }

  bool _overlaps(DayEvent event, DayStop stop) {
    final end = event.time.add(Duration(minutes: event.minutes ?? 30));
    return event.time.isBefore(stop.end) && end.isAfter(stop.start);
  }
}

class _Entry {
  _Entry.event(DayEvent this.event)
    : trip = null,
      stop = null,
      time = event.time;
  _Entry.trip(DayTrip this.trip) : event = null, stop = null, time = trip.start;
  _Entry.stop(DayStop this.stop) : event = null, trip = null, time = stop.start;

  final DayEvent? event;
  final DayTrip? trip;
  final DayStop? stop;
  final DateTime time;
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.entry, required this.last});

  final _Entry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = context.fmt.time(entry.time);
    final trip = entry.trip;
    final stop = entry.stop;
    final event = entry.event;

    if (trip != null) {
      return SrTimelineItem(
        icon: Icons.directions_car_outlined,
        title: l10n.ffTrip(
          context.ffKm(trip.km),
          context.ffDuration(trip.minutes),
        ),
        time: time,
        last: last,
      );
    }
    if (stop != null) {
      return SrTimelineItem(
        icon: Icons.local_parking_rounded,
        title: l10n.ffStopFor(context.ffDuration(stop.minutes)),
        subtitle: l10n.ffStopUnplanned,
        time: time,
        last: last,
      );
    }
    if (event == null) return const SizedBox.shrink();
    return DayEventItem(event: event, last: last);
  }
}
