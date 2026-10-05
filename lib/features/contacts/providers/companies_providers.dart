import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/company_detail.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/providers/contacts_providers.dart';
import 'package:salesroot/features/contacts/providers/customer_providers.dart';

part 'companies_providers.g.dart';

class CompaniesFilter {
  const CompaniesFilter({this.search = '', this.customersOnly = false});

  final String search;
  final bool customersOnly;

  CompanyQuery query(int page) =>
      CompanyQuery(search: search, customersOnly: customersOnly, page: page);
}

@riverpod
class CompaniesFilterNotifier extends _$CompaniesFilterNotifier {
  @override
  CompaniesFilter build() => const CompaniesFilter();

  void search(String term) {
    if (term.trim() == state.search) return;
    state = CompaniesFilter(
      search: term.trim(),
      customersOnly: state.customersOnly,
    );
  }

  void customersOnly(bool value) =>
      state = CompaniesFilter(search: state.search, customersOnly: value);
}

@riverpod
class CompaniesListNotifier extends _$CompaniesListNotifier {
  @override
  Future<Paged<Company>> build() async {
    final filter = ref.watch(companiesFilterProvider);
    final result = await ref
        .watch(contactsRepositoryProvider)
        .companies(filter.query(1));
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
          .companies(ref.read(companiesFilterProvider).query(current.page + 1));
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  Future<void> refresh() async {
    ref
      ..invalidate(companyCountsProvider)
      ..invalidateSelf();
    await future;
  }
}

/// How many companies and customers match the search, for the chips.
class CompanyCounts {
  const CompanyCounts({required this.all, required this.customers});

  final int all;
  final int customers;
}

@riverpod
Future<CompanyCounts> companyCounts(Ref ref) async {
  final search = ref.watch(companiesFilterProvider.select((f) => f.search));
  final repository = ref.watch(contactsRepositoryProvider);
  final totals = await Future.wait([
    for (final customersOnly in [false, true])
      repository
          .companies(
            CompanyQuery(search: search, customersOnly: customersOnly, size: 1),
          )
          .then((page) => page.totalCount),
  ]);
  return CompanyCounts(all: totals[0], customers: totals[1]);
}

@riverpod
Future<CompanyDetail> companyDetail(Ref ref, String id) =>
    ref.watch(contactsRepositoryProvider).company(id);

@riverpod
Future<Company> company(Ref ref, String id) async =>
    (await ref.watch(companyDetailProvider(id).future)).company;

@riverpod
Future<List<Contact>> companyContacts(Ref ref, String id) async =>
    (await ref.watch(companyDetailProvider(id).future)).people;

@riverpod
Future<List<LinkedLead>> companyLeads(Ref ref, String id) async =>
    (await ref.watch(companyDetailProvider(id).future)).leads;

@riverpod
Future<ContactsPack> contactsPack(Ref ref) =>
    ref.watch(contactsRepositoryProvider).pack();

/// Saves the company form; an empty [id] creates. A 409 comes back as
/// [Duplicates].
@riverpod
class CompanySaveNotifier extends _$CompanySaveNotifier {
  @override
  FutureOr<SaveOutcome<Company>?> build(String id) => null;

  Future<void> save(CompanyInput input, {bool allowDuplicate = false}) async {
    final repository = ref.read(contactsRepositoryProvider);
    state = const AsyncLoading();
    final next = await AsyncValue.guard<SaveOutcome<Company>?>(() async {
      try {
        final saved = id.isEmpty
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
            excludeId: id.isEmpty ? null : id,
          ),
        );
      }
    });
    if (!ref.mounted) return;
    if (next.value case Saved()) {
      ref
        ..invalidate(companiesListProvider)
        ..invalidate(companyCountsProvider)
        ..invalidate(companyDetailProvider)
        ..invalidate(contactsListProvider)
        ..invalidate(contactDetailProvider)
        ..invalidate(customerSummaryProvider);
    }
    state = next;
  }
}

/// Deletes a company; true once it is gone.
@riverpod
class CompanyMutationNotifier extends _$CompanyMutationNotifier {
  @override
  FutureOr<bool> build(String id) => false;

  Future<void> delete() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() async {
      await ref.read(contactsRepositoryProvider).deleteCompany(id);
      return true;
    });
    if (!ref.mounted) return;
    if (next.hasValue) {
      ref
        ..invalidate(companiesListProvider)
        ..invalidate(companyCountsProvider)
        ..invalidate(contactsListProvider)
        ..invalidate(contactDetailProvider);
    }
    state = next;
  }
}
