import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/field_force/data/fake_field_data.dart';
import 'package:salesroot/features/field_force/data/tracking_fixtures.dart';
import 'package:salesroot/features/field_force/data/visit_fixtures.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/models/day_analytics.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';

import 'field_force_harness.dart';

/// 15:00 on a working day a month back, when the seeded team is out.
DateTime _workingAfternoon() {
  var day = testAnchor();
  while (day.weekday == DateTime.friday) {
    day = day.subtract(const Duration(days: 1));
  }
  return DateTime(day.year, day.month, day.day, 15);
}

void main() {
  late ProviderContainer container;
  late FakeFieldData data;
  late DateTime afternoon;

  setUp(() async {
    afternoon = _workingAfternoon();
    container = await fieldForceContainer(
      role: WorkspaceRole.owner,
      anchor: afternoon,
    );
    data = FakeFieldData(container.read(fakeBackendProvider));
  });

  tearDown(() => container.dispose());

  test('a member who checked in has a trail through the visits', () {
    final member = fieldMembers(data.graph).firstWhere((m) {
      final points = data.trail(m.id, afternoon, afternoon);
      return points.length > 20 && data.visitsOf(m.id, afternoon).length > 1;
    });
    final points = [
      for (final row in data.trail(member.id, afternoon, afternoon))
        ?TrailPoint.fromJson(row),
    ];
    final analytics = DayAnalytics.from(points);
    expect(analytics.km, greaterThan(1));
    expect(analytics.movingMinutes, greaterThan(0));
    expect(analytics.routePoints.length, lessThan(points.length));
    expect(points.last.time?.isAfter(afternoon), isFalse);

    final events = dayEventsFromJson(
      data.events(member.id, afternoon, afternoon),
    );
    expect(events.first.kind, DayEventKind.checkIn);
    expect(events.where((e) => e.kind == DayEventKind.visit), isNotEmpty);
  });

  test('the live view knows who is on a visit, moving or silent', () {
    final live = [
      for (final member in fieldMembers(data.graph))
        LiveMember.fromJson(data.live(member, afternoon)),
    ];
    expect(live.where((m) => m.status.isLive), isNotEmpty);
    final silent = live.firstWhere((m) => m.memberId == notTrackingMemberId);
    expect(silent.status, LiveStatus.notTracking);
    expect(silent.lastSeenAt?.hour, 11);
    expect(silent.lastSeenMinutes, greaterThan(180));
    for (final member in live.where((m) => m.status.isLive)) {
      expect(member.latitude, isNotNull);
      expect(member.battery, inInclusiveRange(8, 100));
    }
  });

  test('statuses follow the seeded day', () {
    final statuses = {
      for (final member in fieldMembers(data.graph))
        member.id: data.statusOf(member.id, afternoon, afternoon),
    };
    expect(statuses[6], AttendanceStatus.absent);
    expect(statuses[8], AttendanceStatus.leave);
    expect(statuses[5], AttendanceStatus.late);
    expect(statuses[1], AttendanceStatus.present);
  });
}
