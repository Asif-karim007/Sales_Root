import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/settings/data/sync_store.dart';
import 'package:salesroot/features/settings/models/sync_models.dart';
import 'package:salesroot/features/settings/providers/import_providers.dart';
import 'package:salesroot/features/settings/view/conflict_screen.dart';
import 'package:salesroot/features/settings/view/csv_import_screen.dart';
import 'package:salesroot/features/settings/view/form_fields_screen.dart';
import 'package:salesroot/features/settings/view/language_level_screen.dart';
import 'package:salesroot/features/settings/view/more_screen.dart';
import 'package:salesroot/features/settings/view/notification_prefs_screen.dart';
import 'package:salesroot/features/settings/view/pipelines_screen.dart';
import 'package:salesroot/features/settings/view/reports_screen.dart';
import 'package:salesroot/features/settings/view/sales_report_screen.dart';
import 'package:salesroot/features/settings/view/security_screen.dart';
import 'package:salesroot/features/settings/view/settings_screen.dart';
import 'package:salesroot/features/settings/view/sync_screen.dart';
import 'package:salesroot/widgets/widgets.dart';

import '../../helpers/api_stub.dart';
import 'settings_test_setup.dart';

Future<void> _withConflict(ProviderContainer container) async {
  final store = SyncStore(
    container.read(sharedPreferencesProvider),
    container.read(currentWorkspaceProvider)?.id ?? '',
  );
  final pushed = SyncPushResult.fromJson(fixtureMap('settings_sync_conflict'));
  await store.write(SyncSnapshot(conflicts: pushed.conflicts, cursor: 259));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  for (final locale in [english, bangla]) {
    group('screens render in ${locale.languageCode}', () {
      final screens = <String, (Widget, String?)>{
        'more': (const MoreScreen(), null),
        'settings': (const SettingsScreen(), null),
        'language': (const LanguageLevelScreen(), null),
        'notifications': (const NotificationPrefsScreen(), null),
        'security': (const SecurityScreen(), 'agent-settings'),
        'pipelines': (const PipelinesScreen(), null),
        'form fields': (const FormFieldsScreen(), null),
        'import': (const CsvImportScreen(), null),
        'sync': (const SyncScreen(), null),
        'conflict': (const ConflictScreen(id: taskId), '[test] sync probe'),
        'reports': (const ReportsScreen(), null),
        'sales report': (const SalesReportScreen(), '[test] Soap'),
      };
      for (final MapEntry(key: name, value: (screen, text))
          in screens.entries) {
        testWidgets(name, (tester) async {
          final container = await tester.runAsync(
            () => settingsContainer(
              settingsStub(),
              role: 'owner',
              level: 'advanced',
            ),
          );
          if (container == null) return;
          container.read(appLocaleProvider.notifier).set(locale);
          await tester.runAsync(() => _withConflict(container));

          await pumpScreen(tester, container, screen, locale: locale);

          expect(tester.takeException(), isNull);
          expect(find.byType(SrErrorState), findsNothing);
          if (text != null) expect(find.text(text), findsWidgets);
        });
      }
    });
  }

  testWidgets('pipelines show each stage with its chance', (tester) async {
    final container = await tester.runAsync(
      () => settingsContainer(settingsStub(), role: 'owner'),
    );
    if (container == null) return;

    await pumpScreen(tester, container, const PipelinesScreen());

    expect(find.text('To contact'), findsOneWidget);
    expect(find.text('Lost'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
  });

  testWidgets('form fields list the pack fields', (tester) async {
    final container = await tester.runAsync(
      () => settingsContainer(settingsStub()),
    );
    if (container == null) return;

    await pumpScreen(tester, container, const FormFieldsScreen());
    expect(find.text('Products wanted'), findsOneWidget);

    await tester.tap(find.text('Customer'));
    await _settle(tester);
    expect(find.text('Outlet type'), findsOneWidget);
    expect(find.textContaining('retail, wholesale'), findsOneWidget);
  });

  testWidgets('a failed device list shows the error with a retry', (
    tester,
  ) async {
    final stub = settingsStub()..fail('GET', 'auth/devices', 500);
    final container = await tester.runAsync(() => settingsContainer(stub));
    if (container == null) return;

    await pumpScreen(tester, container, const SecurityScreen());

    expect(find.byType(SrErrorState), findsOneWidget);
  });

  testWidgets('choosing English saves it on the account', (tester) async {
    final stub = settingsStub()..on('PATCH', 'auth/me', fixture('auth_me'));
    final container = await tester.runAsync(() => settingsContainer(stub));
    if (container == null) return;

    await pumpScreen(tester, container, const LanguageLevelScreen());
    await tester.tap(find.text('English'));
    await _settle(tester);

    expect(container.read(appLocaleProvider), english);
    expect(stub.lastBody('PATCH', 'auth/me'), {'language': 'en'});
  });

  testWidgets('the import screen maps, checks and imports a file', (
    tester,
  ) async {
    final stub = settingsStub()..on('POST', 'companies/import', const {});
    final container = await tester.runAsync(
      () => settingsContainer(stub, role: 'owner'),
    );
    if (container == null) return;
    listenTo(container, csvImportProvider);

    await pumpScreen(tester, container, const CsvImportScreen());
    await tester.runAsync(
      () => container
          .read(csvImportProvider.notifier)
          .load(
            'outlets.csv',
            utf8.encode(
              'Name,Phone,Area,Fax\n'
              'Rahim Traders,01811000010,Mirpur 10,\n'
              'Karim Store,01811000011,Mirpur 11,\n',
            ),
          ),
    );
    await _settle(tester);
    expect(find.text('outlets.csv'), findsOneWidget);
    expect(find.text('Rahim Traders'), findsOneWidget);

    await tester.tap(find.text('Import 2'));
    await _settle(tester);

    expect(container.read(csvImportProvider).result?.total, 2);
    expect(find.text('Import finished'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a conflict keeps the server value when chosen', (tester) async {
    final stub = settingsStub()
      ..on('POST', 'sync', fixture('settings_sync_applied'));
    final container = await tester.runAsync(() => settingsContainer(stub));
    if (container == null) return;
    await tester.runAsync(() => _withConflict(container));

    await pumpScreen(tester, container, const ConflictScreen(id: taskId));
    await tester.tap(find.text('Keep this').last);
    await _settle(tester);

    final change = (stub.lastBody('POST', 'sync')['changes'] as List).single;
    expect(change['row'], {'id': taskId, 'title': '[test] sync probe'});
  });
}
