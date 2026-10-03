import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/home/view/easy_home_view.dart';
import 'package:salesroot/features/home/view/manager_home_view.dart';
import 'package:salesroot/features/home/view/new_home_view.dart';
import 'package:salesroot/features/home/view/notifications_screen.dart';
import 'package:salesroot/features/home/view/owner_home_view.dart';
import 'package:salesroot/features/home/view/search_screen.dart';
import 'package:salesroot/features/home/view/standard_home_view.dart';
import 'package:salesroot/features/home/view/team_lead_home_view.dart';

import 'home_test_setup.dart';

void main() {
  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    WorkspaceRole? role,
    ExperienceLevel? level,
    bool empty = false,
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await tester.runAsync(
      () => homeContainer(role: role, empty: empty),
    );
    if (container == null) throw StateError('no container');
    if (level != null) {
      container.read(experienceLevelProvider.notifier).set(level);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return container;
  }

  final cases = <(String, WorkspaceRole?, ExperienceLevel?, bool, Type)>[
    ('easy', WorkspaceRole.member, null, false, EasyHomeView),
    (
      'standard',
      WorkspaceRole.member,
      ExperienceLevel.standard,
      false,
      StandardHomeView,
    ),
    ('team lead', WorkspaceRole.teamLead, null, false, TeamLeadHomeView),
    (
      'manager',
      WorkspaceRole.teamLead,
      ExperienceLevel.advanced,
      false,
      ManagerHomeView,
    ),
    ('owner', WorkspaceRole.owner, null, false, OwnerHomeView),
    ('new user', WorkspaceRole.member, null, true, NewHomeView),
  ];

  for (final (name, role, level, empty, view) in cases) {
    testWidgets('renders the $name home', (tester) async {
      await pumpHome(tester, role: role, level: level, empty: empty);
      expect(find.byType(view), findsOneWidget);
    });
  }

  testWidgets('opens notifications and search', (tester) async {
    final container = await pumpHome(tester);
    final router = container.read(appRouterProvider);

    router.push(Routes.notifications);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(NotificationsScreen), findsOneWidget);

    router.push(Routes.search);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'Karim');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('Karim Textiles'), findsWidgets);
  });
}
