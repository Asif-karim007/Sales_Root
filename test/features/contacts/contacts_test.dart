import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/app_theme.dart';
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
import 'package:salesroot/features/contacts/view/companies_screen.dart';
import 'package:salesroot/features/contacts/view/company_detail_screen.dart';
import 'package:salesroot/features/contacts/view/company_form_screen.dart';
import 'package:salesroot/features/contacts/view/contact_detail_screen.dart';
import 'package:salesroot/features/contacts/view/contact_form_screen.dart';
import 'package:salesroot/features/contacts/view/contact_import_screen.dart';
import 'package:salesroot/features/contacts/view/contacts_screen.dart';
import 'package:salesroot/features/contacts/view/customer_360_screen.dart';
import 'package:salesroot/features/contacts/view/customer_documents_screen.dart';
import 'package:salesroot/translations/translations.dart';

import '../../helpers/api_stub.dart';

const rahimId = '01a10101-8657-7f15-8630-b08119f1ae61';
const greenId = '01a10101-865d-7e81-90c1-c811923c2adf';
const mrRahimId = '01a10101-865e-7196-8bd5-2cf8d667f937';
const probeId = '01a10ced-8323-7b2a-a4f2-ab807a5a8af4';

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
    test('parses the recorded list and asks for the first page', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      listenTo(container, contactsListProvider);

      final paged = await container.read(contactsListProvider.future);

      expect(paged.items.map((c) => c.name), [
        'Farhana Islam',
        'Mr Rahim',
        'Sumaiya Akter',
      ]);
      final rahim = paged.items[1];
      expect(rahim.id, mrRahimId);
      expect(rahim.phone, '+8801811000010');
      expect(rahim.designation, 'Owner');
      expect(rahim.companyId, rahimId);
      expect(rahim.companyName, 'Rahim Traders');
      expect(rahim.ownerName, 'Rafi Ahmed');
      expect(rahim.isIndependent, isFalse);
      expect(paged.totalCount, 3);

      final query = stub.last('GET', 'contacts')?.queryParameters;
      expect(query?['offset'], 0);
      expect(query?['limit'], 20);
      expect(query?.containsKey('q'), isFalse);
    });

    test('pages by offset up to the total', () async {
      final stub = contactsStub()..on('GET', 'contacts', pagedContacts(45));
      final container = await contactsContainer(stub);
      listenTo(container, contactsListProvider);

      final first = await container.read(contactsListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.hasMore, isTrue);

      final notifier = container.read(contactsListProvider.notifier);
      await notifier.loadMore();
      expect(stub.last('GET', 'contacts')?.queryParameters['offset'], 20);
      await notifier.loadMore();
      final all = container.read(contactsListProvider).requireValue;
      expect(all.items.map((c) => c.id).toSet(), hasLength(45));
      expect(all.hasMore, isFalse);
    });

    test('a search rebuilds the list from page 1 with q', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      listenTo(container, contactsListProvider);
      await container.read(contactsListProvider.future);

      container.read(contactsSearchProvider.notifier).search(' Rahim ');
      await container.read(contactsListProvider.future);

      final query = stub.last('GET', 'contacts')?.queryParameters;
      expect(query?['q'], 'Rahim');
      expect(query?['offset'], 0);
    });

    test('offline shows as an ApiFailure with status 0', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      stub.offline = true;
      listenTo(container, contactsListProvider);

      await expectLater(
        container.read(contactsListProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('contact detail', () {
    test('the contact comes with their leads and activity', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      listenTo(container, contactDetailProvider(mrRahimId));

      final contact = await container.read(contactProvider(mrRahimId).future);
      final leads = await container.read(
        contactLeadsProvider(mrRahimId).future,
      );

      expect(contact.name, 'Mr Rahim');
      expect(leads.single.title, '50 cartons soap · November');
      expect(leads.single.status, LeadStatus.open);
      expect(leads.single.value, 206400);
      expect(leads.single.stage.of(false), 'Sample given');
      expect(leads.single.stage.of(true), 'নমুনা দেওয়া');
      expect(
        await container.read(contactActivityProvider(mrRahimId).future),
        isEmpty,
      );
      expect(
        stub.requests.where((r) => r.path.startsWith('contacts/')),
        hasLength(1),
      );
    });

    test('activity rows read the type, body and author', () {
      final timeline = fixtureMap('contacts_company')['timeline'] as List;
      final call = ContactActivity.fromJson(
        timeline.first as Map<String, dynamic>,
      );
      expect(call.type, ActivityType.call);
      expect(call.note, 'Wants 5% discount, decision next week');
      expect(call.byName, 'Rafi Ahmed');
      expect(call.leadId, '01a10101-866a-7007-90bc-2326bcdb9d50');
      expect(call.on.toUtc(), DateTime.utc(2026, 10, 2, 9, 3, 59, 542, 506));
    });
  });

  group('contact form', () {
    test('creates a contact from the form, omitting empty fields', () async {
      final stub = contactsStub()
        ..on('POST', 'contacts', fixture('contacts_created'));
      final container = await contactsContainer(stub);
      listenTo(container, contactsListProvider);
      await container.read(contactsListProvider.future);
      final lists = stub.requests.length;

      listenTo(container, contactSaveProvider(''));
      await container
          .read(contactSaveProvider('').notifier)
          .save(
            ContactInput(
              name: ' [test] Contact probe ',
              mobiles: const ['+8801799000222'],
              designation: '  ',
              dateOfBirth: DateTime(1990, 5, 1),
            ),
          );

      final outcome = container.read(contactSaveProvider('')).value;
      expect((outcome as Saved<Contact>).value.id, isNotEmpty);
      expect(stub.lastBody('POST', 'contacts'), {
        'name': '[test] Contact probe',
        'phone': '+8801799000222',
        'birthday': '1990-05-01',
        'tags': <Object>[],
      });
      await container.read(contactsListProvider.future);
      expect(stub.requests.length, greaterThan(lists + 1));
    });

    test('an edit sends cleared fields as empty strings', () async {
      final stub = contactsStub()
        ..on('PATCH', 'contacts/{id}', fixture('contacts_created'));
      final container = await contactsContainer(stub);

      listenTo(container, contactSaveProvider(mrRahimId));
      await container
          .read(contactSaveProvider(mrRahimId).notifier)
          .save(
            const ContactInput(
              name: 'Mr Rahim',
              companyId: rahimId,
              mobiles: ['+8801811000010'],
            ),
          );

      expect(stub.last('PATCH', 'contacts/{id}')?.path, 'contacts/$mrRahimId');
      expect(stub.lastBody('PATCH', 'contacts/{id}'), {
        'name': 'Mr Rahim',
        'phone': '+8801811000010',
        'phone2': '',
        'email': '',
        'designation': '',
        'companyId': rahimId,
        'address': '',
        'notes': '',
        'tags': <Object>[],
      });
    });

    test('a number already saved comes back with the match', () async {
      final stub = contactsStub()
        ..on(
          'POST',
          'contacts',
          StubReply(422, fixtureMap('contacts_duplicate')),
        );
      final container = await contactsContainer(stub);

      listenTo(container, contactSaveProvider(''));
      await container
          .read(contactSaveProvider('').notifier)
          .save(const ContactInput(name: 'Rahim', mobiles: ['+8801811000010']));

      final outcome = container.read(contactSaveProvider('')).value;
      final matches = (outcome as Duplicates<Contact>).matches;
      expect(matches.single.id, mrRahimId);
      expect(matches.single.name, 'Mr Rahim');
      expect(matches.single.subtitle, 'Rahim Traders');
      expect(stub.last('GET', 'contacts')?.queryParameters['q'], '01811000010');
    });

    test('an invalid number is a 422 on the phone field', () async {
      final stub = contactsStub()
        ..fail(
          'POST',
          'contacts',
          422,
          message: 'Enter an 11-digit mobile number (01…)',
          field: 'phone',
          code: 'V-002',
        );
      final container = await contactsContainer(stub);

      listenTo(container, contactSaveProvider(''));
      await container
          .read(contactSaveProvider('').notifier)
          .save(const ContactInput(name: 'X', mobiles: ['123']));

      final error = container.read(contactSaveProvider('')).error;
      expect(error, isA<ApiFailure>());
      final failure = error as ApiFailure;
      expect(failure.isValidation, isTrue);
      expect(failure.fieldError('phone'), contains('11-digit'));
    });

    test('a delete the role lacks is a 403', () async {
      final stub = contactsStub()
        ..fail('DELETE', 'contacts/{id}', 403, message: 'No permission');
      final container = await contactsContainer(stub);

      listenTo(container, contactMutationProvider(mrRahimId));
      await container
          .read(contactMutationProvider(mrRahimId).notifier)
          .delete();

      final error = container.read(contactMutationProvider(mrRahimId)).error;
      expect((error as ApiFailure).isForbidden, isTrue);
    });

    test('a delete removes the contact', () async {
      final stub = contactsStub()
        ..on('DELETE', 'contacts/{id}', null, status: 204);
      final container = await contactsContainer(stub);

      listenTo(container, contactMutationProvider(mrRahimId));
      await container
          .read(contactMutationProvider(mrRahimId).notifier)
          .delete();

      expect(container.read(contactMutationProvider(mrRahimId)).value, isTrue);
      expect(stub.last('DELETE', 'contacts/{id}')?.path, 'contacts/$mrRahimId');
    });
  });

  group('companies', () {
    test('parses the recorded list', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      listenTo(container, companiesListProvider);

      final paged = await container.read(companiesListProvider.future);

      final rahim = paged.items.firstWhere((c) => c.id == rahimId);
      expect(rahim.name, 'Rahim Traders');
      expect(rahim.isClient, isTrue);
      expect(rahim.type, 'retail');
      expect(rahim.area, 'Mirpur 10');
      expect(rahim.district, 'Dhaka');
      expect(rahim.contactCount, 2);
      expect(rahim.openLeadCount, 1);
      expect(rahim.outstanding, 68000);
      expect(rahim.overdue, 68000);
      expect(rahim.creditLimit, 200000);
      expect(rahim.creditDays, 15);
      expect(rahim.custom['route'], 'Mirpur-A');
      expect(rahim.hasLocation, isTrue);
    });

    test('the customers chip sends customersOnly', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      listenTo(container, companiesListProvider);
      await container.read(companiesListProvider.future);
      expect(
        stub.last('GET', 'companies')?.queryParameters['customersOnly'],
        isNull,
      );

      container.read(companiesFilterProvider.notifier).customersOnly(true);
      await container.read(companiesListProvider.future);

      final query = stub.last('GET', 'companies')?.queryParameters;
      expect(query?['customersOnly'], true);
      expect(query?['offset'], 0);
    });

    test('the chip counts are each total', () async {
      final stub = contactsStub()
        ..on(
          'GET',
          'companies',
          (RequestOptions r) => {
            'items': <Object>[],
            'total': r.queryParameters['customersOnly'] == true ? 3 : 5,
            'offset': 0,
            'limit': 1,
          },
        );
      final container = await contactsContainer(stub);
      listenTo(container, companyCountsProvider);

      final counts = await container.read(companyCountsProvider.future);

      expect(counts.all, 5);
      expect(counts.customers, 3);
      expect(
        stub.requests
            .where((r) => r.path == 'companies')
            .every((r) => r.queryParameters['limit'] == 1),
        isTrue,
      );
    });

    test('the detail carries people, leads and the company', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      listenTo(container, companyDetailProvider(rahimId));

      final people = await container.read(
        companyContactsProvider(rahimId).future,
      );
      final leads = await container.read(companyLeadsProvider(rahimId).future);
      final company = await container.read(companyProvider(rahimId).future);

      expect(people.map((p) => p.name), ['Mr Rahim', 'Sumaiya Akter']);
      expect(people.first.companyId, rahimId);
      expect(people.first.companyName, 'Rahim Traders');
      expect(people.last.phone, '+8801911000020');
      expect(leads.single.title, '50 cartons soap · November');
      expect(company.name, 'Rahim Traders');
    });

    test('the pack names companies and adds their fields', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      listenTo(container, contactsPackProvider);

      final pack = await container.read(contactsPackProvider.future);

      expect(pack.companyTerm?.of(false), 'Outlet');
      expect(pack.companyTerm?.of(true), 'আউটলেট');
      expect(pack.contactTerm?.of(false), 'Shop owner');
      expect(pack.companyFields.map((f) => f.key), [
        'outletType',
        'route',
        'shopSize',
      ]);
      expect(pack.companyFields.first.label.of(false), 'Outlet type');
      expect(pack.companyFields.first.options, [
        'retail',
        'wholesale',
        'modern_trade',
      ]);
      expect(pack.companyFields[1].options, isEmpty);
    });

    test('a duplicate number offers the match, then saves anyway', () async {
      final stub = contactsStub()
        ..on(
          'POST',
          'companies',
          (RequestOptions r) => sent(r)['allowDuplicate'] == true
              ? (fixture('contacts_companies')['items'] as List).first
              : StubReply(422, fixtureMap('contacts_company_duplicate')),
        );
      final container = await contactsContainer(stub);
      listenTo(container, companySaveProvider(''));
      final notifier = container.read(companySaveProvider('').notifier);
      const input = CompanyInput(
        name: '[test] Co probe',
        contactNumber: '+8801811000010',
      );

      await notifier.save(input);
      final outcome = container.read(companySaveProvider('')).value;
      final match = (outcome as Duplicates<Company>).matches.single;
      expect(match.id, rahimId);
      expect(match.isCompany, isTrue);
      expect(
        stub.last('GET', 'companies')?.queryParameters['q'],
        '01811000010',
      );

      await notifier.save(input, allowDuplicate: true);
      expect(
        container.read(companySaveProvider('')).value,
        isA<Saved<Company>>(),
      );
      expect(stub.lastBody('POST', 'companies'), {
        'name': '[test] Co probe',
        'phone': '+8801811000010',
        'allowDuplicate': true,
      });
    });

    test('an edit sends the fields and company field values', () async {
      final stub = contactsStub()
        ..on(
          'PATCH',
          'companies/{id}',
          (fixture('contacts_company') as Map)['company'],
        );
      final container = await contactsContainer(stub);

      listenTo(container, companySaveProvider(rahimId));
      await container
          .read(companySaveProvider(rahimId).notifier)
          .save(
            const CompanyInput(
              name: 'Rahim Traders',
              area: 'Mirpur 10',
              creditLimit: 200000,
              creditDays: 15,
              custom: {'route': 'Mirpur-B', 'shopSize': ''},
            ),
          );

      expect(stub.lastBody('PATCH', 'companies/{id}'), {
        'name': 'Rahim Traders',
        'phone': '',
        'email': '',
        'website': '',
        'address': '',
        'area': 'Mirpur 10',
        'creditLimit': 200000.0,
        'creditDays': 15,
        'notes': '',
        'custom': {'route': 'Mirpur-B', 'shopSize': ''},
      });
    });

    test('an executive cannot delete a company (403)', () async {
      final stub = contactsStub()
        ..fail('DELETE', 'companies/{id}', 403, message: 'No permission');
      final container = await contactsContainer(stub);

      listenTo(container, companyMutationProvider(rahimId));
      await container.read(companyMutationProvider(rahimId).notifier).delete();

      final error = container.read(companyMutationProvider(rahimId)).error;
      expect((error as ApiFailure).isForbidden, isTrue);
    });
  });

  group('customer 360', () {
    test('totals come from the invoices and payments', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      listenTo(container, customerSummaryProvider(greenId));

      final summary = await container.read(
        customerSummaryProvider(greenId).future,
      );

      expect(summary.companyName, 'Green Agro Ltd.');
      expect(summary.totalSales, 100000);
      expect(summary.collected, 50000);
      expect(summary.outstanding, 50000);
      expect(summary.overdue, 0);
      expect(summary.invoices.single.number, 'INV-2026-00001');
      expect(summary.invoices.single.due, 50000);
      expect(summary.orders.single.number, 'SO-2026-00001');
      expect(summary.payments.single.method, 'bkash');
      final kinds = summary.events.map((e) => e.kind).toSet();
      expect(
        kinds,
        containsAll([
          CustomerEventKind.collection,
          CustomerEventKind.invoice,
          CustomerEventKind.order,
          CustomerEventKind.delivery,
        ]),
      );
      final times = summary.events.map((e) => e.on).toList();
      for (var i = 1; i < times.length; i++) {
        expect(times[i - 1].isBefore(times[i]), isFalse);
      }

      final invoices = stub.last('GET', 'invoices')?.queryParameters;
      expect(invoices?['companyId'], greenId);
      expect(invoices?['limit'], 100);
      expect(stub.last('GET', 'quotes')?.queryParameters['companyId'], greenId);
    });

    test('lists the role may not see count as empty', () async {
      final stub = contactsStub()
        ..fail('GET', 'invoices', 403)
        ..fail('GET', 'quotes', 403);
      final container = await contactsContainer(stub);
      listenTo(container, customerSummaryProvider(rahimId));

      final summary = await container.read(
        customerSummaryProvider(rahimId).future,
      );

      expect(summary.invoices, isEmpty);
      expect(summary.quotations, isEmpty);
      expect(summary.totalSales, 0);
      expect(summary.openDealValue, 206400);
      expect(summary.events.map((e) => e.kind), [
        CustomerEventKind.call,
        CustomerEventKind.note,
      ]);
    });

    test('a failed company read fails the summary', () async {
      final stub = contactsStub()..fail('GET', 'companies/{id}', 404);
      final container = await contactsContainer(stub);
      listenTo(container, customerSummaryProvider(rahimId));

      await expectLater(
        container.read(customerSummaryProvider(rahimId).future),
        throwsA(isA<ApiFailure>().having((f) => f.isNotFound, '404', true)),
      );
    });
  });

  group('customer documents', () {
    test('lists the company files, newest first', () async {
      final stub = contactsStub();
      final container = await contactsContainer(stub);
      listenTo(container, customerDocumentsProvider(probeId));

      final documents = await container.read(
        customerDocumentsProvider(probeId).future,
      );

      expect(documents.map((d) => d.fileName), [
        'c-entityType.txt',
        'probe.txt',
      ]);
      expect(documents.first.sizeInBytes, 4);
      expect(documents.first.isPhoto, isFalse);
      expect(
        documents.last.key,
        endsWith('1b31204366224721b403ac5102f078b1.txt'),
      );
    });

    test('an upload is attached to the company and the list reloads', () async {
      final stub = contactsStub()
        ..on('POST', 'files', fixture('contacts_uploaded'));
      final container = await contactsContainer(stub);
      listenTo(container, customerDocumentsProvider(probeId));
      await container.read(customerDocumentsProvider(probeId).future);
      final reads = stub.requests.where((r) => r.method == 'GET').length;

      listenTo(container, documentUploadProvider(probeId));
      await container
          .read(documentUploadProvider(probeId).notifier)
          .upload(
            DocumentUpload(
              fileName: 'Shop photo.jpg',
              bytes: Uint8List.fromList([1, 2, 3]),
            ),
          );
      await container.read(customerDocumentsProvider(probeId).future);

      expect(container.read(documentUploadProvider(probeId)).value, isTrue);
      final form = stub.last('POST', 'files')?.data as FormData;
      expect(Map.fromEntries(form.fields), {
        'entityType': 'company',
        'entityId': probeId,
      });
      expect(form.files.single.value.filename, 'Shop photo.jpg');
      expect(
        stub.requests.where((r) => r.method == 'GET').length,
        greaterThan(reads),
      );
    });

    test('a full storage quota fails the upload with 402', () async {
      final stub = contactsStub()..fail('POST', 'files', 402);
      final container = await contactsContainer(stub);

      listenTo(container, documentUploadProvider(probeId));
      await container
          .read(documentUploadProvider(probeId).notifier)
          .upload(DocumentUpload(fileName: 'a.pdf', bytes: Uint8List(1)));

      final error = container.read(documentUploadProvider(probeId)).error;
      expect((error as ApiFailure).isQuota, isTrue);
    });

    test('a file downloads by its storage key', () async {
      final stub = contactsStub()..on('GET', 'files/{a}/{b}/{c}/{d}', 'test');
      final container = await contactsContainer(stub);
      final document = CustomerDocument.fromJson(
        (fixtureMap('contacts_files')['files'] as List).first
            as Map<String, dynamic>,
      );

      final bytes = await container
          .read(customerRepositoryProvider)
          .download(document);

      expect(utf8.decode(bytes), '"test"');
      expect(
        stub.last('GET', 'files/{a}/{b}/{c}/{d}')?.path,
        'files/01a10101-8645-7750-8f77-adcfb74cb05f/2026/10/'
        '1b31204366224721b403ac5102f078b1.txt',
      );
    });
  });

  group('import from phone', () {
    test('marks saved numbers and imports only the picked ones', () async {
      final stub = contactsStub()
        ..on('GET', 'contacts', savedPhoneBook())
        ..on(
          'POST',
          'contacts',
          (RequestOptions r) => sent(r)['phone'] == '+8801912345678'
              ? StubReply(422, fixtureMap('contacts_duplicate'))
              : fixture('contacts_created'),
        );
      final container = await contactsContainer(stub);
      listenTo(container, contactImportProvider);

      final state = await container.read(contactImportProvider.future);
      final rahman = state.candidates.firstWhere(
        (c) => c.entry.name == 'Rahman Hardware',
      );
      expect(rahman.existingContactId, 'saved-rahman');
      expect(state.newCount, state.candidates.length - 1);

      final notifier = container.read(contactImportProvider.notifier);
      for (final name in ['Rahima Begum', 'Rashed Sarker', 'Rahman Hardware']) {
        notifier.toggle(
          state.candidates.firstWhere((c) => c.entry.name == name),
        );
      }
      expect(
        container.read(contactImportProvider).value?.selected,
        hasLength(2),
      );

      await notifier.import();

      expect(container.read(contactImportProvider).value?.imported, 1);
      final posted = [
        for (final r in stub.requests)
          if (r.method == 'POST') sent(r)['phone'],
      ];
      expect(posted, ['+8801912345678', '+8801611444555']);
    });

    test('select all picks every new entry and then clears', () async {
      final stub = contactsStub()..on('GET', 'contacts', savedPhoneBook());
      final container = await contactsContainer(stub);
      listenTo(container, contactImportProvider);
      final state = await container.read(contactImportProvider.future);

      final notifier = container.read(contactImportProvider.notifier)
        ..toggleAll();
      expect(
        container.read(contactImportProvider).value?.selected,
        hasLength(state.newCount),
      );

      notifier.toggleAll();
      expect(container.read(contactImportProvider).value?.selected, isEmpty);
    });
  });

  group('screens render', () {
    Future<void> pump(
      WidgetTester tester,
      ProviderContainer container,
      Widget screen,
      Locale locale,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: screen,
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    final screens = <String, (Widget, String?)>{
      'contacts': (const ContactsScreen(), 'Sumaiya Akter'),
      'companies': (const CompaniesScreen(), 'Green Agro Ltd.'),
      'contact detail': (
        const ContactDetailScreen(id: mrRahimId),
        '50 cartons soap',
      ),
      'company detail': (
        const CompanyDetailScreen(id: rahimId),
        'Route / Beat',
      ),
      'new contact': (
        const ContactFormScreen(prefill: ContactPrefill(companyId: rahimId)),
        'Outlet',
      ),
      'edit contact': (const ContactFormScreen(id: mrRahimId), 'Mr Rahim'),
      'new company': (const CompanyFormScreen(), 'Outlet type'),
      'edit company': (const CompanyFormScreen(id: rahimId), 'Mirpur-A'),
      'customer 360': (
        const Customer360Screen(companyId: greenId),
        'SO-2026-00001',
      ),
      'documents': (
        const CustomerDocumentsScreen(companyId: probeId),
        'probe.txt',
      ),
      'import': (const ContactImportScreen(), 'Rahima Begum'),
    };

    for (final locale in [english, bangla]) {
      for (final MapEntry(key: name, value: (screen, text))
          in screens.entries) {
        testWidgets('$name in ${locale.languageCode}', (tester) async {
          final container = await tester.runAsync(
            () => contactsContainer(contactsStub(), fullAccess: true),
          );
          if (container == null) return;

          await pump(tester, container, screen, locale);

          expect(tester.takeException(), isNull);
          if (locale == english && text != null) {
            expect(find.textContaining(text), findsWidgets);
          }
        });
      }
    }
  });
}

