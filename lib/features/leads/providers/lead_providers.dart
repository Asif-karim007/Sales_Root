import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/leads/data/api_lead_repository.dart';
import 'package:salesroot/features/leads/data/lead_api.dart';
import 'package:salesroot/features/leads/data/lead_repository.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_input.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';

part 'lead_providers.g.dart';

@Riverpod(keepAlive: true)
LeadApi leadApi(Ref ref) => LeadApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
LeadRepository leadRepository(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiLeadRepository(
    ref.watch(leadApiProvider),
    memberId: () => ref.read(currentWorkspaceProvider)?.membershipId,
  );
}

@Riverpod(keepAlive: true)
Future<List<LeadStage>> leadStages(Ref ref) =>
    ref.watch(leadRepositoryProvider).stages();

@Riverpod(keepAlive: true)
Future<LeadLookups> leadLookups(Ref ref) =>
    ref.watch(leadRepositoryProvider).lookups();

/// The stages the current experience level shows, Lost excluded.
@riverpod
Future<List<LeadStage>> visibleLeadStages(Ref ref) async {
  final level = ref.watch(experienceLevelProvider);
  final stages = await ref.watch(leadStagesProvider.future);
  return stages.visibleFor(level);
}

@riverpod
class LeadFilterNotifier extends _$LeadFilterNotifier {
  @override
  LeadFilter build() {
    ref.watch(leadRepositoryProvider);
    return const LeadFilter();
  }

  void apply(LeadFilter filter) => state = filter;

  void search(String text) {
    if (text.trim() == state.search) return;
    state = state.copyWith(search: text.trim());
  }

  void chip(LeadChip chip) => state = state.copyWith(chip: chip);
}

/// The lead list, 20 at a time, rebuilt from page 1 when the filter changes.
@riverpod
class LeadListNotifier extends _$LeadListNotifier {
  LeadQuery _query(int page) => ref.read(leadFilterProvider).query(page: page);

  @override
  Future<Paged<Lead>> build() async {
    ref.watch(leadFilterProvider);
    final repository = ref.watch(leadRepositoryProvider);
    return Paged.first(await repository.list(_query(1)));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(leadRepositoryProvider)
          .list(_query(current.page + 1));
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  /// Shows [lead] as saved.
  void patch(Lead lead) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.map((l) => l.id == lead.id ? lead : l));
  }

  void remove(String id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.where((l) => l.id != id));
  }
}

/// The pipeline board's columns, each paged on its own.
class LeadBoard {
  const LeadBoard({required this.stages, required this.columns});

  final List<LeadStage> stages;
  final Map<String, Paged<Lead>> columns;

  Paged<Lead> column(String stageId) => columns[stageId] ?? const Paged();

  LeadBoard withColumn(String stageId, Paged<Lead> column) =>
      LeadBoard(stages: stages, columns: {...columns, stageId: column});
}

@riverpod
class LeadBoardNotifier extends _$LeadBoardNotifier {
  LeadQuery _query(String stageId, int page) => ref
      .read(leadFilterProvider)
      .query(page: page, stageId: stageId, withChip: false);

  @override
  Future<LeadBoard> build() async {
    ref.watch(leadFilterProvider);
    final level = ref.watch(experienceLevelProvider);
    final repository = ref.watch(leadRepositoryProvider);
    final stages = (await ref.watch(
      leadStagesProvider.future,
    )).columnsFor(level);
    final pages = await Future.wait([
      for (final stage in stages) repository.list(_query(stage.id, 1)),
    ]);
    return LeadBoard(
      stages: stages,
      columns: {
        for (var i = 0; i < stages.length; i++)
          stages[i].id: Paged.first(pages[i]),
      },
    );
  }

  Future<void> loadMore(String stageId) async {
    final board = state.value;
    final column = board?.column(stageId);
    if (board == null || column == null) return;
    if (!column.hasMore || column.isLoadingMore) return;
    state = AsyncData(board.withColumn(stageId, column.loadingMore()));
    try {
      final next = await ref
          .read(leadRepositoryProvider)
          .list(_query(stageId, column.page + 1));
      if (!ref.mounted) return;
      final latest = state.value ?? board;
      state = AsyncData(latest.withColumn(stageId, column.append(next)));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      final latest = state.value ?? board;
      state = AsyncData(latest.withColumn(stageId, column.failedMore(failure)));
    }
  }

