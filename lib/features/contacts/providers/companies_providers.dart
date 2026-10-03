import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/contacts/data/contacts_repository.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/providers/contacts_providers.dart';
import 'package:salesroot/features/contacts/providers/customer_providers.dart';

part 'companies_providers.g.dart';

class CompaniesFilter {
  const CompaniesFilter({
    this.search = '',
    this.customersOnly = false,
    this.industry,
    this.area,
  });

  final String search;
  final bool customersOnly;
  final String? industry;
  final String? area;

  CompanyQuery query(int page) => CompanyQuery(
    search: search,
    customersOnly: customersOnly,
    industry: industry,
    area: area,
    page: page,
  );

  CompaniesFilter copyWith({
    String? search,
    bool? customersOnly,
    String? Function()? industry,
    String? Function()? area,
  }) => CompaniesFilter(
    search: search ?? this.search,
    customersOnly: customersOnly ?? this.customersOnly,
    industry: industry == null ? this.industry : industry(),
    area: area == null ? this.area : area(),
  );
}

@riverpod
class CompaniesFilterNotifier extends _$CompaniesFilterNotifier {
  @override
  CompaniesFilter build() => const CompaniesFilter();

  void search(String term) {
    if (term.trim() == state.search) return;
    state = state.copyWith(search: term.trim());
  }

  void customersOnly(bool value) =>
      state = state.copyWith(customersOnly: value);

  void industry(String? industry) =>
      state = state.copyWith(industry: () => industry);

  void area(String? area) => state = state.copyWith(area: () => area);
}

@riverpod
class CompaniesListNotifier extends _$CompaniesListNotifier {
  @override
  Future<Paged<Company>> build() async {
    final filter = ref.watch(companiesFilterProvider);
    final result = await ref
        .watch(contactsRepositoryProvider)
        .companies(filter.query(1));
    return Paged.first(result, facetKeys: const ['Counts']);
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
          .companies(ref.read(companiesFilterProvider).query(current.page + 1));
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
Future<Company> company(Ref ref, int id) =>
    ref.watch(contactsRepositoryProvider).company(id);

@riverpod
Future<List<Contact>> companyContacts(Ref ref, int id) =>
    ref.watch(contactsRepositoryProvider).companyContacts(id);

@riverpod
Future<List<LinkedLead>> companyLeads(Ref ref, int id) =>
    ref.watch(contactsRepositoryProvider).companyLeads(id);

@riverpod
Future<CompanyLookups> companyLookups(Ref ref) =>
    ref.watch(contactsRepositoryProvider).companyLookups();

/// Saves the company form; [id] 0 creates. A 409 comes back as [Duplicates].
@riverpod
class CompanySaveNotifier extends _$CompanySaveNotifier {
  @override
  FutureOr<SaveOutcome<Company>?> build(int id) => null;

  Future<void> save(CompanyInput input, {bool allowDuplicate = false}) async {
    final repository = ref.read(contactsRepositoryProvider);
    state = const AsyncLoading();
    final next = await AsyncValue.guard<SaveOutcome<Company>?>(() async {
      try {
        final saved = id == 0
            ? await repository.createCompany(
                input,
                allowDuplicate: allowDuplicate,
              )
            : await repository.editCompany(
                id,
                input,
                allowDuplicate: allowDuplicate,
              );
        return Saved(saved);
      } on ApiFailure catch (failure) {
        if (!failure.isConflict) rethrow;
        return Duplicates(
          await repository.companyDuplicates(
            name: input.name,
            phone: input.contactNumber,
            excludeId: id == 0 ? null : id,
          ),
        );
      }
    });
    if (!ref.mounted) return;
    if (next.value case Saved()) {
      ref
        ..invalidate(companiesListProvider)
        ..invalidate(companyProvider)
        ..invalidate(contactsListProvider)
        ..invalidate(contactProvider)
        ..invalidate(customerSummaryProvider);
    }
    state = next;
  }
}

/// Deletes a company or changes its concern persons; screens listen for the
/// [RecordChange] to react.
@riverpod
class CompanyMutationNotifier extends _$CompanyMutationNotifier {
  @override
  FutureOr<RecordChange?> build(int id) => null;

  Future<void> delete() =>
      _run(RecordChange.deleted, (repository) => repository.deleteCompany(id));

  Future<void> setPrimary(int contactId) => _run(
    RecordChange.primarySet,
    (repository) => repository.setPrimaryContact(id, contactId),
  );

  Future<void> detach(int contactId) => _run(
    RecordChange.detached,
    (repository) => repository.detachContact(contactId),
  );

  Future<void> _run(
    RecordChange change,
    Future<void> Function(ContactsRepository repository) action,
  ) async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard<RecordChange?>(() async {
      await action(ref.read(contactsRepositoryProvider));
      return change;
    });
    if (!ref.mounted) return;
    if (next.hasValue) {
      ref
        ..invalidate(companiesListProvider)
        ..invalidate(contactsListProvider)
        ..invalidate(contactProvider);
      if (change != RecordChange.deleted) {
        ref
          ..invalidate(companyProvider(id))
          ..invalidate(companyContactsProvider(id));
      }
    }
    state = next;
  }
}
