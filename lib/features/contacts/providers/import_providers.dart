import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/contacts/data/device_contacts_source.dart';
import 'package:salesroot/features/contacts/data/fake_device_contacts_source.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/phone_book_entry.dart';
import 'package:salesroot/features/contacts/providers/contacts_providers.dart';

part 'import_providers.g.dart';

@Riverpod(keepAlive: true)
DeviceContactsSource deviceContactsSource(Ref ref) =>
    FakeDeviceContactsSource(ref.watch(fakeBackendProvider));

class ContactImportState {
  const ContactImportState({
    this.granted = true,
    this.candidates = const [],
    this.selected = const {},
    this.search = '',
    this.importing = false,
    this.imported,
    this.failure,
  });

  final bool granted;
  final List<ImportCandidate> candidates;

  /// Device ids of the picked entries.
  final Set<String> selected;
  final String search;
  final bool importing;

  /// How many were added, once the import finished.
  final int? imported;
  final ApiFailure? failure;

  List<ImportCandidate> get visible {
    final term = search.trim().toLowerCase();
    if (term.isEmpty) return candidates;
    final digits = term.replaceAll(RegExp(r'\D'), '');
    return candidates.where((candidate) {
      final entry = candidate.entry;
      return entry.name.toLowerCase().contains(term) ||
          (digits.length >= 3 &&
              entry.phones.any(
                (phone) => phone.replaceAll(RegExp(r'\D'), '').contains(digits),
              ));
    }).toList();
  }

  int get newCount => candidates.where((c) => !c.exists).length;

  ContactImportState copyWith({
    Set<String>? selected,
    String? search,
    bool? importing,
    int? Function()? imported,
    ApiFailure? Function()? failure,
  }) => ContactImportState(
    granted: granted,
    candidates: candidates,
    selected: selected ?? this.selected,
    search: search ?? this.search,
    importing: importing ?? this.importing,
    imported: imported == null ? this.imported : imported(),
    failure: failure == null ? this.failure : failure(),
  );
}

/// The phone book with saved numbers marked, the user's picks and the import.
@riverpod
class ContactImportNotifier extends _$ContactImportNotifier {
  @override
  Future<ContactImportState> build() async {
    final source = ref.watch(deviceContactsSourceProvider);
    if (!await source.requestAccess()) {
      return const ContactImportState(granted: false);
    }
    final entries = await source.entries();
    final matches = await ref.watch(contactsRepositoryProvider).matchPhones([
      for (final entry in entries) ...entry.phones,
    ]);
    return ContactImportState(
      candidates: [
        for (final entry in entries)
          ImportCandidate(
            entry: entry,
            existingContactId: entry.phones
                .map((phone) => matches[phone])
                .nonNulls
                .firstOrNull,
          ),
      ],
    );
  }

  void search(String term) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(search: term));
  }

  void toggle(ImportCandidate candidate) {
    final current = state.value;
    if (current == null || candidate.exists || current.importing) return;
    final id = candidate.entry.deviceId;
    final selected = {...current.selected};
    if (!selected.remove(id)) selected.add(id);
    state = AsyncData(current.copyWith(selected: selected));
  }

  /// Picks every new entry, or clears the picks when all are already picked.
  void toggleAll() {
    final current = state.value;
    if (current == null || current.importing) return;
    final fresh = {
      for (final candidate in current.candidates)
        if (!candidate.exists) candidate.entry.deviceId,
    };
    final all = current.selected.containsAll(fresh);
    state = AsyncData(current.copyWith(selected: all ? {} : fresh));
  }

  Future<void> import() async {
    final current = state.value;
    if (current == null || current.selected.isEmpty || current.importing) {
      return;
    }
    state = AsyncData(current.copyWith(importing: true, failure: () => null));
    final inputs = [
      for (final candidate in current.candidates)
        if (current.selected.contains(candidate.entry.deviceId))
          ContactInput(
            name: candidate.entry.name,
            mobiles: candidate.entry.phones,
            emails: [?candidate.entry.email],
          ),
    ];
    try {
      final added = await ref
          .read(contactsRepositoryProvider)
          .importContacts(inputs);
      if (!ref.mounted) return;
      ref.invalidate(contactsListProvider);
      state = AsyncData(
        current.copyWith(importing: false, imported: () => added),
      );
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(importing: false, failure: () => failure),
      );
    }
  }
}
