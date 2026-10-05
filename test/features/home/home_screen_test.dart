import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/home/view/easy_home_view.dart';
import 'package:salesroot/features/home/view/home_screen.dart';
import 'package:salesroot/features/home/view/manager_home_view.dart';
import 'package:salesroot/features/home/view/new_home_view.dart';
import 'package:salesroot/features/home/view/notifications_screen.dart';
import 'package:salesroot/features/home/view/owner_home_view.dart';
import 'package:salesroot/features/home/view/standard_home_view.dart';
import 'package:salesroot/features/home/view/team_lead_home_view.dart';
import 'package:salesroot/features/home/view/workspace_switch_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

import '../../helpers/api_stub.dart';
import 'home_test_setup.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    ApiStub stub,
    Widget screen, {
    String role = 'executive',
    String level = 'easy',
    Locale locale = bangla,
    ThemeData? theme,
  }) async {
    tester.view
      ..physicalSize = const Size(360, 780)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await tester.runAsync(
      () => homeContainer(stub, role: role, level: level),
    );
    if (container == null) throw StateError('no container');
    container.read(appLocaleProvider.notifier).set(locale);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: screen,
        ),
      ),
    );
    await settle(tester);
    return container;
  }

  final cases = <(String, String, String, Type)>[
    ('easy', 'executive', 'easy', EasyHomeView),
    ('standard', 'executive', 'standard', StandardHomeView),
    ('team lead', 'teamlead', 'standard', TeamLeadHomeView),
    ('manager', 'manager', 'advanced', ManagerHomeView),
    ('owner', 'owner', 'standard', OwnerHomeView),
  ];
  final looks = [
    (bangla, AppTheme.light, 'Bangla, light'),
    (english, AppTheme.light, 'English, light'),
    (bangla, AppTheme.dark, 'Bangla, dark'),
  ];

  for (final (name, role, level, view) in cases) {
    for (final (locale, theme, look) in looks) {
      testWidgets('renders the $name home ($look)', (tester) async {
        await pump(
          tester,
          homeStub(),
          const HomeScreen(),
          role: role,
          level: level,
          locale: locale,
          theme: theme,
        );
        expect(find.byType(view), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('an empty workspace renders the new-user home', (tester) async {
    await pump(
      tester,
      homeStub()..on('GET', 'home', emptyHome()),
      const HomeScreen(),
    );
    expect(find.byType(NewHomeView), findsOneWidget);
  });

  testWidgets('a failed home shows the error state', (tester) async {
    await pump(
      tester,
      homeStub()..fail('GET', 'home', 500, message: 'Down'),
      const HomeScreen(),
    );
    expect(find.byType(SrErrorState), findsOneWidget);
  });

  testWidgets('notifications show the empty state', (tester) async {
    await pump(tester, homeStub(), const NotificationsScreen());
    expect(find.byType(SrEmptyState), findsOneWidget);
  });

  group('workspace switch', () {
    Map<String, dynamic> twoWorkspaces() {
      final me = meWith(role: 'executive', level: 'easy');
      final first = (me['workspaces'] as List).first as Map<String, dynamic>;
      return {
        ...me,
        'workspaces': [
          first,
          {...first, 'id': 'other', 'name': 'Karim Textiles'},
        ],
      };
    }

    Widget opener() => Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showWorkspaceSwitcher(context),
          child: const Text('open'),
        ),
      ),
    );

    testWidgets('re-issues the session for the chosen workspace', (
      tester,
    ) async {
      final tokens = fixtureMap('auth_tokens');
      final stub = homeStub()
        ..on('GET', 'auth/me', twoWorkspaces())
        ..on('POST', 'auth/workspace/{id}', {
          ...tokens,
          'accessToken': 'switched',
          'me': {
            ...tokens['me'] as Map<String, dynamic>,
            'workspaceId': 'other',
          },
        });
      final container = await pump(tester, stub, opener());
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.text('Karim Textiles'));
      await settle(tester);

      expect(stub.last('POST', 'auth/workspace/{id}')?.path, contains('other'));
      expect(container.read(sessionProvider).value?.workspaceId, 'other');
      expect(find.text('Karim Textiles'), findsNothing);
    });

    testWidgets('a failed switch keeps the sheet open', (tester) async {
      final stub = homeStub()
        ..on('GET', 'auth/me', twoWorkspaces())
        ..fail('POST', 'auth/workspace/{id}', 403, message: 'Not a member');
      final container = await pump(tester, stub, opener());
      final before = container.read(sessionProvider).value?.workspaceId;
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tap(find.text('Karim Textiles'));
      await settle(tester);

      expect(container.read(sessionProvider).value?.workspaceId, before);
      expect(find.text('Karim Textiles'), findsOneWidget);
    });
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
