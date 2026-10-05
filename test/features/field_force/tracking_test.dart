import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/field_force/data/api_tracking_repository.dart';
import 'package:salesroot/features/field_force/data/field_api.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/models/tracker_ping.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/providers/tracking_providers.dart';

import '../../helpers/api_stub.dart';
import 'field_force_harness.dart';

void main() {
  ApiTrackingRepository repositoryOver(ApiStub stub) =>
      ApiTrackingRepository(FieldApi(stubDio(stub)));

  group('pings', () {
    final ping = TrackerPing(
      latitude: 23.8368,
      longitude: 90.3698,
      locationTimeUtc: DateTime.utc(2026, 10, 5, 17, 4, 30, 250),
      createdAt: DateTime.utc(2026, 10, 5, 17, 4, 31),
      battery: 81,
      accuracy: 10,
      mock: true,
    );

    test('upload as LocationPoints in one batch', () async {
      final stub = fieldStub();

      final result = await repositoryOver(stub).uploadPings([ping, ping]);

      expect(result.accepted, 2);
      expect(result.rejected, 0);
      expect(sent(stub.last('POST', 'locations')), {
        'points': [
          for (var i = 0; i < 2; i++)
            {
              'at': '2026-10-05T17:04:30Z',
              'lat': 23.8368,
              'lng': 90.3698,
              'accuracy': 10.0,
              'battery': 81,
              'mock': true,
            },
        ],
      });
    });

    test('points the server did not store count as rejected', () async {
      final stub = fieldStub();
      final result = await repositoryOver(stub).uploadPings([ping, ping, ping]);
      expect(result.accepted, 2);
      expect(result.rejected, 1);
    });

    test('survive the tracker database round trip', () {
      final copy = TrackerPing.fromDb(ping.toDb());
      expect(copy.accuracy, 10);
      expect(copy.mock, isTrue);
      expect(copy.battery, 81);
      expect(copy.locationTimeUtc, DateTime.utc(2026, 10, 5, 17, 4, 30));
    });

    test('offline keeps the batch for later', () async {
      final stub = fieldStub()..offline = true;
      await expectLater(
        repositoryOver(stub).uploadPings([ping]),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('settings', () {
    test('the tracker runs at the workspace interval', () async {
      final config = await repositoryOver(fieldStub()).trackerConfig();
      expect(config.isEnabled, isTrue);
      expect(config.interval, const Duration(minutes: 10));
      expect(config.isInsideWindow(DateTime(2026, 10, 2, 23)), isTrue);
    });

    test('saving patches the field settings and reads them back', () async {
      final stub = fieldStub()..on('PATCH', 'field/settings', null);
      final container = await fieldContainer(stub, fullAccess: true);
      keepAlive(container, trackingSettingsProvider);
      final settings = await container.read(trackingSettingsProvider.future);

      await container
          .read(trackingSettingsProvider.notifier)
          .save(settings.copyWith(geofenceMetres: 300, selfieOnCheckIn: true));

      expect(sent(stub.last('PATCH', 'field/settings')), {
        'geofenceM': 300,
        'trackIntervalSec': 600,
        'selfieOnCheckIn': true,
      });
    });

    test('an executive may not save them', () async {
      final stub = fieldStub()
        ..on(
          'PATCH',
          'field/settings',
          fixture('field_team_map_forbidden'),
          status: 403,
        );
      await expectLater(
        repositoryOver(stub).saveSettings(const TrackingSettings()),
        throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
      );
    });
  });

  group('team', () {
    test('the live view reads today\'s attendance rows', () async {
      final container = await fieldContainer(fieldStub(), fullAccess: true);
      keepAlive(container, liveTeamProvider);

      final team = await container.read(liveTeamProvider.future);
      final rafi = team.single;
      expect(rafi.memberId, rafiId);
      expect(rafi.status, LiveStatus.checkedOut);
      expect(rafi.visits, 1);
      expect(rafi.lastSeenAt, isNotNull);
      expect(LiveFilter.offDuty.matches(rafi), isTrue);
      expect(LiveFilter.checkedIn.matches(rafi), isFalse);
    });

    test("a member's day needs the team map", () async {
      final stub = fieldStub();
      await expectLater(
        repositoryOver(stub).memberDay(rafiId, DateTime(2026, 10, 5)),
        throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
      );
      expect(stub.last('GET', 'team/map')?.queryParameters, {
        'membershipId': rafiId,
        'day': '2026-10-05',
      });
    });

    test("a member's day joins the punch, the visits and the trail", () async {
      final stub = fieldStub();
      final repository = repositoryOver(stub);
      final ping = TrackerPing(
        latitude: 23.8368,
        longitude: 90.3698,
        locationTimeUtc: DateTime.utc(2026, 10, 5, 17, 4, 30),
        createdAt: DateTime.utc(2026, 10, 5, 17, 4, 31),
        battery: 81,
      );
      await repository.uploadPings([ping]);
      stub.on(
        'GET',
        'team/map',
        (RequestOptions r) => sent(stub.last('POST', 'locations'))['points'],
      );

      final day = await repository.memberDay(rafiId, DateTime(2026, 10, 5));

      expect(day.name, 'Rafi Ahmed');
      expect(day.points.single.battery, 81);
      expect(day.events.map((e) => e.kind), [
        DayEventKind.checkIn,
        DayEventKind.visit,
        DayEventKind.checkOut,
      ]);
      expect(day.visitCount, 1);
    });
  });
}
