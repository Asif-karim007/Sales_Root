import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/support/data/fake_support_repository.dart';
import 'package:salesroot/features/support/data/support_repository.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';

part 'ticket_providers.g.dart';

@Riverpod(keepAlive: true)
SupportRepository supportRepository(Ref ref) {
  final latency = ref.watch(devSettingsProvider.select((s) => s.latency));
  final repository = FakeSupportRepository(
    ref.watch(fakeBackendProvider),
    agentDelay: latency
        ? const Duration(seconds: 6)
        : const Duration(milliseconds: 300),
  );
  ref.onDispose(repository.dispose);
  return repository;
}

/// The user's support requests, refreshed when support answers one.
@riverpod
class MyTicketsNotifier extends _$MyTicketsNotifier {
  @override
  Future<Paged<SupportTicket>> build() async {
    final repository = ref.watch(supportRepositoryProvider);
    final changes = repository.ticketChanges.listen((_) => _reload());
    ref.onDispose(changes.cancel);
    return Paged.first(await repository.tickets());
  }

  Future<void> _reload() async {
    final result = await AsyncValue.guard(
      () async =>
          Paged.first(await ref.read(supportRepositoryProvider).tickets()),
    );
    if (!ref.mounted || !result.hasValue) return;
    state = result;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(supportRepositoryProvider)
          .tickets(page: current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }
}

/// One conversation with support and what the user is doing in it.
class TicketThread {
  const TicketThread({
    required this.ticket,
    this.sending = false,
    this.resolving = false,
    this.agentTyping = false,
    this.failure,
  });

  final SupportTicket ticket;
  final bool sending;
  final bool resolving;

  /// The user wrote and support has not answered yet in this session.
  final bool agentTyping;

  /// The last action's failure; every copy clears it.
  final ApiFailure? failure;

  TicketThread copyWith({
    SupportTicket? ticket,
    bool? sending,
    bool? resolving,
    bool? agentTyping,
    ApiFailure? failure,
  }) => TicketThread(
    ticket: ticket ?? this.ticket,
    sending: sending ?? this.sending,
    resolving: resolving ?? this.resolving,
    agentTyping: agentTyping ?? this.agentTyping,
    failure: failure,
  );
}

@riverpod
class SupportTicketNotifier extends _$SupportTicketNotifier {
  @override
  Future<TicketThread> build(int id) async {
    final repository = ref.watch(supportRepositoryProvider);
    final changes = repository.ticketChanges
        .where((changed) => changed == id)
        .listen((_) => _refresh());
    ref.onDispose(changes.cancel);
    return TicketThread(ticket: await repository.ticket(id));
  }

  Future<void> _refresh() async {
    final result = await AsyncValue.guard(
      () => ref.read(supportRepositoryProvider).ticket(id),
    );
    if (!ref.mounted) return;
    final ticket = result.value;
    final current = state.value;
    if (ticket == null || current == null) return;
    state = AsyncData(current.copyWith(ticket: ticket, agentTyping: false));
  }

  /// True when the reply was sent.
  Future<bool> send(
    String text, {
    List<SupportAttachment> attachments = const [],
  }) async {
    final current = state.value;
    if (current == null || current.sending) return false;
    state = AsyncData(current.copyWith(sending: true));
    try {
      final ticket = await ref
          .read(supportRepositoryProvider)
          .reply(id, text, attachments: attachments);
      if (!ref.mounted) return true;
      state = AsyncData(TicketThread(ticket: ticket, agentTyping: true));
      ref.invalidate(myTicketsProvider);
      return true;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return false;
      state = AsyncData(current.copyWith(sending: false, failure: failure));
      return false;
    }
  }

  Future<void> resolve() async {
    final current = state.value;
    if (current == null || current.resolving) return;
    state = AsyncData(current.copyWith(resolving: true));
    try {
      final ticket = await ref.read(supportRepositoryProvider).resolve(id);
      if (!ref.mounted) return;
      state = AsyncData(TicketThread(ticket: ticket));
      ref.invalidate(myTicketsProvider);
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(resolving: false, failure: failure));
    }
  }
}

/// Sends a new support request; holds the created ticket once sent.
@riverpod
class NewTicketNotifier extends _$NewTicketNotifier {
  @override
  FutureOr<SupportTicket?> build() => null;

  Future<void> submit(TicketInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(supportRepositoryProvider).createTicket(input),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) ref.invalidate(myTicketsProvider);
  }
}
