import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/growth/data/fake_lead_inbox_repository.dart';
import 'package:salesroot/features/growth/data/lead_inbox_repository.dart';
import 'package:salesroot/features/growth/models/distribution_rule.dart';
import 'package:salesroot/features/growth/models/inbox_lead.dart';

part 'inbox_providers.g.dart';

@Riverpod(keepAlive: true)
LeadInboxRepository leadInboxRepository(Ref ref) =>
    FakeLeadInboxRepository(ref.watch(fakeBackendProvider));

@riverpod
class InboxFilterNotifier extends _$InboxFilterNotifier {
  @override
  InboxFilter build() => InboxFilter.all;

  void set(InboxFilter filter) => state = filter;
}

/// The new-leads inbox (#136), most urgent first.
@riverpod
class InboxListNotifier extends _$InboxListNotifier {
  @override
  Future<Paged<InboxLead>> build() async {
    final filter = ref.watch(inboxFilterProvider);
    final page = await ref.watch(leadInboxRepositoryProvider).list(filter);
    return Paged.first(page, facetKeys: const ['Counts', 'Stats']);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(leadInboxRepositoryProvider)
          .list(ref.read(inboxFilterProvider), page: current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<InboxLead> inboxLead(Ref ref, int id) =>
    ref.watch(leadInboxRepositoryProvider).get(id);

@riverpod
Future<AssigneeSuggestion> inboxSuggestion(Ref ref, int id) =>
    ref.watch(leadInboxRepositoryProvider).suggestAssignee(id);

@riverpod
Future<List<GrowthMember>> growthMembers(Ref ref) =>
    ref.watch(leadInboxRepositoryProvider).members();

@riverpod
Future<List<LeadStage>> leadStages(Ref ref) =>
    ref.watch(leadInboxRepositoryProvider).stages();

/// Assign and reject from the list or the detail; callers show the outcome.
@Riverpod(keepAlive: true)
class InboxActions extends _$InboxActions {
  @override
  void build() {}

  Future<InboxLead> assign(int id, int memberId) async {
    final lead = await ref
        .read(leadInboxRepositoryProvider)
        .assign(id, memberId);
    if (ref.mounted) _refresh(id);
    return lead;
  }

  Future<InboxLead> reject(int id, RejectReason reason) async {
    final lead = await ref.read(leadInboxRepositoryProvider).reject(id, reason);
    if (ref.mounted) _refresh(id);
    return lead;
  }

  void _refresh(int id) {
    ref
      ..invalidate(inboxListProvider)
      ..invalidate(inboxLeadProvider(id))
      ..invalidate(growthMembersProvider);
  }
}

/// Accepting an inbox lead into the main list (#138).
@riverpod
class AcceptLeadSubmit extends _$AcceptLeadSubmit {
  @override
  AsyncValue<InboxLead?> build(int id) => const AsyncData(null);

  Future<void> submit(AcceptInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(leadInboxRepositoryProvider).accept(id, input),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) {
      ref
        ..invalidate(inboxListProvider)
        ..invalidate(inboxLeadProvider(id))
        ..invalidate(growthMembersProvider);
    }
  }
}
