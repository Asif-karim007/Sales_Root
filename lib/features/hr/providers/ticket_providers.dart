import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/features/hr/data/hr_repositories.dart';
import 'package:salesroot/features/hr/models/ticket.dart';

part 'ticket_providers.g.dart';

@riverpod
Future<Ticket> ticket(Ref ref, String id) =>
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
  AsyncValue<TicketAction?> build(String id) => const AsyncData(null);

  Future<void> setStatus(TicketStatus status) => _run(
    TicketAction.status,
    () => ref.read(ticketRepositoryProvider).setStatus(id, status),
  );

  Future<void> reply(String text) => _run(
    TicketAction.reply,
    () => ref.read(ticketRepositoryProvider).reply(id, text),
  );

  Future<void> _run(TicketAction action, Future<void> Function() work) async {
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