/// The contacts screens' endpoints, answering from the recorded fixtures.
ApiStub contactsStub() => ApiStub()
  ..on('GET', 'contacts', fixture('contacts_list'))
  ..on('GET', 'contacts/{id}', fixture('contacts_detail'))
  ..on('GET', 'companies', fixture('contacts_companies'))
  ..on('GET', 'companies/{id}', (RequestOptions r) {
    final id = r.uri.pathSegments.last;
    if (id == greenId) return fixture('contacts_customer');
    final rahim = fixtureMap('contacts_company');
    return id == probeId ? {...rahim, ...fixtureMap('contacts_files')} : rahim;
  })
  ..on('GET', 'workspaces/current', fixture('contacts_workspace'))
  ..on('GET', 'invoices', fixture('contacts_invoices'))
  ..on('GET', 'quotes', fixture('contacts_quotes'));

/// A signed-in container over [stub] as Rafi, an executive, with the
/// workspace loaded.
Future<ProviderContainer> contactsContainer(
  ApiStub stub, {
  bool fullAccess = false,
}) async {
  final container = await apiContainer(
    stub,
    me: meWith(role: 'executive', level: 'standard'),
    overrides: [
      if (fullAccess)
        moduleAccessProvider.overrideWith(
          (ref, module) => const ModuleAccess(
            canView: true,
            canAdd: true,
            canEdit: true,
            canDelete: true,
            canApprove: true,
            canExport: true,
          ),
        ),
    ],
  );
  await container.read(workspacesProvider.future);
  return container;
}

