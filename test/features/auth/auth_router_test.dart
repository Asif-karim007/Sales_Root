import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/auth/auth_routes.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/view/code_screen.dart';
import 'package:salesroot/features/auth/view/create_team_screen.dart';
import 'package:salesroot/features/auth/view/phone_screen.dart';
import 'package:salesroot/features/auth/view/pin_screen.dart';
import 'package:salesroot/features/auth/view/welcome_screen.dart';
import 'package:salesroot/translations/translations.dart';

import 'auth_test_setup.dart';

/// The sign-up steps' own guards, on the auth routes alone.
void main() {
  Future<GoRouter> start(
    WidgetTester tester,
    ProviderContainer container,
    String location,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: location, routes: authRoutes);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await pumpFor(tester);
    return router;
  }

  testWidgets('the code step without a sent code goes back to the phone', (
    tester,
  ) async {
    final container = await tester.runAsync(() => authContainer(authStub()));
    if (container == null) throw StateError('No container');
    await start(tester, container, Routes.authCode);

    expect(find.byType(PhoneScreen), findsOneWidget);
  });

  testWidgets('the code step opens once a code was sent', (tester) async {
    final container = await tester.runAsync(() async {
      final container = await authContainer(authStub());
      container.listen(sendCodeProvider, (_, _) {});
      await container.read(sendCodeProvider.notifier).send(testPhone);
      return container;
    });
    if (container == null) throw StateError('No container');
    await start(tester, container, Routes.authCode);

    expect(find.byType(CodeScreen), findsOneWidget);
  });

  testWidgets('the PIN step needs a verified number', (tester) async {
    final container = await tester.runAsync(() => authContainer(authStub()));
    if (container == null) throw StateError('No container');
    await start(tester, container, Routes.authPin);

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('a new account goes on to set its PIN', (tester) async {
    final container = await tester.runAsync(() async {
      final stub = authStub()..on('POST', 'auth/otp/verify', newUserTokens());
      final container = await authContainer(stub);
      container
        ..listen(sendCodeProvider, (_, _) {})
        ..listen(verifyCodeProvider, (_, _) {});
      await container.read(sendCodeProvider.notifier).send(testPhone);
      await container.read(verifyCodeProvider.notifier).verify('123456');
      return container;
    });
    if (container == null) throw StateError('No container');
    await start(tester, container, Routes.authPin);

    expect(find.byType(PinScreen), findsOneWidget);
  });

  testWidgets('creating a team needs a session', (tester) async {
    final container = await tester.runAsync(() async {
      final container = await authContainer(authStub());
      await container.read(sessionProvider.future);
      return container;
    });
    if (container == null) throw StateError('No container');
    await start(tester, container, Routes.createTeam);

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('a signed-in user can create a team', (tester) async {
    final container = await tester.runAsync(() async {
      final container = await authContainer(authStub(), signedIn: true);
      await container.read(sessionProvider.future);
      return container;
    });
    if (container == null) throw StateError('No container');
    await start(tester, container, Routes.createTeam);

    expect(find.byType(CreateTeamScreen), findsOneWidget);
  });
}

Future<void> pumpFor(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
