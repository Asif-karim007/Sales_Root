import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/translations/translations.dart';

import '../../helpers/api_stub.dart';

const memberId = '01a10101-8656-7886-b8e5-4f197fbd9159';
const pipelineId = '01a10101-8646-7b7e-9690-527c3f1af8dc';
const taskId = '01a10d1a-63f9-7c56-8222-736d8b98cce4';

/// Every settings endpoint, answering from the recorded responses of the
/// test user.
ApiStub settingsStub() => ApiStub()
  ..on('GET', 'auth/devices', fixture('settings_devices'))
  ..on('GET', 'workspaces/pipelines', fixture('settings_pipelines'))
  ..on('GET', 'workspaces/pack', fixture('settings_pack'))
  ..on('POST', 'sync', fixture('settings_sync_push'))
  ..on('GET', 'sync', fixture('settings_sync_pull'))
  ..on(
    'GET',
    'reports/conversion',
    (RequestOptions r) => r.queryParameters['group'] == 'week'
        ? fixture('settings_report_conversion_weeks')
        : fixture('settings_report_conversion'),
  )
  ..on(
    'GET',
    'reports/sales',
    (RequestOptions r) => r.queryParameters['group'] == 'month'
        ? fixture('settings_report_sales_months')
        : fixture('settings_report_sales'),
  )
  ..on('GET', 'reports/targets', fixture('settings_report_targets'));

/// A signed-in container over [stub] as Rafi with [role] and [level], whose
/// workspace and grants are loaded.
Future<ProviderContainer> settingsContainer(
  ApiStub stub, {
  String role = 'executive',
  String level = 'standard',
  bool levelLocked = false,
  List<String>? layers,
  List<Override> overrides = const [],
}) async {
  PackageInfo.setMockInitialValues(
    appName: 'SalesRoot',
    packageName: 'com.salesrootcrm.salesroot',
    version: '2.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final container = await apiContainer(
    stub,
    me: meWith(
      role: role,
      level: level,
      levelLocked: levelLocked,
      layers: layers,
    ),
    overrides: overrides,
  );
  container.listen(currentWorkspaceProvider, (_, _) {});
  await container.read(workspacesProvider.future);
  await container.read(permissionsProvider.future);
  return container;
}

void listenTo(ProviderContainer container, ProviderListenable<Object?> p) {
  final sub = container.listen(p, (_, _) {});
  addTearDown(sub.close);
}

/// Pumps [screen] at phone width in [locale] and lets its requests land.
Future<void> pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
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
