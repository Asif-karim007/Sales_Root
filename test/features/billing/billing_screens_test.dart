import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/routing/no_access_screen.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/billing/view/checkout_screen.dart';
import 'package:salesroot/features/billing/view/plan_activated_screen.dart';
import 'package:salesroot/widgets/widgets.dart';

import 'billing_test_setup.dart';

const _ownerRoutes = [
  '/billing/plan',
  '/billing/compare',
  '/billing/choose',
  '/billing/choose?reason=quota&kind=cardScans',
  '/billing/choose?reason=quota&kind=users',
  '/billing/choose?reason=quota&kind=records',
  '/billing/choose?reason=quota&kind=storage',
  '/billing/choose?reason=quota&kind=smsCredits',
  '/billing/add-ons/later?plan=Business&seats=25&cycle=monthly',
  '/billing/checkout?plan=Business&seats=25&cycle=monthly',
  '/billing/checkout?packs=Scans50',
  '/billing/activated?invoice=24',
  '/billing/add-ons',
  '/billing/history',
  '/refer',
  '/refer/invite',
  '/refer/list',
  '/refer/wallet',
  '/refer/qr',
];

/// Signs in on [workspaceId] as [role] and opens the app at phone width.
Future<ProviderContainer> _open(
  WidgetTester tester, {
  int workspaceId = 200,
  WorkspaceRole role = WorkspaceRole.owner,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = await billingContainer(
    workspaceId: workspaceId,
    role: role,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return container;
}

/// Opens each route and checks it rendered data without a layout error.
Future<void> _visit(
  WidgetTester tester,
  ProviderContainer container,
  List<String> routes, {
  bool allowEmpty = false,
}) async {
  final router = container.read(appRouterProvider);
  for (final route in routes) {
    router.push(route);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull, reason: route);
    expect(find.byType(SrComingSoonScreen), findsNothing, reason: route);
    expect(find.byType(SrErrorState), findsNothing, reason: route);
    expect(find.byType(SrSkeletonList), findsNothing, reason: route);
    expect(find.byType(NoAccessScreen), findsNothing, reason: route);
    if (!allowEmpty) {
      expect(find.byType(SrEmptyState), findsNothing, reason: route);
    }
    router.go(Routes.home);
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('the owner sees every screen in Bangla and English', (
    tester,
  ) async {
    final container = await _open(tester);
    await _visit(tester, container, _ownerRoutes);
    container.read(appLocaleProvider.notifier).set(english);
    await tester.pump();
    await _visit(tester, container, _ownerRoutes);
  });

  testWidgets('a Free owner sees empty history and the upgrade path', (
    tester,
  ) async {
    final container = await _open(tester, workspaceId: 100);
    await _visit(tester, container, const [
      '/billing/plan',
      '/billing/compare',
      '/billing/choose',
      '/billing/choose?reason=quota&kind=users',
      '/billing/add-ons/later?plan=Team&seats=2&cycle=yearly',
      '/billing/checkout?plan=Team&seats=2&cycle=yearly',
      '/billing/add-ons',
    ]);
    await _visit(tester, container, const [
      '/billing/history',
    ], allowEmpty: true);
  });

  testWidgets('a team lead browses billing in dark mode, read-only', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final container = await _open(
      tester,
      workspaceId: 300,
      role: WorkspaceRole.teamLead,
    );
    await _visit(tester, container, const [
      '/billing/plan',
      '/billing/add-ons',
      '/billing/history',
      '/billing/choose?reason=quota&kind=cardScans',
      '/refer',
      '/refer/list',
      '/refer/wallet',
      '/refer/qr',
    ]);
    await _visit(tester, container, const [
      '/billing/compare',
    ], allowEmpty: true);
    container.read(appRouterProvider).push(Routes.checkout);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CheckoutScreen), findsNothing);
    expect(find.byType(NoAccessScreen), findsOneWidget);
  });

  testWidgets('paying for a pack lands on the success screen', (tester) async {
    final container = await _open(tester);
    container.read(appRouterProvider).push('${Routes.checkout}?packs=Scans50');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(
      find.descendant(
        of: find.byType(SrFooter),
        matching: find.byType(SrButton),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(CheckoutScreen), findsNothing);
    expect(find.byType(PlanActivatedScreen), findsOneWidget);
    expect(find.byType(SrErrorState), findsNothing);
  });

  testWidgets('a member at a limit is told to ask the owner', (tester) async {
    final container = await _open(tester, role: WorkspaceRole.member);
    container
        .read(appRouterProvider)
        .push('${Routes.planChoose}?reason=quota&kind=cardScans');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(NoAccessScreen), findsNothing);
    expect(find.byType(SrEmptyState), findsOneWidget);
    expect(find.byType(SrErrorState), findsNothing);
  });
}
