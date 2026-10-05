import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/team/view/chat_info_screen.dart';
import 'package:salesroot/features/team/view/chat_list_screen.dart';
import 'package:salesroot/features/team/view/chat_oversight_screen.dart';
import 'package:salesroot/features/team/view/chat_screen.dart';
import 'package:salesroot/features/team/view/file_detail_screen.dart';
import 'package:salesroot/features/team/view/files_screen.dart';
import 'package:salesroot/features/team/view/invite_form_screen.dart';
import 'package:salesroot/features/team/view/invite_sent_screen.dart';
import 'package:salesroot/features/team/view/member_detail_screen.dart';
import 'package:salesroot/features/team/view/new_chat_screen.dart';
import 'package:salesroot/features/team/view/organogram_screen.dart';
import 'package:salesroot/features/team/view/remove_member_screen.dart';
import 'package:salesroot/features/team/view/team_screen.dart';
import 'package:salesroot/features/team/view/upload_screen.dart';
import 'package:salesroot/features/team/view/widget/member_row.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

import '../../helpers/api_stub.dart';
import 'team_test_helpers.dart';

/// Every team, chat and files screen, at phone size.
const _screens = <String, Widget>{
  'team': TeamScreen(),
  'invite': InviteFormScreen(),
  'invite sent': InviteSentScreen(inviteId: tanvir),
  'member with numbers': MemberDetailScreen(memberId: rafi),
  'member': MemberDetailScreen(memberId: bushra),
  'remove member': RemoveMemberScreen(memberId: bushra),
  'organogram': OrganogramScreen(),
  'chats': ChatListScreen(),
  'new chat': NewChatScreen(),
  'oversight': ChatOversightScreen(),
  'chat': ChatScreen(threadId: '1'),
  'chat info': ChatInfoScreen(threadId: '1'),
  'files': FilesScreen(),
  'upload': UploadScreen(),
  'new version': UploadScreen(replaceFileId: '1'),
  'file': FileDetailScreen(fileId: '1'),
};

Future<void> _show(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen,
) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.light,
          locale: ref.watch(appLocaleProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: screen,
        ),
      ),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Builds the container, with the role's grants and the plan loaded,
/// outside the widget test's fake clock: signing in does real async work.
Future<ProviderContainer> _container(
  WidgetTester tester, {
  ApiStub? stub,
  String role = 'owner',
}) async {
  final container = await tester.runAsync(() async {
    final container = await teamContainer(stub: stub, role: role);
    await container.read(permissionsProvider.future);
    await container.read(planProvider.future);
    return container;
  });
  if (container == null) throw StateError('No container');
  return container;
}

void main() {
  for (final locale in const [bangla, english]) {
    testWidgets('team screens render in ${locale.languageCode}', (
      tester,
    ) async {
      final container = await _container(
        tester,
        stub: teamStub(withInvite: true),
      );
      container.read(appLocaleProvider.notifier).set(locale);

      for (final MapEntry(key: name, value: screen) in _screens.entries) {
        await _show(tester, container, screen);
        expect(tester.takeException(), isNull, reason: name);
        expect(find.byType(SrErrorState), findsNothing, reason: name);
      }
    });
  }

  testWidgets('a member, offline and an empty team render cleanly', (
    tester,
  ) async {
    final stub = teamStub()
      ..fail('GET', 'attendance', 403)
      ..fail('GET', 'targets', 403);
    final container = await _container(tester, stub: stub, role: 'executive');
    final states = <void Function()>[
      () {},
      () {
        stub.offline = true;
        setDev(container, (s) => s.copyWith(offline: true));
      },
      () {
        stub
          ..offline = false
          ..on('GET', 'workspaces/members', <Object>[]);
        setDev(container, (s) => s.copyWith(offline: false));
      },
    ];
    for (final state in states) {
      state();
      for (final MapEntry(key: name, value: screen) in _screens.entries) {
        await _show(tester, container, screen);
        expect(tester.takeException(), isNull, reason: name);
      }
    }
  });

  testWidgets('the team lists everyone; the detail shows the month', (
    tester,
  ) async {
    final container = await _container(tester, stub: teamStub());

    await _show(tester, container, const TeamScreen());
    expect(find.byType(MemberRow), findsNWidgets(5));

    await _show(tester, container, const MemberDetailScreen(memberId: rafi));
    expect(find.byType(SrKpiTile), findsNWidgets(3));

    await _show(tester, container, const MemberDetailScreen(memberId: bushra));
    expect(find.byType(SrKpiTile), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is SrButton && w.variant == SrButtonVariant.danger,
      ),
      findsOneWidget,
    );
  });

  testWidgets('a member sees the team without remove or invite', (
    tester,
  ) async {
    final container = await _container(
      tester,
      stub: teamStub(),
      role: 'executive',
    );

    await _show(tester, container, const MemberDetailScreen(memberId: bushra));
    expect(
      find.byWidgetPredicate(
        (w) => w is SrButton && w.variant == SrButtonVariant.danger,
      ),
      findsNothing,
    );
  });
}
