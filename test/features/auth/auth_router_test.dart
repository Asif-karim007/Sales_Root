import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/shell/main_shell.dart';
import 'package:salesroot/features/auth/data/auth_fixtures.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
import 'package:salesroot/features/auth/view/tour_screen.dart';
import 'package:salesroot/features/auth/view/unlock_screen.dart';
import 'package:salesroot/features/auth/view/welcome_screen.dart';

import 'auth_test_setup.dart';

void main() {
  Future<void> pumpFor(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<ProviderContainer> start(
    WidgetTester tester, {
    Map<String, String> secure = const {},
  }) async {
    final container = await tester.runAsync(
      () => authContainer(secure: secure),
    );
    if (container == null) throw StateError('No container');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await pumpFor(tester);
    return container;
  }

  testWidgets('signed out opens the welcome screen', (tester) async {
    await start(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('a stored session with a PIN opens the lock screen', (
    tester,
  ) async {
    await start(tester, secure: {...storedSession, 'pin_hash': 'stored'});
    expect(find.byType(UnlockScreen), findsOneWidget);
  });

  testWidgets('a new user stays on the tour after signing in', (tester) async {
    final container = await start(tester);
    container
      ..listen(sendCodeProvider, (_, _) {})
      ..listen(verifyCodeProvider, (_, _) {});
    await tester.runAsync(() async {
      await container.read(sendCodeProvider.notifier).send('01812345678');
      await container.read(verifyCodeProvider.notifier).verify(demoSmsCode);
    });
    container.read(appRouterProvider).go(Routes.tour);
    await tester.runAsync(container.read(signUpFlowProvider.notifier).signIn);
    await pumpFor(tester);

    expect(find.byType(TourScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });
}
