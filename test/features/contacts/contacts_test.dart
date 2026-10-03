import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/contacts/models/bd_phone.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/customer.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';
import 'package:salesroot/features/contacts/providers/companies_providers.dart';
import 'package:salesroot/features/contacts/providers/contacts_providers.dart';
import 'package:salesroot/features/contacts/providers/customer_providers.dart';
import 'package:salesroot/features/contacts/providers/import_providers.dart';

Future<ProviderContainer> _container({
  WorkspaceRole role = WorkspaceRole.owner,
}) async {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      seedGraphProvider.overrideWithValue(
        SeedGraph.build(
          workspaceId: 2,
          kind: WorkspaceKind.team,
          memberCount: 25,
          leadCount: 230,
        ),
      ),
      currentRoleProvider.overrideWithValue(role),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(devSettingsProvider.notifier)
      .update((s) => s.copyWith(latency: false));
  return container;
}

void _offline(ProviderContainer container) => container
    .read(devSettingsProvider.notifier)
    .update((s) => s.copyWith(offline: true));

void main() {
  group('BdPhone', () {
    test('accepts the ways people type a mobile number', () {
      expect(BdPhone.mobile('01711-234567'), '+8801711234567');
      expect(BdPhone.mobile('+880 1711 234 567'), '+8801711234567');
      expect(BdPhone.mobile('8801711234567'), '+8801711234567');
      expect(BdPhone.mobile('0171123456'), isNull);
      expect(BdPhone.mobile('01211234567'), isNull);
      expect(BdPhone.any('02-55012345'), '0255012345');
      expect(BdPhone.display('+8801711234567'), '01711 234 567');
    });
  });

  group('contacts list', () {
    test('pages 20 at a time up to the total', () async {
      final container = await _container();
      final sub = container.listen(contactsListProvider, (_, _) {});
      addTearDown(sub.close);

      final first = await container.read(contactsListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.totalCount, greaterThan(100));
      expect(first.facets['GroupCounts']?['All'], first.totalCount);

      await container.read(contactsListProvider.notifier).loadMore();
      final second = container.read(contactsListProvider).requireValue;
      expect(second.items, hasLength(40));
      expect(second.page, 2);
      expect(
        second.items.map((c) => c.id).toSet(),
        hasLength(40),
        reason: 'pages must not overlap',
      );
    });

    test('search, group and letter narrow the list', () async {
      final container = await _container();
      final sub = container.listen(contactsListProvider, (_, _) {});
      addTearDown(sub.close);
      final filter = container.read(contactsFilterProvider.notifier);

      filter.search('Karim Textiles');
      final byCompany = await container.read(contactsListProvider.future);
      expect(byCompany.items, isNotEmpty);
      expect(
        byCompany.items.every((c) => c.companyName == 'Karim Textiles'),
        isTrue,
      );

      filter
        ..search('')
        ..group(ContactGroup.independent);
      final independent = await container.read(contactsListProvider.future);
      expect(independent.items, isNotEmpty);
      expect(independent.items.every((c) => c.isIndependent), isTrue);

      filter
        ..group(ContactGroup.all)
        ..letter('S');
      final letterS = await container.read(contactsListProvider.future);
      expect(letterS.items.every((c) => c.name.startsWith('S')), isTrue);
    });

    test('offline shows as an ApiFailure with status 0', () async {
      final container = await _container();
      _offline(container);
      final sub = container.listen(contactsListProvider, (_, _) {});
      addTearDown(sub.close);

      await expectLater(
        container.read(contactsListProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('contact form', () {
    test('creates a contact and invalidates the list', () async {
      final container = await _container();
      final save = container.read(contactSaveProvider(0).notifier);
      final sub = container.listen(contactSaveProvider(0), (_, _) {});
      addTearDown(sub.close);

      await save.save(
        const ContactInput(
          name: 'Zakir Hossain',
          companyId: 1,
          mobiles: ['01799-000111'],
        ),
      );
      final outcome = container.read(contactSaveProvider(0)).requireValue;
      expect(outcome, isA<Saved<Contact>>());
      final saved = (outcome as Saved<Contact>).value;
      expect(saved.phone, '+8801799000111');
      expect(saved.companyName, 'Karim Textiles');

      final people = await container.read(companyContactsProvider(1).future);
      expect(people.map((c) => c.id), contains(saved.id));
    });

    test('a number already saved answers 409 with the match', () async {
      final container = await _container();
      final graph = container.read(seedGraphProvider);
      final existing = graph.contacts.first;
      final sub = container.listen(contactSaveProvider(0), (_, _) {});
      addTearDown(sub.close);
      final save = container.read(contactSaveProvider(0).notifier);

      final local = '0${existing.phone.substring(4)}';
      await save.save(ContactInput(name: 'Someone else', mobiles: [local]));
      final outcome = container.read(contactSaveProvider(0)).requireValue;
      expect(outcome, isA<Duplicates<Contact>>());
      expect(
        (outcome as Duplicates<Contact>).matches.map((m) => m.id),
        contains(existing.id),
      );

      await save.save(
        ContactInput(name: 'Someone else', mobiles: [local]),
        allowDuplicate: true,
      );
      expect(
        container.read(contactSaveProvider(0)).requireValue,
        isA<Saved<Contact>>(),
      );
    });

    test('an invalid number is a 400 on the mobile field', () async {
      final container = await _container();
      final sub = container.listen(contactSaveProvider(0), (_, _) {});
      addTearDown(sub.close);

      await container
          .read(contactSaveProvider(0).notifier)
          .save(const ContactInput(name: 'Bad', mobiles: ['12345']));
      final error = container.read(contactSaveProvider(0)).error;
      expect(error, isA<ApiFailure>());
      expect((error as ApiFailure).fieldError('Mobiles'), isNotNull);
    });

    test('a duplicate company name answers 409', () async {
      final container = await _container();
      final sub = container.listen(companySaveProvider(0), (_, _) {});
      addTearDown(sub.close);

      await container
          .read(companySaveProvider(0).notifier)
          .save(const CompanyInput(name: '  delta power '));
      final outcome = container.read(companySaveProvider(0)).requireValue;
      expect(outcome, isA<Duplicates<Company>>());
      expect(
        (outcome as Duplicates<Company>).matches.first.name,
        'Delta Power',
      );
    });

    test('a member cannot delete a contact (403)', () async {
      final container = await _container(role: WorkspaceRole.member);
      final sub = container.listen(contactMutationProvider(1), (_, _) {});
      addTearDown(sub.close);

      await container.read(contactMutationProvider(1).notifier).delete();
      final error = container.read(contactMutationProvider(1)).error;
      expect(error, isA<ApiFailure>());
      expect((error as ApiFailure).isForbidden, isTrue);
    });
  });

  group('import from phone', () {
    test('marks saved numbers and imports only the picked ones', () async {
      final container = await _container();
      final sub = container.listen(contactImportProvider, (_, _) {});
      addTearDown(sub.close);

      final state = await container.read(contactImportProvider.future);
      final existing = state.candidates.where((c) => c.exists).toList();
      final fresh = state.candidates.where((c) => !c.exists).toList();
      expect(existing, isNotEmpty);
      expect(fresh.length, greaterThan(2));

      final notifier = container.read(contactImportProvider.notifier)
        ..toggle(existing.first)
        ..toggle(fresh[0])
        ..toggle(fresh[1]);
      expect(container.read(contactImportProvider).requireValue.selected, {
        fresh[0].entry.deviceId,
        fresh[1].entry.deviceId,
      });

      final before =
          (await container
                  .read(contactsRepositoryProvider)
                  .contacts(const ContactQuery()))
              .totalCount;
      await notifier.import();
      final after = container.read(contactImportProvider).requireValue;
      expect(after.imported, 2);
      final total =
          (await container
                  .read(contactsRepositoryProvider)
                  .contacts(const ContactQuery()))
              .totalCount;
      expect(total, before + 2);
    });

    test('select all picks every new entry and then clears', () async {
      final container = await _container();
      final sub = container.listen(contactImportProvider, (_, _) {});
      addTearDown(sub.close);
      final state = await container.read(contactImportProvider.future);
      final notifier = container.read(contactImportProvider.notifier)
        ..toggleAll();
      expect(
        container.read(contactImportProvider).requireValue.selected,
        hasLength(state.newCount),
      );
      notifier.toggleAll();
      expect(
        container.read(contactImportProvider).requireValue.selected,
        isEmpty,
      );
    });
  });

  group('customer 360', () {
    test('every customer\'s totals agree with its documents', () async {
      final container = await _container();
      final graph = container.read(seedGraphProvider);
      var customers = 0;
      for (final company in graph.companies) {
        final summary = await container.read(
          customerSummaryProvider(company.id).future,
        );
        final invoiced = summary.invoices.fold<int>(0, (s, i) => s + i.amount);
        final paid = summary.invoices.fold<int>(0, (s, i) => s + i.paid);
        final collections = summary.events
            .where((e) => e.kind == CustomerEventKind.collection)
            .fold<int>(0, (s, e) => s + (e.amount ?? 0));
        final won = graph.leads.where(
          (l) => l.companyId == company.id && l.stageId == 5,
        );

        expect(summary.totalSales, invoiced);
        expect(summary.collected, paid);
        expect(collections, paid);
        expect(summary.outstanding, summary.totalSales - summary.collected);
        expect(summary.overdue, inInclusiveRange(0, summary.outstanding));
        expect(summary.orders, hasLength(won.length));
        expect(summary.invoices, hasLength(won.length));
        expect(
          summary.openDealValue,
          summary.openDeals.fold<int>(0, (s, l) => s + l.value),
        );
        expect(
          summary.leads.where((l) => l.status == LeadStatus.won),
          hasLength(won.length),
        );

        final detail = await container.read(companyProvider(company.id).future);
        expect(detail.totalSales, summary.totalSales);
        expect(detail.outstanding, summary.outstanding);
        expect(detail.isClient, summary.invoices.isNotEmpty);
        if (detail.isClient) customers++;
      }
      expect(customers, greaterThan(0));
    });

    test('documents upload, list and come back as the same bytes', () async {
      final container = await _container();
      final sub = container.listen(documentMutationProvider(1), (_, _) {});
      addTearDown(sub.close);
      final before = await container.read(customerDocumentsProvider(1).future);

      final bytes = Uint8List.fromList(List.generate(2048, (i) => i % 256));
      await container
          .read(documentMutationProvider(1).notifier)
          .upload(
            DocumentUpload(
              fileName: 'roof.jpg',
              bytes: bytes,
              title: 'Roof photo',
              category: DocumentCategory.photo,
            ),
          );
      expect(
        container.read(documentMutationProvider(1)).value,
        DocumentChange.uploaded,
      );
      final after = await container.read(customerDocumentsProvider(1).future);
      expect(after, hasLength(before.length + 1));
      expect(after.first.title, 'Roof photo');
      final stored = await container
          .read(customerRepositoryProvider)
          .download(after.first.id);
      expect(stored, bytes);
    });
  });
}