  /// Puts [lead] at the top of its stage's column, taking it out of any
  /// other.
  void place(Lead lead) {
    final board = state.value;
    if (board == null) return;
    final stageId = lead.stage?.id;
    final columns = <String, Paged<Lead>>{
      for (final entry in board.columns.entries)
        entry.key: entry.value.where((l) => l.id != lead.id),
    };
    final target = columns[stageId];
    if (stageId != null && target != null) {
      columns[stageId] = target.prepend(lead);
    }
    state = AsyncData(LeadBoard(stages: board.stages, columns: columns));
  }

  void remove(String id) {
    final board = state.value;
    if (board == null) return;
    state = AsyncData(
      LeadBoard(
        stages: board.stages,
        columns: {
          for (final entry in board.columns.entries)
            entry.key: entry.value.where((l) => l.id != id),
        },
      ),
    );
  }
}

/// One lead with its timeline.
@riverpod
Future<Lead> lead(Ref ref, String id) =>
    ref.watch(leadRepositoryProvider).get(id);

/// How many leads [filter] would show, for the filter sheet's button.
@riverpod
Future<int> leadFilterPreview(Ref ref, LeadFilter filter) async {
  final result = await ref
      .watch(leadRepositoryProvider)
      .list(filter.query(pageSize: 1));
  return result.totalCount;
}

/// Where a lead action started, so only that screen reacts to its result.
enum LeadSurface { list, board, detail, links }

sealed class LeadEvent {
  const LeadEvent(this.origin);

  final LeadSurface origin;
}

class LeadMoved extends LeadEvent {
  const LeadMoved(super.origin, this.move, this.stage);

  final LeadStageMove move;
  final LeadStage stage;
}

class LeadMoveUndone extends LeadEvent {
  const LeadMoveUndone(super.origin, this.lead);

  final Lead lead;
}

class LeadTaskDone extends LeadEvent {
  const LeadTaskDone(super.origin, this.lead);

  final Lead lead;
}

class LeadDeleted extends LeadEvent {
  const LeadDeleted(super.origin, this.lead);

  final Lead lead;
}

class LeadRestored extends LeadEvent {
  const LeadRestored(super.origin, this.lead);

  final Lead lead;
}

class LeadActionFailed extends LeadEvent {
  const LeadActionFailed(super.origin, this.failure);

  final ApiFailure failure;
}

/// Stage moves, undo, task done, delete and restore. Every result lands in
/// the list, the board and the detail at once; the screen named by the
/// event's origin shows the snackbar. Kept alive so an undo still lands
/// after the screen that started the move has closed.
@Riverpod(keepAlive: true)
class LeadActionsNotifier extends _$LeadActionsNotifier {
  @override
  LeadEvent? build() => null;

  Future<void> moveStage(
    Lead lead,
    LeadStageInput input,
    LeadSurface origin,
  ) async {
    _show(lead.movedTo(input.stage));
    try {
      final moved = await ref
          .read(leadRepositoryProvider)
          .moveStage(lead, input);
      if (!ref.mounted) return;
      _show(moved);
      ref.invalidate(leadProvider(lead.id));
      state = LeadMoved(
        origin,
        LeadStageMove(before: lead, lead: moved),
        input.stage,
      );
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      _show(lead);
      state = LeadActionFailed(origin, failure);
    }
  }

  /// Puts the lead back where [move] found it.
  Future<void> undoMove(LeadStageMove move, LeadSurface origin) =>
      _run(origin, () async {
        final before = move.before;
        final stages = await ref.read(leadStagesProvider.future);
        final from = before.stage;
        final stage = before.isLost ? stages.lost : stages.byId(from?.id);
        if (stage == null) throw const ApiFailure(404, '');
        final lead = await ref
            .read(leadRepositoryProvider)
            .moveStage(
              move.lead,
              LeadStageInput(
                stage: stage,
                lostReason: before.lostReason,
                note: before.lostNote,
                amount: before.isWon ? before.estimatedAmount : null,
              ),
            );
        return LeadMoveUndone(origin, lead);
      });

