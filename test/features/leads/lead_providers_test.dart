import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';

Future<ProviderContainer> _container({
  WorkspaceRole role = WorkspaceRole.owner,
}) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      seedGraphProvider.overrideWithValue(
        SeedGraph.build(
          workspaceId: 200,
          kind: WorkspaceKind.team,
          memberCount: 21,
          leadCount: 230,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false, role: () => role));
  return container;
}

/// Shows everyone's leads, so the list is long enough to page.
void _everyone(ProviderContainer container) => container
    .read(leadFilterProvider.notifier)
    .apply(const LeadFilter(mine: false));

Future<Lead> _openLeadIn(ProviderContainer container, int stageId) async {
  final page = await container
      .read(leadRepositoryProvider)
      .list(LeadQuery(stageIds: {stageId}, openOnly: false));
  return page.items.first;
}

void main() {
  group('lead list', () {
    test('loads 20 a time and appends the next page', () async {
      final container = await _container();
      container.listen(leadListProvider, (_, _) {});
      _everyone(container);

      final first = await container.read(leadListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.totalCount, greaterThan(40));
      expect(first.hasMore, isTrue);

      await container.read(leadListProvider.notifier).loadMore();
      final second = container.read(leadListProvider).requireValue;
      expect(second.items, hasLength(40));
      expect(second.page, 2);
      expect(
        second.items.map((l) => l.id).toSet(),
        hasLength(40),
        reason: 'pages must not overlap',
      );
    });

    test('chip and stage facets agree with the filtered lists', () async {
      final container = await _container();
      container.listen(leadListProvider, (_, _) {});
      _everyone(container);

      final all = await container.read(leadListProvider.future);
      expect(all.chipCount(LeadChip.all), all.totalCount);
      expect(all.openCount, all.totalCount);

      final stages = await container.read(leadStagesProvider.future);
      final openByStage = stages
          .where((s) => s.isOpen)
          .fold<int>(0, (sum, s) => sum + all.stageCount(s.id));
      expect(openByStage, all.openCount);

      for (final chip in [LeadChip.overdue, LeadChip.hot, LeadChip.stalled]) {
        container.read(leadFilterProvider.notifier).chip(chip);
        final narrowed = await container.read(leadListProvider.future);
        expect(narrowed.totalCount, all.chipCount(chip), reason: chip.wire);
        expect(narrowed.chipCount(LeadChip.all), all.totalCount);
      }
    });

    test('a member only sees their own and shared leads', () async {
      final container = await _container(role: WorkspaceRole.member);
      container.listen(leadListProvider, (_, _) {});
      _everyone(container);

      final page = await container.read(leadListProvider.future);
      expect(page.items, isNotEmpty);
      for (final lead in page.items) {
        final mine = lead.assignedTo?.id == SeedGraph.meId;
        final shared = lead.sharedWith.any((p) => p.id == SeedGraph.meId);
        expect(mine || shared, isTrue);
      }
    });

    test('offline shows the offline failure', () async {
      final container = await _container();
      container.listen(leadListProvider, (_, _) {});
      container
          .read(devSettingsProvider.notifier)
          .update((s) => s.copyWith(offline: true));

      await expectLater(
        container.read(leadListProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('create', () {
    test('saves a new lead, and a matching phone answers 409', () async {
      final container = await _container();
      final save = leadSaveProvider('test');
      container.listen(save, (_, _) {});
      final existing = await _openLeadIn(container, 1);
      final phone = existing.phone ?? '';

      const fresh = LeadInput(
        leadName: 'Rahim Enterprise',
        newContact: LeadNewContact(name: 'Abdur Rahim', mobile: '01912345678'),
      );
      await container.read(save.notifier).create(fresh);
      final created = container.read(save).value;
      expect(created?.leadName, 'Rahim Enterprise');
      expect(created?.phone, '01912345678');
      expect(created?.timeline.first.kind.wire, 'Created');

      final twin = LeadInput(
        leadName: 'Same buyer again',
        newContact: LeadNewContact(name: 'Someone', mobile: phone),
      );
      await container.read(save.notifier).create(twin);
      final error = container.read(save).error;
      expect(error, isA<LeadDuplicateFailure>());
      expect((error as LeadDuplicateFailure).existing.phone, phone);
      expect(error.statusCode, 409);
      expect(error.field, LeadDuplicateField.phone);

      await container.read(save.notifier).create(twin.allowingDuplicate());
      expect(container.read(save).value?.leadName, 'Same buyer again');
    });

    test('rejects a bad mobile number with a field error', () async {
      final container = await _container();
      await expectLater(
        container
            .read(leadRepositoryProvider)
            .create(
              const LeadInput(
                leadName: 'Test',
                newContact: LeadNewContact(name: 'X', mobile: '12345'),
              ),
            ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.fieldError('Mobile'),
            'Mobile',
            isNotNull,
          ),
        ),
      );
    });
  });

  group('stage moves', () {
    test('a move lands everywhere and undo puts it back', () async {
      final container = await _container();
      container
        ..listen(leadActionsProvider, (_, _) {})
        ..listen(leadListProvider, (_, _) {});
      _everyone(container);
      await container.read(leadListProvider.future);
      final stages = await container.read(leadStagesProvider.future);
      final lead = await _openLeadIn(container, 1);
      final interested = stages.byId(3);
      expect(interested, isNotNull);
      if (interested == null) return;
      final before = (await container.read(
        leadProvider(lead.id).future,
      )).timeline.length;

      final actions = container.read(leadActionsProvider.notifier);
      await actions.moveStage(lead, interested, LeadSurface.board);

      final event = container.read(leadActionsProvider);
      expect(event, isA<LeadMoved>());
      expect(event?.origin, LeadSurface.board);
      final moved = await container.read(leadProvider(lead.id).future);
      expect(moved.stage?.id, 3);
      expect(moved.winProbability, interested.winProbability);
      expect(moved.timeline.length, before + 1);

      await actions.undoMove((event as LeadMoved).move, LeadSurface.board);
      expect(container.read(leadActionsProvider), isA<LeadMoveUndone>());
      final undone = await container.read(leadProvider(lead.id).future);
      expect(undone.stage?.id, 1);
      expect(undone.timeline.length, before);
    });

    test('Lost needs a reason, and keeps it', () async {
      final container = await _container();
      container.listen(leadActionsProvider, (_, _) {});
      final stages = await container.read(leadStagesProvider.future);
      final lost = stages.lost;
      expect(lost, isNotNull);
      if (lost == null) return;
      final lead = await _openLeadIn(container, 2);
      final actions = container.read(leadActionsProvider.notifier);

      await actions.moveStage(lead, lost, LeadSurface.detail);
      final failed = container.read(leadActionsProvider);
      expect(failed, isA<LeadActionFailed>());
      expect((failed as LeadActionFailed).failure.isValidation, isTrue);

      await actions.moveStage(
        lead,
        lost,
        LeadSurface.detail,
        lostReasonId: 2,
        note: 'Went with a cheaper brand',
      );
      expect(container.read(leadActionsProvider), isA<LeadMoved>());
      final saved = await container.read(leadProvider(lead.id).future);
      expect(saved.isLost, isTrue);
      expect(saved.winLoss?.causeId, 2);
      expect(saved.winLoss?.note, 'Went with a cheaper brand');
      expect(saved.winProbability, 0);
    });

    test('Easy shows the first three open stages and Won', () async {
      final container = await _container(role: WorkspaceRole.member);
      final visible = await container.read(visibleLeadStagesProvider.future);
      expect(visible.map((s) => s.id), [1, 2, 3, 5]);
    });
  });

  group('access', () {
    test('a member cannot delete a lead', () async {
      final container = await _container(role: WorkspaceRole.member);
      container.listen(leadActionsProvider, (_, _) {});
      final lead =
          (await container
                  .read(leadRepositoryProvider)
                  .list(const LeadQuery(mine: true)))
              .items
              .first;
      expect(lead.canDelete, isFalse);

      await container
          .read(leadActionsProvider.notifier)
          .delete(lead, LeadSurface.list);
      final event = container.read(leadActionsProvider);
      expect(event, isA<LeadActionFailed>());
      expect((event as LeadActionFailed).failure.isForbidden, isTrue);
      expect((await container.read(leadProvider(lead.id).future)).id, lead.id);
    });

    test('an owner deletes, and the lead is gone', () async {
      final container = await _container();
      container.listen(leadActionsProvider, (_, _) {});
      final lead = await _openLeadIn(container, 1);
      await container
          .read(leadActionsProvider.notifier)
          .delete(lead, LeadSurface.detail);
      expect(container.read(leadActionsProvider), isA<LeadDeleted>());
      await expectLater(
        container.read(leadRepositoryProvider).get(lead.id),
        throwsA(isA<ApiFailure>().having((f) => f.isNotFound, '404', true)),
      );
    });
  });
}
