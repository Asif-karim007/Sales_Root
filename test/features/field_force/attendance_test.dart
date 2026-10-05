import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/field_force/data/api_attendance_repository.dart';
import 'package:salesroot/features/field_force/data/field_api.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/providers/attendance_providers.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';

import '../../helpers/api_stub.dart';
import 'field_force_harness.dart';

void main() {
  group('today', () {
    test('before check-in there is no punch and no visit', () async {
      final stub = fieldStub()
        ..on('GET', 'attendance/today', fixture('field_today_empty'));
      final container = await fieldContainer(stub);

      final today = await container.read(attendanceTodayProvider.future);
      expect(today.date, DateTime(2026, 10, 5));
      expect(today.log, isNull);
      expect(today.visits, isEmpty);
      expect(today.stops, isEmpty);
      expect(today.settings.geofenceMetres, 200);
      expect(today.settings.trackIntervalSeconds, 600);
      expect(today.settings.selfieOnCheckIn, isFalse);
      expect(today.events, isEmpty);
    });

    test('a checked-in day on a visit reads its punch and the visit', () async {
      final container = await fieldContainer(fieldStub());

      final today = await container.read(attendanceTodayProvider.future);
      final log = today.log;
      expect(log?.isCheckedIn, isTrue);
      expect(log?.status, AttendanceStatus.late);
      expect(log?.inOffice, isFalse);
      expect(log?.checkInAt?.isUtc, isFalse);
      expect(today.visits.single.id, visitId);
      expect(today.visits.single.isOpen, isTrue);
      expect(today.events.map((e) => e.kind), [
        DayEventKind.checkIn,
        DayEventKind.visit,
      ]);
    });

    test('a checked-out day is a half day with both punches', () async {
      final stub = fieldStub()
        ..on('GET', 'attendance/today', fixture('field_today_checked_out'));
      final container = await fieldContainer(stub);

      final log = (await container.read(attendanceTodayProvider.future)).log;
      expect(log?.isCheckedOut, isTrue);
      expect(log?.status, AttendanceStatus.halfDay);
      expect(log?.distanceKm, closeTo(10045.19, 0.001));
    });
  });

  group('check-in and check-out', () {
    test('check-in sends the fix and reloads the day', () async {
      final stub = fieldStub();
      final container = await fieldContainer(stub);
      keepAlive(container, attendanceTodayProvider);
      await container.read(attendanceTodayProvider.future);

      final log = await container
          .read(attendanceTodayProvider.notifier)
          .checkIn();

      expect(log.status, AttendanceStatus.late);
      expect(log.checkInAt, isNotNull);
      final body = sent(stub.last('POST', 'attendance/check-in'));
      expect(body, {
        'lat': 23.8069,
        'lng': 90.3687,
        'accuracy': 12.0,
        'mock': false,
      });
      await container.read(attendanceTodayProvider.future);
      expect(
        stub.requests.where((r) => r.path.endsWith('attendance/today')),
        hasLength(2),
      );
    });

    test('a selfie is uploaded first and sent as the photo key', () async {
      final stub = fieldStub();
      final repository = ApiAttendanceRepository(
        FieldApi(stubDio(stub)),
        me: rafiId,
      );

      final key = await repository.uploadSelfie(
        'test/fixtures/api/field_uploaded.json',
      );
      await repository.checkIn(
        AttendancePunch(
          latitude: 23.8,
          longitude: 90.4,
          accuracy: 10,
          photoKey: key,
        ),
      );

      final upload = stub.last('POST', 'files')?.data as FormData;
      expect(
        {for (final f in upload.fields) f.key: f.value},
        {'entityType': 'attendance', 'entityId': rafiId},
      );
      expect(
        sent(stub.last('POST', 'attendance/check-in'))['photoKey'],
        fixtureMap('field_uploaded')['key'],
      );
    });

    test('check-in without a fix never reaches the server', () async {
      final stub = fieldStub();
      final container = await fieldContainer(
        stub,
        location: StillLocation(0, 0, fails: true),
      );
      keepAlive(container, attendanceTodayProvider);

      await expectLater(
        container.read(attendanceTodayProvider.notifier).checkIn(),
        throwsA(isA<LocationFailure>()),
      );
      expect(stub.last('POST', 'attendance/check-in'), isNull);
    });

    test('a reason the server asks for comes back as a field error', () async {
      final asked = fixtureMap('field_checked_in');
      final stub = fieldStub()
        ..on(
          'POST',
          'attendance/check-in',
          (RequestOptions r) => sent(r).containsKey('reason')
              ? asked
              : const StubReply(422, {
                  'code': 'V-001',
                  'message': {'en': 'Reason needed', 'bn': 'Reason needed'},
                  'field': 'reason',
                }),
        );
      final container = await fieldContainer(stub);
      keepAlive(container, attendanceTodayProvider);

      await expectLater(
        container.read(attendanceTodayProvider.notifier).checkIn(),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.isValidation, 'validation', isTrue)
              .having((f) => f.fieldErrors.keys, 'fields', ['reason']),
        ),
      );

      await container
          .read(attendanceTodayProvider.notifier)
          .checkIn(reason: 'At the Savar depot');
      expect(
        sent(stub.last('POST', 'attendance/check-in'))['reason'],
        'At the Savar depot',
      );
    });

    test('check-out sends the fix and returns the server time', () async {
      final stub = fieldStub();
      final container = await fieldContainer(stub);
      keepAlive(container, attendanceTodayProvider);

      final log = await container
          .read(attendanceTodayProvider.notifier)
          .checkOut();

      expect(log.checkOutAt, isNotNull);
      expect(sent(stub.last('POST', 'attendance/check-out')), {
        'lat': 23.8069,
        'lng': 90.3687,
        'manual': false,
      });
    });

    test('check-out offline fails as status 0', () async {
      final stub = fieldStub();
      final container = await fieldContainer(stub);
      keepAlive(container, attendanceTodayProvider);
      stub.offline = true;

      await expectLater(
        container.read(attendanceTodayProvider.notifier).checkOut(),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('days', () {
    test('a week of the report gets each day a status', () async {
      final stub = fieldStub();
      final repository = ApiAttendanceRepository(
        FieldApi(stubDio(stub)),
        me: rafiId,
        clock: () => DateTime(2026, 10, 5, 18),
      );

      final week = await repository.days(
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 7),
      );

      expect(week.days.map((d) => d.status), [
        AttendanceStatus.none,
        AttendanceStatus.off,
        AttendanceStatus.off,
        AttendanceStatus.none,
        AttendanceStatus.leave,
        AttendanceStatus.upcoming,
        AttendanceStatus.upcoming,
      ]);
      expect(week.summary.workingDays, 3);
      expect(week.summary.leave, 1);
      final query = stub.last('GET', 'reports/field')?.queryParameters;
      expect(query, {
        'from': '2026-10-01',
        'to': '2026-10-07',
        'group': 'day',
        'ownerId': rafiId,
      });
    });

    test('this month asks for the calendar month', () async {
      final stub = fieldStub();
      final container = await fieldContainer(stub);
      keepAlive(container, attendanceMonthProvider);

      final month = await container.read(attendanceMonthProvider.future);
      final now = DateTime.now();
      expect(month.from, DateTime(now.year, now.month));
      expect(month.days, hasLength(DateTime(now.year, now.month + 1, 0).day));
      expect(
        stub.last('GET', 'reports/field')?.queryParameters['ownerId'],
        rafiId,
      );
    });
  });

  group('team', () {
    test('today lists each member with their punch', () async {
      final stub = fieldStub();
      final container = await fieldContainer(stub, fullAccess: true);
      keepAlive(container, teamAttendanceProvider);

      final team = await container.read(teamAttendanceProvider.future);
      final rafi = team.rows.single;
      expect(rafi.memberId, rafiId);
      expect(rafi.name, 'Rafi Ahmed');
      expect(rafi.status, AttendanceStatus.halfDay);
      expect(rafi.inOffice, isFalse);
      expect(team.summary.present, 1);
      expect(stub.last('GET', 'attendance')?.queryParameters.keys, ['day']);
    });

    test('a week reads the report per person', () async {
      final stub = fieldStub();
      final container = await fieldContainer(stub, fullAccess: true);
      keepAlive(container, teamAttendanceProvider);
      container
          .read(teamAttendancePeriodProvider.notifier)
          .set(TeamPeriod.week);

      final team = await container.read(teamAttendanceProvider.future);
      expect(team.rows.single.summary, isNotNull);
      expect(team.summary.leave, 1);
      expect(
        stub.last('GET', 'reports/field')?.queryParameters['ownerId'],
        isNull,
      );
    });

    test('the monthly download reads the period summary', () async {
      final stub = fieldStub();
      final container = await fieldContainer(stub, fullAccess: true);

      final rows = await container
          .read(attendanceRepositoryProvider)
          .teamMonth(DateTime(2026, 10));

      expect(rows.single.present, 1);
      expect(rows.single.halfDays, 1);
      expect(
        stub.last('GET', 'attendance')?.queryParameters['period'],
        '2026-10',
      );
    });

    test('a 403 shows as forbidden', () async {
      final stub = fieldStub()
        ..on(
          'GET',
          'attendance',
          fixture('field_team_map_forbidden'),
          status: 403,
        );
      final container = await fieldContainer(stub);
      keepAlive(container, teamAttendanceProvider);

      await expectLater(
        container.read(teamAttendanceProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
      );
    });
  });
}
