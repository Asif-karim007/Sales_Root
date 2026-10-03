import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/settings/data/csv_parser.dart';
import 'package:salesroot/features/settings/models/csv_import.dart';
import 'package:salesroot/features/settings/providers/import_providers.dart';

import 'settings_test_utils.dart';

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

  test('headers map to lead fields by name', () {
    expect(ImportField.forHeader(' Phone '), ImportField.mobile);
    expect(ImportField.forHeader('Notes'), ImportField.note);
    expect(ImportField.forHeader('Fax'), ImportField.skip);
  });

  test('loading a file maps columns, flags duplicates and imports', () async {
    final container = await signedInContainer(role: WorkspaceRole.owner);
    addTearDown(container.dispose);
    keepAlive(container, csvImportProvider);
    final saved = container.read(fakeBackendProvider).graph.contacts.first;
    final csv = [
      'Name,Phone,Company,Stage,Value,Source,Notes',
      'Karim Textiles,${saved.phone},Karim Textiles Ltd,Interested,240000,Fair,"Roof, 2 floors"',
      'Delta Power,01811000111,Delta Power,Contacted,120000,Referral,',
      'Delta Power again,+8801811000111,Delta Power,Contacted,90000,Referral,',
      ',01911000222,No name Ltd,,,,',
    ].join('\n');
    final notifier = container.read(csvImportProvider.notifier);

    await notifier.load('leads_sept.csv', utf8.encode(csv));
    final loaded = container.read(csvImportProvider);

    expect(loaded.mapping, [
      ImportField.name,
      ImportField.mobile,
      ImportField.company,
      ImportField.stage,
      ImportField.value,
      ImportField.source,
      ImportField.note,
    ]);
    expect(loaded.duplicates.value, {0, 2});
    expect(loaded.canStart, isTrue);

    await notifier.start();
    final job = container.read(csvImportProvider).job;

    expect(job?.done, isTrue);
    expect(job?.imported, 3);
    expect(job?.duplicates, 2);
    expect(job?.failed, 1);
  });

  test('unmapping the mobile column blocks the import', () async {
    final container = await signedInContainer(role: WorkspaceRole.owner);
    addTearDown(container.dispose);
    keepAlive(container, csvImportProvider);
    final notifier = container.read(csvImportProvider.notifier);

    await notifier.load('a.csv', utf8.encode('Name,Phone\nRahim,01711000000'));
    await notifier.map(1, ImportField.skip);

    expect(container.read(csvImportProvider).missing, [ImportField.mobile]);
    expect(container.read(csvImportProvider).canStart, isFalse);
  });
}
