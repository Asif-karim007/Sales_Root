import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/features/growth/data/fake_lead_sources_repository.dart';
import 'package:salesroot/features/growth/data/lead_sources_repository.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';

part 'sources_providers.g.dart';

@Riverpod(keepAlive: true)
LeadSourcesRepository leadSourcesRepository(Ref ref) =>
    FakeLeadSourcesRepository(ref.watch(fakeBackendProvider));

@riverpod
Future<List<LeadChannel>> leadChannels(Ref ref) =>
    ref.watch(leadSourcesRepositoryProvider).channels();

/// Connect and disconnect from the channel list; callers show the outcome.
@Riverpod(keepAlive: true)
class ChannelActions extends _$ChannelActions {
  @override
  void build() {}

  Future<LeadChannel> connect(int id) async {
    final channel = await ref.read(leadSourcesRepositoryProvider).connect(id);
    if (ref.mounted) ref.invalidate(leadChannelsProvider);
    return channel;
  }

  Future<LeadChannel> disconnect(int id) async {
    final channel = await ref
        .read(leadSourcesRepositoryProvider)
        .disconnect(id);
    if (ref.mounted) {
      ref
        ..invalidate(leadChannelsProvider)
        ..invalidate(facebookSetupProvider);
    }
    return channel;
  }
}

enum FacebookStep { signIn, page, forms, mapping, connected }

/// The Facebook connection being set up or edited (#135).
class FacebookDraft {
  const FacebookDraft({
    required this.step,
    this.pages = const [],
    this.page,
    this.forms = const [],
    this.enabled = const {},
    this.mappings = const [],
    this.destination = LeadDestination.rules,
    this.busy = false,
    this.connected = false,
  });

  factory FacebookDraft.of(FacebookSetup setup) {
    final page = setup.page;
    if (page == null) return const FacebookDraft(step: FacebookStep.signIn);
    return FacebookDraft(
      step: FacebookStep.connected,
      page: page,
      forms: setup.forms,
      enabled: {
        for (final form in setup.forms)
          if (form.enabled) form.id,
      },
      mappings: setup.mappings,
      destination: setup.destination,
      connected: true,
    );
  }

  final FacebookStep step;
  final List<FacebookPage> pages;
  final FacebookPage? page;
  final List<LeadForm> forms;
  final Set<int> enabled;
  final List<FieldMapping> mappings;
  final LeadDestination destination;
  final bool busy;

  /// The Page is already connected; the screen edits it in place.
  final bool connected;

  /// The questions of the forms that are on, each with its mapping.
  List<FieldMapping> get visibleMappings {
    final keys = <String>{
      for (final form in forms)
        if (enabled.contains(form.id)) ...form.fields,
    };
    return [
      for (final key in keys)
        mappings.where((m) => m.field == key).firstOrNull ??
            FieldMapping(field: key, target: LeadField.guess(key)),
    ];
  }

  FacebookDraft copyWith({
    FacebookStep? step,
    List<FacebookPage>? pages,
    FacebookPage? page,
    List<LeadForm>? forms,
    Set<int>? enabled,
    List<FieldMapping>? mappings,
    LeadDestination? destination,
    bool? busy,
  }) => FacebookDraft(
    step: step ?? this.step,
    pages: pages ?? this.pages,
    page: page ?? this.page,
    forms: forms ?? this.forms,
    enabled: enabled ?? this.enabled,
    mappings: mappings ?? this.mappings,
    destination: destination ?? this.destination,
    busy: busy ?? this.busy,
    connected: connected,
  );
}

@riverpod
class FacebookSetupNotifier extends _$FacebookSetupNotifier {
  @override
  Future<FacebookDraft> build() async => FacebookDraft.of(
    await ref.watch(leadSourcesRepositoryProvider).facebook(),
  );

  /// The Meta sign-in: brings back the Pages the account manages.
  Future<void> signIn() => _busy((draft) async {
    final pages = await ref.read(leadSourcesRepositoryProvider).facebookPages();
    return draft.copyWith(pages: pages, step: FacebookStep.page);
  });

  Future<void> pickPage(FacebookPage page) => _busy((draft) async {
    final forms = await ref
        .read(leadSourcesRepositoryProvider)
        .facebookForms(page.id);
    return draft.copyWith(
      page: page,
      forms: forms,
      enabled: {
        for (final form in forms)
          if (form.enabled || form.campaign != null) form.id,
      },
      step: FacebookStep.forms,
    );
  });

  void toggleForm(int id) => _edit(
    (draft) => draft.copyWith(
      enabled: draft.enabled.contains(id)
          ? ({...draft.enabled}..remove(id))
          : {...draft.enabled, id},
    ),
  );

  void map(String field, LeadField target) => _edit(
    (draft) => draft.copyWith(
      mappings: [
        for (final mapping in draft.visibleMappings)
          mapping.field == field
              ? FieldMapping(field: field, target: target)
              : mapping,
      ],
    ),
  );

  void setDestination(LeadDestination destination) =>
      _edit((draft) => draft.copyWith(destination: destination));

  void goTo(FacebookStep step) => _edit((draft) => draft.copyWith(step: step));

  /// Saves the connection; throws the server's failure for the screen.
  Future<FacebookSetup> save() async {
    final draft = state.value;
    final page = draft?.page;
    if (draft == null || page == null) {
      throw StateError('Pick a Page first');
    }
    state = AsyncData(draft.copyWith(busy: true));
    try {
      final setup = await ref
          .read(leadSourcesRepositoryProvider)
          .saveFacebook(
            FacebookSetupInput(
              pageId: page.id,
              formIds: [
                for (final form in draft.forms)
                  if (draft.enabled.contains(form.id)) form.id,
              ],
              mappings: draft.visibleMappings,
              destination: draft.destination,
            ),
          );
      if (ref.mounted) {
        state = AsyncData(FacebookDraft.of(setup));
        ref.invalidate(leadChannelsProvider);
      }
      return setup;
    } catch (_) {
      if (ref.mounted) state = AsyncData(draft.copyWith(busy: false));
      rethrow;
    }
  }

  void _edit(FacebookDraft Function(FacebookDraft draft) change) {
    final draft = state.value;
    if (draft == null || draft.busy) return;
    state = AsyncData(change(draft));
  }

  Future<void> _busy(
    Future<FacebookDraft> Function(FacebookDraft draft) work,
  ) async {
    final draft = state.value;
    if (draft == null || draft.busy) return;
    state = AsyncData(draft.copyWith(busy: true));
    try {
      final next = await work(draft);
      if (ref.mounted) state = AsyncData(next.copyWith(busy: false));
    } catch (_) {
      if (ref.mounted) state = AsyncData(draft.copyWith(busy: false));
      rethrow;
    }
  }
}