/// The JSON body of [request].
Map<String, dynamic> sent(RequestOptions request) {
  final data = request.data;
  if (data is Map<String, dynamic>) return data;
  return jsonDecode(data as String) as Map<String, dynamic>;
}

void listenTo(ProviderContainer container, ProviderListenable<Object?> p) {
  final sub = container.listen(p, (_, _) {});
  addTearDown(sub.close);
}

Map<String, dynamic> contactRow() =>
    (fixtureMap('contacts_list')['items'] as List).first
        as Map<String, dynamic>;

/// `GET contacts` over [total] copies of a recorded row, honouring the
/// offset and limit.
StubAnswer pagedContacts(int total) => (RequestOptions r) {
  final offset = r.queryParameters['offset'] as int;
  final limit = r.queryParameters['limit'] as int;
  final end = (offset + limit).clamp(0, total);
  return {
    'items': [
      for (var i = offset; i < end; i++) {...contactRow(), 'id': 'contact-$i'},
    ],
    'total': total,
    'offset': offset,
    'limit': limit,
  };
};

/// One saved contact whose number the sample phone book has, written the
/// way the server stores it.
Map<String, dynamic> savedPhoneBook() => {
  'items': [
    {
      ...contactRow(),
      'id': 'saved-rahman',
      'name': 'Rahman Hardware',
      'phone': '+8801711987654',
    },
  ],
  'total': 1,
  'offset': 0,
  'limit': 200,
};
