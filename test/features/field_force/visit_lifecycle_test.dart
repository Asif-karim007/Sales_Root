import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/field_force/data/visit_fixtures.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/providers/visit_providers.dart';

import 'field_force_harness.dart';

void main() {
  late ProviderContainer container;
  late StillLocation phone;

  setUp(() async {
    phone = StillLocation(0, 0);
    container = await fieldForceContainer(location: phone);
    keepAlive(container, visitsProvider);
  });

  tearDown(() => container.dispose());

  Future<Visit> plan(int leadId) => container
      .read(visitsProvider.notifier)
      .create(VisitInput(leadId: leadId, purpose: 'Show samples'));

  /// Stands [metres] north of the visit's customer.
  void standNear(Visit visit, double metres) {
    final (lat, lng) = offsetBy(
      visit.latitude ?? 0,
      visit.longitude ?? 0,
      metres,
      0,
    );
    phone
      ..latitude = lat
      ..longitude = lng;
  }

  Future<CheckInState> located(int visitId) async {
    keepAlive(container, checkInProvider(visitId));
    await container.read(checkInProvider(visitId).future);
    await container.read(checkInProvider(visitId).notifier).locate();
    return container.read(checkInProvider(visitId)).requireValue;
  }

  test('a planned visit shows on today\'s list', () async {
    final visit = await plan(5);
    final today = await container.read(visitsProvider.future);
    expect(today.items.map((v) => v.id), contains(visit.id));
    expect(visit.status, VisitStatus.planned);
    expect(visit.purpose, 'Show samples');
  });

  test('check-in near the customer, then check-out with no outcome is '
      'stored as Ignored', () async {
    final visit = await plan(5);
    standNear(visit, 25);
    final state = await located(visit.id);
    expect(state.distance, closeTo(25, 2));
    expect(state.isFar, isFalse);

    final checkedIn = await container
        .read(checkInProvider(visit.id).notifier)
        .submit();
    expect(checkedIn.status, VisitStatus.inProgress);
    expect(checkedIn.isFarCheckIn, isFalse);
    expect(checkedIn.checkInDistance, closeTo(25, 2));

    keepAlive(container, visitDetailProvider(visit.id));
    await container.read(visitDetailProvider(visit.id).future);
    final ended = await container
        .read(visitDetailProvider(visit.id).notifier)
        .checkOut(note: '  ');
    expect(ended.status, VisitStatus.done);
    expect(ended.outcome, VisitOutcome.ignored);
    expect(ended.note, isNull);
    expect(ended.durationMinutes, isNotNull);
  });

  test('a blank outcome goes on the wire as "Ignored"', () {
    expect(const VisitEndInput().toJson()['Outcome'], 'Ignored');
    expect(
      const VisitEndInput(outcome: VisitOutcome.order).toJson()['Outcome'],
      'Order',
    );
  });

  test('a far check-in needs a reason and a photo, and is flagged', () async {
    final visit = await plan(7);
    standNear(visit, 850);
    final state = await located(visit.id);
    expect(state.isFar, isTrue);
    final notifier = container.read(checkInProvider(visit.id).notifier);

    await expectLater(
      notifier.submit(),
      throwsA(isA<ApiFailure>().having((f) => f.isValidation, 'is 400', true)),
    );

    notifier.setPhoto('/tmp/site.jpg');
    final checkedIn = await notifier.submit(reason: 'Met at their warehouse');
    expect(checkedIn.isFarCheckIn, isTrue);
    expect(checkedIn.farReason, 'Met at their warehouse');
    expect(checkedIn.photos.single.path, '/tmp/site.jpg');
  });

  test('only one visit can be open at a time', () async {
    final first = await plan(5);
    final second = await plan(6);
    standNear(first, 10);
    await located(first.id);
    await container.read(checkInProvider(first.id).notifier).submit();

    standNear(second, 10);
    await located(second.id);
    await expectLater(
      container.read(checkInProvider(second.id).notifier).submit(),
      throwsA(isA<ApiFailure>().having((f) => f.isConflict, 'is 409', true)),
    );
  });

  test('a photo past the storage limit is a quota failure', () async {
    final visit = await plan(5);
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(quotaReached: true));
    await expectLater(
      container.read(visitRepositoryProvider).addPhoto(visit.id, '/tmp/a.jpg'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.isQuota, '402', true)
            .having((f) => f.quota, 'quota', QuotaKind.storage),
      ),
    );
  });

  test('a visit needs a lead', () async {
    await expectLater(
      container.read(visitsProvider.notifier).create(const VisitInput()),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.fieldError('LeadId'),
          'field',
          isNotNull,
        ),
      ),
    );
  });

  test('offline shows as a failure with status 0', () async {
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: true));
    await expectLater(
      container.read(visitsProvider.future),
      throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
    );
  });

  test('targets page 20 at a time over every open lead', () async {
    final repository = container.read(visitRepositoryProvider);
    final first = await repository.targets('', 1);
    final second = await repository.targets('', 2);
    expect(first.items, hasLength(20));
    expect(second.items, hasLength(20));
    expect(first.totalCount, greaterThan(40));
    expect(
      first.items
          .map((t) => t.leadId)
          .toSet()
          .intersection(second.items.map((t) => t.leadId).toSet()),
      isEmpty,
    );
  });
}
