import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/contacts/data/api_contacts_repository.dart';
import 'package:salesroot/features/contacts/data/contacts_api.dart';
import 'package:salesroot/features/contacts/data/contacts_repository.dart';
import 'package:salesroot/features/contacts/models/company_detail.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';

part 'contacts_providers.g.dart';

@Riverpod(keepAlive: true)
ContactsApi contactsApi(Ref ref) => ContactsApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
ContactsRepository contactsRepository(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiContactsRepository(ref.watch(contactsApiProvider));
}

@riverpod
class ContactsSearchNotifier extends _$ContactsSearchNotifier {
  @override
  String build() => '';

  void search(String term) {
    if (term.trim() == state) return;
    state = term.trim();
  }
}

@riverpod
class ContactsListNotifier extends _$ContactsListNotifier {
  @override
  Future<Paged<Contact>> build() async {
    final search = ref.watch(contactsSearchProvider);
    final result = await ref
        .watch(contactsRepositoryProvider)
        .contacts(ContactQuery(search: search));
    return Paged.first(result);
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
          .contacts(
            ContactQuery(
              search: ref.read(contactsSearchProvider),
              page: current.page + 1,
            ),
          );
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
Future<ContactDetail> contactDetail(Ref ref, String id) =>
    ref.watch(contactsRepositoryProvider).contact(id);

@riverpod
Future<Contact> contact(Ref ref, String id) async =>
    (await ref.watch(contactDetailProvider(id).future)).contact;

@riverpod
Future<List<LinkedLead>> contactLeads(Ref ref, String id) async =>
    (await ref.watch(contactDetailProvider(id).future)).leads;

@riverpod
Future<List<ContactActivity>> contactActivity(Ref ref, String id) async =>
    (await ref.watch(contactDetailProvider(id).future)).activities;

/// Everything that lists contacts or counts them.
void invalidateContactLists(Ref ref) {
  ref
    ..invalidate(contactsListProvider)
    ..invalidate(companyDetailProvider)
    ..invalidate(companiesListProvider);
}

/// Saves the contact form; an empty [id] creates. A 409 comes back as
/// [Duplicates] so the form can offer to open the existing contact.
@riverpod
class ContactSaveNotifier extends _$ContactSaveNotifier {
  @override
  FutureOr<SaveOutcome<Contact>?> build(String id) => null;

  Future<void> save(ContactInput input) async {
    final repository = ref.read(contactsRepositoryProvider);
    state = const AsyncLoading();
    final next = await AsyncValue.guard<SaveOutcome<Contact>?>(() async {
      try {
        final saved = id.isEmpty
            ? await repository.createContact(input)
            : await repository.editContact(id, input);
        return Saved(saved);
      } on ApiFailure catch (failure) {
        if (!failure.isConflict) rethrow;
        return Duplicates(
          await repository.contactDuplicates(
            input.mobiles,
            excludeId: id.isEmpty ? null : id,
          ),
        );
      }
    });
    if (!ref.mounted) return;
    if (next.value case Saved(:final value)) {
      invalidateContactLists(ref);
      ref.invalidate(contactDetailProvider(value.id));
    }
    state = next;
  }
}

/// Deletes one contact; true once it is gone.
@riverpod
class ContactMutationNotifier extends _$ContactMutationNotifier {
  @override
  FutureOr<bool> build(String id) => false;

  Future<void> delete() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() async {
      await ref.read(contactsRepositoryProvider).deleteContact(id);
      return true;
    });
    if (!ref.mounted) return;
    if (next.hasValue) invalidateContactLists(ref);
    state = next;
  }
}
