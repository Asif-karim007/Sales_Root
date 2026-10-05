import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/field_force/data/api_visit_repository.dart';
import 'package:salesroot/features/field_force/data/field_api.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';

import '../../helpers/api_stub.dart';
import 'field_force_harness.dart';

void main() {
  group('today', () {
    test('the open visit comes first, then the unvisited stops', () {
      final visit = Visit.fromJson(
        (fixtureMap('field_visits_open')['items'] as List).first
            as Map<String, dynamic>,
      );
      const stop = RouteStop(id: 's1', companyId: rahimId, name: 'Rahim');
      const visited = RouteStop(id: 's2', companyId: 'c2', name: 'Green');
      final done = Visit(
        id: 'v2',
        companyId: 'c2',
        startedAt: DateTime(2026, 10, 5, 10),
        endedAt: DateTime(2026, 10, 5, 10, 30),
      );

      final plan = dayPlan([visit, done], [stop, visited]);

      expect(plan.map((s) => s.key), ['v2', visitId, 'stop-s1']);
      expect(plan.map((s) => s.status), [
        VisitStatus.done,
        VisitStatus.inProgress,
        VisitStatus.planned,
      ]);
    });

    test('the plan follows attendance/today', () async {
      final container = await fieldContainer(fieldStub());
      keepAlive(container, todayPlanProvider);

      final plan = await container.read(todayPlanProvider.future);
      expect(plan.single.visit?.id, visitId);
      expect(plan.single.visit?.memberName, isNull);
    });
  });

  group('start and end', () {
    test('a check-in starts the visit at the fix and reads it back', () async {
      final stub = fieldStub();
      final container = await fieldContainer(stub, fullAccess: true);
      keepAlive(container, checkInProvider(rahimId));
      final state = await container.read(checkInProvider(rahimId).future);
      expect(state.target.companyName, 'Rahim Traders');
      expect(state.radius, 200);
      await container.read(checkInProvider(rahimId).notifier).locate();
      expect(container.read(checkInProvider(rahimId)).value?.distance, 0);

      final visit = await container
          .read(checkInProvider(rahimId).notifier)
          .submit(routeStopId: 'stop-1');

      expect(visit.id, visitId);
      expect(sent(stub.last('POST', 'visits/start')), {
        'companyId': rahimId,
        'routeStopId': 'stop-1',
        'lat': 23.8069,
        'lng': 90.3687,
      });
      expect(
        stub.last('GET', 'visits')?.queryParameters['membershipId'],
        rafiId,
      );
    });

    test('far from the customer the check-in is flagged', () async {
      final container = await fieldContainer(
        fieldStub(),
        location: StillLocation(23.8269, 90.3687),
      );
      keepAlive(container, checkInProvider(rahimId));
      await container.read(checkInProvider(rahimId).future);
      await container.read(checkInProvider(rahimId).notifier).locate();

      final state = container.read(checkInProvider(rahimId)).value;
      expect(state?.distance, greaterThan(2000));
      expect(state?.isFar, isTrue);
    });

    test('check-out uploads the photos and sends the outcome', () async {
      final stub = fieldStub();
      stub
        ..on('POST', 'visits/{id}/end', null)
        ..on('GET', 'visits', (RequestOptions r) {
          final end = stub.last('POST', 'visits/{id}/end');
          return {
            'items': [
              if (end == null)
                (fixtureMap('field_visits_open')['items'] as List).first
              else
                endedVisit(sent(end)),
            ],
            'total': 1,
            'offset': 0,
            'limit': 100,
          };
        });
      final container = await fieldContainer(stub);
      final detail = visitDetailProvider(visitId);
      keepAlive(container, detail);
      await container.read(detail.future);
      container.read(detail.notifier)
        ..addNote('Owner wants the new price list')
        ..addPhoto('test/fixtures/api/field_uploaded.json');

      final visit = await container
          .read(detail.notifier)
          .checkOut(outcome: 'stock_check', note: 'Next week');

      final key = fixtureMap('field_uploaded')['key'];
      expect(sent(stub.last('POST', 'visits/{id}/end')), {
        'outcome': 'stock_check',
        'note': 'Owner wants the new price list\nNext week',
        'lat': 23.8069,
        'lng': 90.3687,
        'photos': [key],
      });
      final upload = stub.last('POST', 'files')?.data as FormData;
      expect(
        {for (final f in upload.fields) f.key: f.value},
        {'entityType': 'visit', 'entityId': visitId},
      );
      expect(visit.isDone, isTrue);
      expect(visit.outcome, 'stock_check');
      expect(container.read(detail).value?.notes, isEmpty);
    });

    test('a visit nobody can find is not found', () async {
      final stub = fieldStub()
        ..on('GET', 'visits', {
          'items': <Object>[],
          'total': 0,
          'offset': 0,
          'limit': 100,
        });
      final container = await fieldContainer(stub);
      keepAlive(container, visitDetailProvider('missing'));

      await expectLater(
        container.read(visitDetailProvider('missing').future),
        throwsA(isA<ApiFailure>().having((f) => f.isNotFound, '404', true)),
      );
    });
  });

  group('lookups', () {
    test('outcomes come from the workspace pack', () async {
      final container = await fieldContainer(fieldStub());
      keepAlive(container, visitOutcomesProvider);

      final outcomes = await container.read(visitOutcomesProvider.future);
      expect(outcomes.first.key, 'order_taken');
      expect(outcomes.first.name.en, 'Order taken');
      expect(outcomes.first.productive, isTrue);
      expect(outcomes.map((o) => o.key), contains('stock_check'));
    });

    test('customers are searched by name, 20 at a time', () async {
      final stub = fieldStub();
      final repository = ApiVisitRepository(FieldApi(stubDio(stub)));

      final page = await repository.targets(' Rahim ', 2);

      expect(page.items.single.companyName, 'Rahim Traders');
      expect(stub.last('GET', 'companies')?.queryParameters, {
        'q': 'Rahim',
        'offset': 20,
        'limit': 20,
      });
    });

    test("a lead opens its customer's visit", () async {
      final stub = fieldStub()
        ..on('GET', 'leads/{id}', {'lead': fixtureMap('leads_detail')['lead']});
      final repository = ApiVisitRepository(FieldApi(stubDio(stub)));

      final target = await repository.leadTarget('lead-1');

      expect(target?.companyId, rahimId);
      expect(target?.leadTitle, '50 cartons soap · November');
      expect(target?.latitude, 23.8069);
    });
  });

  group('report', () {
    test('reads totals per person and lists far check-ins', () async {
      final far = {
        ...(fixtureMap('field_visits_open')['items'] as List).first
            as Map<String, dynamic>,
        'locationMismatch': true,
      };
      final stub = fieldStub()
        ..on('GET', 'visits', {
          'items': [far],
          'total': 1,
          'offset': 0,
          'limit': 100,
        });
      final repository = ApiVisitRepository(
        FieldApi(stubDio(stub)),
        clock: () => DateTime(2026, 10, 5),
      );

      final report = await repository.report(const VisitReportQuery());

      expect(report.from, DateTime(2026, 10, 3));
      expect(report.to, DateTime(2026, 10, 9));
      expect(report.visits, 1);
      expect(report.byMember.single.name, 'Rafi Ahmed');
      expect(report.farCheckIns.single.visitId, visitId);
      expect(
        stub.last('GET', 'reports/field')?.queryParameters['from'],
        '2026-10-03',
      );
    });

    test('members come from the workspace', () async {
      final repository = ApiVisitRepository(FieldApi(stubDio(fieldStub())));
      final members = await repository.members();
      expect(members, hasLength(3));
      expect(members.first.name, isNotEmpty);
    });
  });
}