  Future<void> completeTask(Lead lead, LeadTask task, LeadSurface origin) =>
      _run(origin, () async {
        final done = await ref
            .read(leadRepositoryProvider)
            .completeTask(lead.id, task.id);
        return LeadTaskDone(origin, done);
      });

  Future<void> delete(Lead lead, LeadSurface origin) => _run(origin, () async {
    await ref.read(leadRepositoryProvider).delete(lead.id);
    return LeadDeleted(origin, lead);
  });

  Future<void> restore(Lead lead, LeadSurface origin) => _run(origin, () async {
    final restored = await ref.read(leadRepositoryProvider).restore(lead.id);
    return LeadRestored(origin, restored);
  });

  Future<void> _run(
    LeadSurface origin,
    Future<LeadEvent> Function() action,
  ) async {
    try {
      final event = await action();
      if (!ref.mounted) return;
      switch (event) {
        case LeadDeleted(:final lead):
          _drop(lead.id);
        case LeadRestored():
          ref
            ..invalidate(leadListProvider)
            ..invalidate(leadBoardProvider);
        case LeadMoveUndone(:final lead) || LeadTaskDone(:final lead):
          _show(lead);
          ref.invalidate(leadProvider(lead.id));
        case LeadMoved() || LeadActionFailed():
          break;
      }
      state = event;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = LeadActionFailed(origin, failure);
    }
  }

  void _show(Lead lead) {
    if (ref.exists(leadListProvider)) {
      ref.read(leadListProvider.notifier).patch(lead);
    }
    if (ref.exists(leadBoardProvider)) {
      ref.read(leadBoardProvider.notifier).place(lead);
    }
  }

  void _drop(String id) {
    if (ref.exists(leadListProvider)) {
      ref.read(leadListProvider.notifier).remove(id);
    }
    if (ref.exists(leadBoardProvider)) {
      ref.read(leadBoardProvider.notifier).remove(id);
    }
  }
}

/// Saving the lead forms. [slot] keeps the quick, voice and full forms
/// apart, since one can open over another.
@riverpod
class LeadSaveNotifier extends _$LeadSaveNotifier {
  @override
  FutureOr<Lead?> build(String slot) => null;

  Future<void> create(LeadInput input) => _save(
    () => ref.read(leadRepositoryProvider).create(input),
    created: true,
  );

  Future<void> edit(Lead lead, LeadInput input) =>
      _save(() => ref.read(leadRepositoryProvider).edit(lead, input));

  Future<void> _save(
    Future<Lead> Function() save, {
    bool created = false,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(save);
    if (!ref.mounted) return;
    final lead = result.value;
    if (lead != null) {
      ref.invalidate(leadProvider(lead.id));
      if (created) {
        ref
          ..invalidate(leadListProvider)
          ..invalidate(leadBoardProvider);
      } else {
        if (ref.exists(leadListProvider)) {
          ref.read(leadListProvider.notifier).patch(lead);
        }
        if (ref.exists(leadBoardProvider)) {
          ref.read(leadBoardProvider.notifier).place(lead);
        }
      }
    }
    state = result;
  }
}

/// Logging a call, visit, note or message on a lead.
@riverpod
class LeadActivitySaveNotifier extends _$LeadActivitySaveNotifier {
  @override
  FutureOr<Lead?> build(String slot) => null;

  Future<void> log(String leadId, LeadActivityInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(leadRepositoryProvider).logActivity(leadId, input),
    );
    if (!ref.mounted) return;
    final lead = result.value;
    if (lead != null) {
      ref.invalidate(leadProvider(leadId));
      if (ref.exists(leadListProvider)) {
        ref.read(leadListProvider.notifier).patch(lead);
      }
    }
    state = result;
  }
}

/// A call started from a lead, waiting for the app to come back so the
/// outcome can be logged.
class PendingCall {
  const PendingCall({
    required this.leadId,
    required this.contactName,
    required this.startedAt,
  });

  final String leadId;
  final String contactName;
  final DateTime startedAt;
}

@Riverpod(keepAlive: true)
class PendingCallNotifier extends _$PendingCallNotifier {
  @override
  PendingCall? build() => null;

  void start(PendingCall call) => state = call;

  /// The waiting call, cleared so only one screen asks for its outcome.
  PendingCall? take() {
    final call = state;
    state = null;
    return call;
  }
}
