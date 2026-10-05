import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';

import '../../helpers/api_stub.dart';
import 'lead_stub.dart';

/// The recorded detail with the lead moved to [stageId] and [status].
Map<String, dynamic> _detailAt(String stageId, {String status = 'open'}) {
  final detail = fixtureMap('leads_detail');
  return {
    ...detail,
    'lead': {
      ...detail['lead'] as Map<String, dynamic>,
      'stageId': stageId,
      'status': status,
    },
  };
}

/// Keeps the screen providers alive between reads, as a mounted screen would.
void _keep(ProviderContainer container) {
  container
    ..listen(leadListProvider, (_, _) {})
    ..listen(leadSaveProvider('form'), (_, _) {})
    ..listen(leadSaveProvider('quick'), (_, _) {})
    ..listen(leadActivitySaveProvider('call'), (_, _) {});
}

void main() {
  group('lead list', () {
    test('loads 20 a time and asks for the next offset', () async {
      final stub = leadStub(total: 45);
      final container = await leadContainer(stub);
      _keep(container);
      final list = container.read(leadListProvider.notifier);

      var paged = await container.read(leadListProvider.future);
      expect(paged.items, hasLength(20));
      expect(paged.hasMore, isTrue);

      while (paged.hasMore) {
        await list.loadMore();
        paged = container.read(leadListProvider).value ?? paged;
      }
      expect(paged.items, hasLength(45));
      expect(paged.items.map((l) => l.id).toSet(), hasLength(45));
      expect(stub.last('GET', 'leads')?.queryParameters['offset'], 40);
    });

    test('a filter change reloads from the first page', () async {
      final stub = leadStub(total: 45);
      final container = await leadContainer(stub, role: 'owner');
      _keep(container);
      await container.read(leadListProvider.future);
      await container.read(leadListProvider.notifier).loadMore();

      container
          .read(leadFilterProvider.notifier)
          .apply(
            const LeadFilter(
              mine: false,
              stageId: visitedStage,
              temperature: LeadTemperature.warm,
            ),
          );
      await container.read(leadListProvider.future);
      final query = stub.last('GET', 'leads')?.queryParameters;
      expect(query?['offset'], 0);
      expect(query?['scope'], 'all');
      expect(query?['stageId'], visitedStage);
      expect(query?['temperature'], 'warm');
      expect(query?.containsKey('status'), isFalse);
    });

    test('a failed next page keeps the rows and offers a retry', () async {
      final stub = leadStub(total: 45);
      final container = await leadContainer(stub);
      _keep(container);
      await container.read(leadListProvider.future);

      stub.offline = true;
      await container.read(leadListProvider.notifier).loadMore();
      final paged = container.read(leadListProvider).value;
      expect(paged?.items, hasLength(20));
      expect(paged?.loadMoreError?.isOffline, isTrue);
    });

    test('offline shows the offline failure', () async {
      final stub = leadStub();
      final container = await leadContainer(stub);
      _keep(container);
      stub.offline = true;

      await expectLater(
        container.read(leadListProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('stage moves', () {
    test('a move lands in the list, and undo puts it back', () async {
      final stub = leadStub();
      stub.on('POST', 'leads/{id}/stage', (RequestOptions r) {
        final body = r.data as Map<String, dynamic>;
        stub.on('GET', 'leads/{id}', _detailAt('${body['stageId']}'));
        return const <String, dynamic>{};
      });
      final container = await leadContainer(stub);
      _keep(container);
      final lead = (await container.read(
        leadListProvider.future,
      )).items.firstWhere((l) => l.id == rahimId);
      final stages = await container.read(leadStagesProvider.future);
      final actions = container.read(leadActionsProvider.notifier);

      await actions.moveStage(
        lead,
        LeadStageInput(stage: stages.byId(visitedStage) ?? stages.first),
        LeadSurface.list,
      );
      final moved = container.read(leadActionsProvider);
      expect(moved, isA<LeadMoved>());
      expect(
        container
            .read(leadListProvider)
            .value
            ?.items
            .firstWhere((l) => l.id == rahimId)
            .stage
            ?.id,
        visitedStage,
      );

      await actions.undoMove((moved as LeadMoved).move, LeadSurface.list);
      expect(container.read(leadActionsProvider), isA<LeadMoveUndone>());
      expect(stub.lastBody('POST', 'leads/{id}/stage'), {
        'stageId': sampleStage,
      });
    });

    test('a required field the server asks for fails the move', () async {
      final stub = leadStub()
        ..on(
          'POST',
          'leads/{id}/stage',
          (RequestOptions r) =>
              StubReply(422, fixture('leads_stage_required_error')),
        );
      final container = await leadContainer(stub);
      _keep(container);
      final lead = await container.read(leadProvider(rahimId).future);
      final stages = await container.read(leadStagesProvider.future);

      await container
          .read(leadActionsProvider.notifier)
          .moveStage(
            lead,
            LeadStageInput(stage: stages.byId(toContactStage) ?? stages.first),
            LeadSurface.detail,
          );
      final event = container.read(leadActionsProvider);
      expect(event, isA<LeadActionFailed>());
      expect(
        (event as LeadActionFailed).failure.fieldError('productInterest'),
        isNotNull,
      );
    });
  });

  group('delete', () {
    test('a delete drops the lead, and undo restores it', () async {
      final stub = leadStub()
        ..on('DELETE', 'leads/{id}', null)
        ..on('POST', 'leads/{id}/restore', fixtureMap('leads_detail')['lead']);
      final container = await leadContainer(stub, role: 'owner');
      _keep(container);
      final lead = (await container.read(
        leadListProvider.future,
      )).items.firstWhere((l) => l.id == rahimId);
      final actions = container.read(leadActionsProvider.notifier);

      await actions.delete(lead, LeadSurface.list);
      expect(container.read(leadActionsProvider), isA<LeadDeleted>());
      expect(
        container.read(leadListProvider).value?.items.map((l) => l.id),
        isNot(contains(rahimId)),
      );

      await actions.restore(lead, LeadSurface.list);
      expect(container.read(leadActionsProvider), isA<LeadRestored>());
      expect(
        (await container.read(leadListProvider.future)).items.map((l) => l.id),
        contains(rahimId),
      );
    });

    test('a 403 shows as a failed action', () async {
      final stub = leadStub()
        ..fail('DELETE', 'leads/{id}', 403, message: 'Ask your manager');
      final container = await leadContainer(stub);
      _keep(container);
      final lead = await container.read(leadProvider(rahimId).future);

      await container
          .read(leadActionsProvider.notifier)
          .delete(lead, LeadSurface.detail);
      final event = container.read(leadActionsProvider);
      expect(event, isA<LeadActionFailed>());
      expect((event as LeadActionFailed).failure.isForbidden, isTrue);
    });
  });

  group('saving', () {
    test('a duplicate phone surfaces the existing lead', () async {
      final stub = leadStub()
        ..on(
          'POST',
          'leads',
          (RequestOptions r) =>
              StubReply(422, fixture('leads_duplicate_error')),
        );
      final container = await leadContainer(stub);
      _keep(container);
      final save = container.read(leadSaveProvider('form').notifier);

      await save.create(
        const LeadInput(leadName: 'Rahim', phone: '01811000010'),
      );
      final error = container.read(leadSaveProvider('form')).error;
      expect(error, isA<LeadDuplicateFailure>());
      expect((error as LeadDuplicateFailure).existing.id, rahimId);
    });

    test('a quota answer is kept for the upgrade sheet', () async {
      final stub = leadStub()..fail('POST', 'leads', 402, message: 'Limit');
      final container = await leadContainer(stub);
      _keep(container);
      await container
          .read(leadSaveProvider('quick').notifier)
          .create(const LeadInput(leadName: 'Karim'));
      final error = container.read(leadSaveProvider('quick')).error;
      expect(error, isA<ApiFailure>().having((f) => f.isQuota, 'quota', true));
    });

    test('logging an activity refreshes the lead', () async {
      final stub = leadStub()..on('POST', 'activities', const {});
      final container = await leadContainer(stub);
      _keep(container);
      await container
          .read(leadActivitySaveProvider('call').notifier)
          .log(
            rahimId,
            LeadActivityInput(
              kind: LeadActivityKind.note,
              occurredOn: DateTime(2026, 10, 5, 11),
              description: 'Wants a sample',
            ),
          );
      expect(
        container.read(leadActivitySaveProvider('call')).value?.id,
        rahimId,
      );
      expect(stub.lastBody('POST', 'activities')['body'], 'Wants a sample');
    });
  });
}
