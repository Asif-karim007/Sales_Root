import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/auth/view/code_screen.dart';
import 'package:salesroot/features/auth/view/create_team_screen.dart';
import 'package:salesroot/features/auth/view/email_sign_in_screen.dart';
import 'package:salesroot/features/auth/view/features_screen.dart';
import 'package:salesroot/features/auth/view/industry_screen.dart';
import 'package:salesroot/features/auth/view/invite_screen.dart';
import 'package:salesroot/features/auth/view/phone_screen.dart';
import 'package:salesroot/features/auth/view/pin_screen.dart';
import 'package:salesroot/features/auth/view/profile_screen.dart';
import 'package:salesroot/features/auth/view/splash_screen.dart';
import 'package:salesroot/features/auth/view/tour_screen.dart';
import 'package:salesroot/features/auth/view/unlock_screen.dart';
import 'package:salesroot/features/auth/view/welcome_screen.dart';
import 'package:salesroot/l10n/l10n.dart';

import 'auth_test_setup.dart';

void main() {
  final screens = <String, Widget>{
    'splash': const SplashScreen(),
    'welcome': const WelcomeScreen(),
    'phone': const PhoneScreen(),
    'refersignup': const PhoneScreen(referralCode: 'RH4K9P'),
    'code': const CodeScreen(),
    'pin': const PinScreen(),
    'profile': const ProfileScreen(),
    'industry': const IndustryScreen(),
    'tour': const TourScreen(),
    'features': const FeaturesScreen(),
    'createteam': const CreateTeamScreen(),
    'invite': const InviteScreen(code: 'DS7Q2M'),
    'signin': const UnlockScreen(),
    'signinemail': const EmailSignInScreen(),
  };

  final looks = [
    (bangla, AppTheme.light, 'Bangla, light'),
    (english, AppTheme.light, 'English, light'),
    (bangla, AppTheme.dark, 'Bangla, dark'),
  ];
  for (final (locale, theme, look) in looks) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('$name renders at phone width ($look)', (tester) async {
        tester.view
          ..physicalSize = const Size(360, 740)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = await tester.runAsync(authContainer);
        if (container == null) throw StateError('No container');
        container.read(appLocaleProvider.notifier).set(locale);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: theme,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: screen,
            ),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(tester.takeException(), isNull);
        expect(find.byWidget(screen), findsOneWidget);
      });
    }
  }
}
