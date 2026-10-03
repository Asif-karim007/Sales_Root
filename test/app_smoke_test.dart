import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/shell/main_shell.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';

void main() {
  testWidgets('a stored session opens the shell', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'session': jsonEncode({'Token': 't', 'UserId': 1, 'Name': 'Karim Hossain'}),
    });
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(latency: false));

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(MainShell), findsOneWidget);
  });
}
