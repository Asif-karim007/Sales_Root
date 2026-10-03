import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/team/view/chat_list_screen.dart';
import 'package:salesroot/features/team/view/chat_screen.dart';
import 'package:salesroot/widgets/widgets.dart';

import 'team_test_helpers.dart';

/// Opens every team, chat and files screen at phone size, in both
/// languages, and fails on any layout or build error.
void main() {
  final routes = [
    Routes.team,
    Routes.teamInvite,
    '${Routes.teamInviteSent}?id=1',
    Routes.memberFor(5),
    Routes.memberRemoveFor(5),
    Routes.organogram,
    Routes.chats,
    '${Routes.chats}?leadId=40',
    Routes.chatNew,
    Routes.chatOversight,
    Routes.chatFor(1),
    Routes.chatInfoFor(1),
    Routes.files,
    Routes.fileUpload,
    '${Routes.fileUpload}?fileId=1',
    Routes.fileFor(1),
  ];

  for (final locale in [bangla, english]) {
    testWidgets('team screens render in ${locale.languageCode}', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1170, 2532)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final container = await teamContainer();
      addTearDown(container.dispose);
      container.read(appLocaleProvider.notifier).set(locale);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await _settle(tester);

      final router = container.read(appRouterProvider);
      for (final route in routes) {
        router.go(route);
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: route);
        expect(find.byType(SrErrorState), findsNothing, reason: route);
        expect(find.byType(SrScaffold), findsWidgets, reason: route);
      }
    });
  }

  testWidgets('a member, offline and an empty workspace render cleanly', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = await teamContainer(role: WorkspaceRole.member);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await _settle(tester);
    final router = container.read(appRouterProvider);
    final states = <DevSettings Function(DevSettings)>[
      (s) => s,
      (s) => s.copyWith(offline: true),
      (s) => s.copyWith(offline: false, emptyWorkspace: true),
    ];
    for (final state in states) {
      setDev(container, state);
      for (final route in routes) {
        router.go(route);
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: route);
      }
    }
  });

  testWidgets('a lead link opens that lead\'s discussion in place', (
    tester,
  ) async {
    final container = await teamContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await _settle(tester);
    final router = container.read(appRouterProvider);

    router.go(Routes.home);
    await _settle(tester);
    router.push('${Routes.chats}?leadId=1');
    await _settle(tester);

    expect(find.byType(ChatListScreen), findsNothing);
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Karim Textiles'), findsWidgets);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
