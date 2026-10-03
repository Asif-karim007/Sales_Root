import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/contacts/data/contacts_repository.dart';
import 'package:salesroot/features/contacts/data/fake_contacts_repository.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';

part 'contacts_providers.g.dart';

@Riverpod(keepAlive: true)
ContactsRepository contactsRepository(Ref ref) =>
    FakeContactsRepository(ref.watch(fakeBackendProvider));

class ContactsFilter {
  const ContactsFilter({
    this.search = '',
    this.group = ContactGroup.all,
    this.letter,
  });

  final String search;
  final ContactGroup group;
  final String? letter;

  ContactQuery query(int page) =>
      ContactQuery(search: search, group: group, letter: letter, page: page);
}

@riverpod
class ContactsFilterNotifier extends _$ContactsFilterNotifier {
  @override
  ContactsFilter build() => const ContactsFilter();

  void search(String term) {
    if (term.trim() == state.search) return;
    state = ContactsFilter(
      search: term.trim(),
      group: state.group,
      letter: state.letter,
    );
  }

  void group(ContactGroup group) => state = ContactsFilter(
    search: state.search,
    group: group,
    letter: state.letter,
  );

  void letter(String? letter) => state = ContactsFilter(
    search: state.search,
    group: state.group,
    letter: letter,
  );
}

@riverpod
class ContactsListNotifier extends _$ContactsListNotifier {
  @override
  Future<Paged<Contact>> build() async {
    final filter = ref.watch(contactsFilterProvider);
    final result = await ref
        .watch(contactsRepositoryProvider)
        .contacts(filter.query(1));
    return Paged.first(result, facetKeys: const ['GroupCounts']);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        state.isLoading ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(contactsRepositoryProvider)
          .contacts(ref.read(contactsFilterProvider).query(current.page + 1));
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
Future<Contact> contact(Ref ref, int id) =>
    ref.watch(contactsRepositoryProvider).contact(id);

@riverpod
Future<List<LinkedLead>> contactLeads(Ref ref, int id) =>
    ref.watch(contactsRepositoryProvider).contactLeads(id);

@riverpod
Future<List<ContactActivity>> contactActivity(Ref ref, int id) =>
    ref.watch(contactsRepositoryProvider).contactActivity(id);

/// Everything that lists contacts or counts them.
void invalidateContactLists(Ref ref) {
  ref
    ..invalidate(contactsListProvider)
    ..invalidate(companyContactsProvider)
    ..invalidate(companyProvider)
    ..invalidate(companiesListProvider);
}

/// Saves the contact form; [id] 0 creates. A 409 comes back as [Duplicates]
/// so the form can offer to open the existing contact or save anyway.
@riverpod
class ContactSaveNotifier extends _$ContactSaveNotifier {
  @override
  FutureOr<SaveOutcome<Contact>?> build(int id) => null;

  Future<void> save(ContactInput input, {bool allowDuplicate = false}) async {
    final repository = ref.read(contactsRepositoryProvider);
    state = const AsyncLoading();
    final next = await AsyncValue.guard<SaveOutcome<Contact>?>(() async {
      try {
        final saved = id == 0
            ? await repository.createContact(
                input,
                allowDuplicate: allowDuplicate,
              )
            : await repository.editContact(
                id,
                input,
                allowDuplicate: allowDuplicate,
              );
        return Saved(saved);
      } on ApiFailure catch (failure) {
        if (!failure.isConflict) rethrow;
        return Duplicates(
          await repository.contactDuplicates(
            input.mobiles,
            excludeId: id == 0 ? null : id,
          ),
        );
      }
    });
    if (!ref.mounted) return;
    if (next.value case Saved(:final value)) {
      invalidateContactLists(ref);
      ref
        ..invalidate(contactProvider(value.id))
        ..invalidate(contactLeadsProvider(value.id));
    }
    state = next;
  }
}

enum RecordChange { deleted, primarySet, detached }

/// Deletes one contact; screens listen for [RecordChange.deleted].
@riverpod
class ContactMutationNotifier extends _$ContactMutationNotifier {
  @override
  FutureOr<RecordChange?> build(int id) => null;

  Future<void> delete() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard<RecordChange?>(() async {
      await ref.read(contactsRepositoryProvider).deleteContact(id);
      return RecordChange.deleted;
    });
    if (!ref.mounted) return;
    if (next.hasValue) invalidateContactLists(ref);
    state = next;
  }
}
