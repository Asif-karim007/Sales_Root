import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/support/support_routes.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

import 'support_test_container.dart';

void main() {
  final locations = [
    Routes.feedback,
    Routes.help,
    Routes.helpArticleFor(1),
    Routes.supportNew,
    Routes.supportTicketFor(3),
    Routes.aiGuide,
    Routes.dataSafety,
    Routes.academy,
    Routes.lessonFor(14),
    Routes.career,
    Routes.about,
    Routes.enquiry,
  ];

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    required Locale locale,
    bool offline = false,
  }) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    PackageInfo.setMockInitialValues(
      appName: 'SalesRoot',
      packageName: 'com.salesrootcrm.salesroot',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final container = await supportContainer();
    addTearDown(container.dispose);
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: offline));
    final router = GoRouter(
      initialLocation: location,
      routes: [
        ...supportRoutes,
        GoRoute(path: Routes.home, builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(
          parent: container,
          overrides: [
            moduleAccessProvider(AppModule.support).overrideWithValue(
              const ModuleAccess(canView: true, canAdd: true, canEdit: true),
            ),
            appLocaleProvider.overrideWithValue(locale),
          ],
        ),
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final locale in [bangla, english]) {
    for (final location in locations) {
      testWidgets('$location renders in ${locale.languageCode}', (
        tester,
      ) async {
        await pumpAt(tester, location, locale: locale);
        expect(tester.takeException(), isNull);
        expect(find.byType(SrScaffold), findsOneWidget);
        expect(find.byType(SrErrorState), findsNothing);
        await unmount(tester);
      });
    }
  }

  testWidgets('a suggested prompt gets an answer with a link', (tester) async {
    await pumpAt(tester, Routes.aiGuide, locale: english);

    await tester.tap(find.text('How do I add a lead?'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('green + button'), findsOneWidget);
    expect(find.text('Add a lead'), findsOneWidget);
    await unmount(tester);
  });

  for (final location in [
    Routes.help,
    Routes.helpArticleFor(1),
    Routes.supportTicketFor(3),
    Routes.academy,
    Routes.career,
  ]) {
    testWidgets('$location shows the offline state', (tester) async {
      await pumpAt(tester, location, locale: english, offline: true);
      expect(tester.takeException(), isNull);
      expect(find.byType(SrErrorState), findsWidgets);
      expect(find.text('No internet connection'), findsWidgets);
      await unmount(tester);
    });
  }
}
