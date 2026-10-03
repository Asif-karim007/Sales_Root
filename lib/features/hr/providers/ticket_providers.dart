import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/features/hr/data/fake_ticket_repository.dart';
import 'package:salesroot/features/hr/data/ticket_repository.dart';
import 'package:salesroot/features/hr/models/ticket.dart';

part 'ticket_providers.g.dart';

@Riverpod(keepAlive: true)
TicketRepository ticketRepository(Ref ref) =>
    FakeTicketRepository(ref.watch(fakeBackendProvider));

@riverpod
Future<List<TicketProduct>> ticketProducts(Ref ref) =>
    ref.watch(ticketRepositoryProvider).products();

@riverpod
Future<Ticket> ticket(Ref ref, int id) =>
    ref.watch(ticketRepositoryProvider).get(id);

class TicketFormState {
  const TicketFormState({
    this.draft = const TicketDraft(),
    this.showErrors = false,
    this.submission = const AsyncData(null),
  });

  final TicketDraft draft;

  /// Set after a submit attempt, so errors show only once they matter.
  final bool showErrors;
  final AsyncValue<Ticket?> submission;

  TicketFormState copyWith({
    TicketDraft? draft,
    bool? showErrors,
    AsyncValue<Ticket?>? submission,
  }) => TicketFormState(
    draft: draft ?? this.draft,
    showErrors: showErrors ?? this.showErrors,
    submission: submission ?? this.submission,
  );
}

@riverpod
class TicketFormNotifier extends _$TicketFormNotifier {
  @override
  TicketFormState build() => const TicketFormState();

  void edit(TicketDraft Function(TicketDraft draft) change) =>
      state = state.copyWith(draft: change(state.draft));

  Future<void> submit() async {
    final current = state;
    if (current.submission.isLoading) return;
    if (current.draft.errors.isNotEmpty) {
      state = current.copyWith(showErrors: true);
      return;
    }
    state = current.copyWith(
      showErrors: true,
      submission: const AsyncLoading(),
    );
    final result = await AsyncValue.guard(
      () => ref.read(ticketRepositoryProvider).create(current.draft.toInput()),
    );
    if (!ref.mounted) return;
    state = current.copyWith(showErrors: true, submission: result);
  }
}

enum TicketAction { status, reply }

/// Status changes and replies on one ticket; the state names the last one
/// that went through.
@riverpod
class TicketActionsNotifier extends _$TicketActionsNotifier {
  @override
  AsyncValue<TicketAction?> build(int id) => const AsyncData(null);

  Future<void> setStatus(TicketStatus status) => _run(
    TicketAction.status,
    () => ref.read(ticketRepositoryProvider).setStatus(id, status),
  );

  Future<void> reply(String text) => _run(
    TicketAction.reply,
    () => ref.read(ticketRepositoryProvider).reply(id, text),
  );

  Future<void> _run(TicketAction action, Future<Ticket> Function() work) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await work();
      return action;
    });
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) ref.invalidate(ticketProvider(id));
  }
}
