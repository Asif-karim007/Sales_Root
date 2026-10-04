import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/field_force/view/widget/field_force_gate.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

import 'field_force_harness.dart';

void main() {
  Future<void> settleAccess(ProviderContainer container) async {
    await container.read(permissionsProvider.future);
    await container.read(planProvider.future);
  }

  test('the team plan opens visits, tracking and attendance', () async {
    final container = await fieldForceContainer();
    addTearDown(container.dispose);
    await settleAccess(container);
    final visit = container.read(moduleAccessProvider(AppModule.visit));
    expect(visit.canView, isTrue);
    expect(visit.canAdd, isTrue);
    expect(visit.lockedByPlan, isFalse);
  });

  test('without the Field Force add-on every module is plan-locked', () async {
    final container = await fieldForceContainer(
      role: WorkspaceRole.owner,
      addOns: const {},
    );
    addTearDown(container.dispose);
    await settleAccess(container);
    for (final module in [
      AppModule.visit,
      AppModule.liveTracking,
      AppModule.attendance,
      AppModule.teamAttendance,
    ]) {
      final access = container.read(moduleAccessProvider(module));
      expect(access.lockedByPlan, isTrue, reason: module.name);
      expect(access.canView, isFalse, reason: module.name);
    }
  });

  testWidgets('a visit entry point shows the plan upsell', (tester) async {
    final container = await fieldForceContainer(addOns: const {});
    addTearDown(container.dispose);
    await tester.runAsync(() => settleAccess(container));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: FieldForceGate(
              module: AppModule.visit,
              child: Text('visits'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SrPlanLocked), findsOneWidget);
    expect(find.text('visits'), findsNothing);
  });
}
