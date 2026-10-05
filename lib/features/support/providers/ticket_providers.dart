import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/support/data/support_repositories.dart';
import 'package:salesroot/features/support/models/support_ticket.dart';

part 'ticket_providers.g.dart';

/// The user's support requests.
@riverpod
Future<List<SupportTicket>> myTickets(Ref ref) async =>
    (await ref.watch(supportRepositoryProvider).tickets()).items;

/// One conversation with support and what the user is doing in it.
class TicketThread {
  const TicketThread({
    required this.ticket,
    this.sending = false,
    this.failure,
  });

  final SupportTicket ticket;
  final bool sending;

  /// The last action's failure; every copy clears it.
  final ApiFailure? failure;

  TicketThread copyWith({
    SupportTicket? ticket,
    bool? sending,
    ApiFailure? failure,
  }) => TicketThread(
    ticket: ticket ?? this.ticket,
    sending: sending ?? this.sending,
    failure: failure,
  );
}

@riverpod
class SupportTicketNotifier extends _$SupportTicketNotifier {
  @override
  Future<TicketThread> build(String id) async => TicketThread(
    ticket: await ref.watch(supportRepositoryProvider).ticket(id),
  );

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
      state = AsyncData(TicketThread(ticket: ticket));
      ref.invalidate(myTicketsProvider);
      return true;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return false;
      state = AsyncData(current.copyWith(sending: false, failure: failure));
      return false;
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
