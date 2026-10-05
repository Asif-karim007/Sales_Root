import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/settings/data/csv_parser.dart';
import 'package:salesroot/features/settings/models/csv_import.dart';
import 'package:salesroot/features/settings/providers/import_providers.dart';

import '../../helpers/api_stub.dart';
import 'settings_test_setup.dart';

void main() {
  group('parseCsv', () {
    test('splits plain rows on LF and CRLF', () {
      expect(parseCsv('a,b\r\n1,2\n3,4'), [
        ['a', 'b'],
        ['1', '2'],
        ['3', '4'],
      ]);
    });

    test('keeps commas inside quotes', () {
      expect(parseCsv('name,company\n"Hossain, Karim","Karim Textiles, Ltd"'), [
        ['name', 'company'],
        ['Hossain, Karim', 'Karim Textiles, Ltd'],
      ]);
    });

    test('keeps line breaks inside quotes', () {
      expect(parseCsv('name,note\nRahim,"Roof 1,800 sq ft\r\nwants 5kW"\n'), [
        ['name', 'note'],
        ['Rahim', 'Roof 1,800 sq ft\r\nwants 5kW'],
      ]);
    });

    test('reads doubled quotes as one', () {
      expect(parseCsv('note\n"He said ""call me tomorrow"""'), [
        ['note'],
        ['He said "call me tomorrow"'],
      ]);
    });

    test('keeps empty fields and drops blank lines and the BOM', () {
      expect(parseCsv('﻿a,b,c\n\n1,,3\n,,\n'), [
        ['a', 'b', 'c'],
        ['1', '', '3'],
        ['', '', ''],
      ]);
    });

    test('reads Bangla text', () {
      expect(parseCsv('নাম,মোবাইল\nকরিম,০১৭১১'), [
        ['নাম', 'মোবাইল'],
        ['করিম', '০১৭১১'],
      ]);
    });
  });

  test('readCsvTable pads short rows and needs a header', () {
    final table = readCsvTable(
      'a.csv',
      utf8.encode('Name,Phone,Notes\nRahim,017'),
    );

    expect(table?.headers, ['Name', 'Phone', 'Notes']);
    expect(table?.rows.single, ['Rahim', '017', '']);
    expect(readCsvTable('empty.csv', const []), isNull);
  });

  test('normalizePhone matches local and +880 forms', () {
    expect(normalizePhone('+880 1711-234567'), '1711234567');
    expect(normalizePhone('01711234567'), '1711234567');
  });

  test('headers map to customer fields by name', () {
    expect(ImportField.forHeader(' Phone '), ImportField.phone);
    expect(ImportField.forHeader('Mobile'), ImportField.phone);
    expect(ImportField.forHeader('Shop'), ImportField.name);
    expect(ImportField.forHeader('এলাকা'), ImportField.area);
    expect(ImportField.forHeader('Notes'), ImportField.note);
    expect(ImportField.forHeader('Fax'), ImportField.skip);
  });

  group('importing', () {
    const csv =
        'Name,Phone,Area,Notes\n'
        'Rahim Traders,01811000010,Mirpur 10,"Roof, 2 floors"\n'
        'Karim Store,01811000011,Mirpur 11,\n'
        'Karim Store again,+8801811000011,Mirpur 11,\n';

    test('a file is checked by a dry run, then imported', () async {
      final stub = settingsStub()..on('POST', 'companies/import', const {});
      final container = await settingsContainer(stub, role: 'owner');
      listenTo(container, csvImportProvider);
      final notifier = container.read(csvImportProvider.notifier);

      await notifier.load('outlets.csv', utf8.encode(csv));
      final loaded = container.read(csvImportProvider);

      expect(loaded.mapping, [
        ImportField.name,
        ImportField.phone,
        ImportField.area,
        ImportField.note,
      ]);
      expect(loaded.repeatedRows, {2});
      expect(loaded.check.value?.total, 3);
      final check = stub.lastBody('POST', 'companies/import');
      expect(check['commit'], isFalse);
      expect((check['rows'] as List).first, {
        'name': 'Rahim Traders',
        'phone': '01811000010',
        'area': 'Mirpur 10',
        'notes': 'Roof, 2 floors',
      });
      expect((check['rows'] as List)[1], {
        'name': 'Karim Store',
        'phone': '01811000011',
        'area': 'Mirpur 11',
      });

      await notifier.start();

      expect(stub.lastBody('POST', 'companies/import')['commit'], isTrue);
      expect(container.read(csvImportProvider).result?.total, 3);
    });

    test('without the import right the check and the import fail', () async {
      final stub = settingsStub()
        ..on(
          'POST',
          'companies/import',
          fixture('settings_forbidden'),
          status: 403,
        );
      final container = await settingsContainer(stub);
      listenTo(container, csvImportProvider);
      final notifier = container.read(csvImportProvider.notifier);

      await notifier.load('outlets.csv', utf8.encode(csv));
      expect(
        container.read(csvImportProvider).check,
        isA<AsyncError<ImportResult?>>(),
      );

      await notifier.start();
      final state = container.read(csvImportProvider);
      expect(state.failure?.isForbidden, isTrue);
      expect(state.result, isNull);
      expect(state.canStart, isTrue);
    });

    test('unmapping the name column blocks the import', () async {
      final stub = settingsStub()..on('POST', 'companies/import', const {});
      final container = await settingsContainer(stub, role: 'owner');
      listenTo(container, csvImportProvider);
      final notifier = container.read(csvImportProvider.notifier);

      await notifier.load('a.csv', utf8.encode('Name,Phone\nRahim,0171100'));
      await notifier.map(0, ImportField.skip);

      final state = container.read(csvImportProvider);
      expect(state.missing, [ImportField.name]);
      expect(state.canStart, isFalse);
      expect(state.check.value, isNull);
    });
  });
}
