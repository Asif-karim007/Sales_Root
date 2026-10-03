import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/workspace/workspace.dart';
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

import 'settings_test_utils.dart';

void _phone(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 3
    ..physicalSize = const Size(360 * 3, 1800 * 3);
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final locale in [bangla, english]) {
    testWidgets('every screen renders for an owner in ${locale.languageCode}', (
      tester,
    ) async {
      final container = await signedInContainer(
        role: WorkspaceRole.owner,
        addOns: const {AddOn.fieldForce, AddOn.growth},
      );
      addTearDown(container.dispose);
      _phone(tester);
      container
          .read(experienceLevelProvider.notifier)
          .set(ExperienceLevel.advanced);
      container.read(appLocaleProvider.notifier).set(locale);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await _settle(tester);
      final router = container.read(appRouterProvider);
      final screens = {
        Routes.more: MoreScreen,
        Routes.settings: SettingsScreen,
        Routes.settingsLanguage: LanguageLevelScreen,
        Routes.settingsNotifications: NotificationPrefsScreen,
        Routes.settingsSecurity: SecurityScreen,
        Routes.settingsPipelines: PipelinesScreen,
        Routes.settingsFormFields: FormFieldsScreen,
        Routes.settingsImport: CsvImportScreen,
        Routes.sync: SyncScreen,
        Routes.syncConflictFor(2): ConflictScreen,
        Routes.reports: ReportsScreen,
        Routes.reportSales: SalesReportScreen,
      };
      for (final MapEntry(key: route, value: type) in screens.entries) {
        router.go(route);
        await _settle(tester);
        expect(find.byType(type), findsOneWidget, reason: route);
        expect(tester.takeException(), isNull, reason: route);
      }
    });
  }

  testWidgets('the import screen maps, previews and imports a file', (
    tester,
  ) async {
    final container = await signedInContainer(role: WorkspaceRole.owner);
    addTearDown(container.dispose);
    _phone(tester);
    container
        .read(experienceLevelProvider.notifier)
        .set(ExperienceLevel.advanced);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await _settle(tester);
    container.read(appRouterProvider).go(Routes.settingsImport);
    await _settle(tester);

    await container
        .read(csvImportProvider.notifier)
        .load(
          'leads_sept.csv',
          utf8.encode(
            'Name,Phone,Company,Fax\n'
            'Karim Textiles,01711234567,"Karim Textiles, Ltd",\n'
            'Delta Power,01811000111,Delta Power,\n',
          ),
        );
    await _settle(tester);
    expect(find.text('leads_sept.csv'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await container.read(csvImportProvider.notifier).start();
    await _settle(tester);
    expect(container.read(csvImportProvider).job?.done, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a member is kept out of pipelines', (tester) async {
    final container = await signedInContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await _settle(tester);
    container.read(appRouterProvider).go(Routes.settingsPipelines);
    await _settle(tester);

    expect(find.byType(PipelinesScreen), findsNothing);
  });
}
