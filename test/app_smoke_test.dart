import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/session/session_store.dart';
import 'package:salesroot/core/shell/main_shell.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/auth/view/unlock_screen.dart';
import 'package:salesroot/features/auth/view/welcome_screen.dart';

import 'helpers/api_stub.dart';

ApiStub _homeStub() => ApiStub()
  ..on('GET', 'home', fixture('home_home'))
  ..on('GET', 'reports/me', fixture('home_reports_me'))
  ..on('GET', 'notifications', fixture('home_notifications'));

Future<void> _open(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a stored session opens the shell', (tester) async {
    final container = await apiContainer(
      _homeStub(),
      me: meWith(role: 'executive', level: 'easy'),
    );
    await tester.runAsync(() async {
      await container.read(workspacesProvider.future);
      await container.read(permissionsProvider.future);
      await container.read(planProvider.future);
    });

    await _open(tester, container);

    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('no session opens the welcome screen', (tester) async {
    final container = await apiContainer(_homeStub(), signedIn: false);

    await _open(tester, container);

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('a stored PIN puts the lock screen first', (tester) async {
    final container = await apiContainer(_homeStub());
    await tester.runAsync(() async {
      final session = await container.read(sessionProvider.future);
      await container
          .read(sessionStoreProvider)
          .writePin('2580', session?.userId ?? '');
      container.invalidate(pinLockProvider);
      await container.read(pinLockProvider.future);
    });

    await _open(tester, container);

    expect(find.byType(UnlockScreen), findsOneWidget);
  });
}
