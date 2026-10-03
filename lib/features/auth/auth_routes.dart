import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/features/auth/models/sign_up_flow.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';
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

final List<RouteBase> authRoutes = [
  GoRoute(
    path: Routes.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: Routes.unlock,
    builder: (context, state) => const UnlockScreen(),
  ),
  GoRoute(
    path: Routes.welcome,
    builder: (context, state) => const WelcomeScreen(),
  ),
  GoRoute(
    path: Routes.authPhone,
    builder: (context, state) => PhoneScreen(
      signIn: _signInMode(state),
      referralCode: state.uri.queryParameters['ref'],
      inviteCode: state.uri.queryParameters['invite'],
    ),
  ),
  GoRoute(
    path: Routes.authCode,
    redirect: _requireFlow((flow) => flow.challenge != null, Routes.authPhone),
    builder: (context, state) => CodeScreen(signIn: _signInMode(state)),
  ),
  GoRoute(
    path: Routes.authPin,
    redirect: _requireFlow((flow) => flow.session != null, Routes.welcome),
    builder: (context, state) => const PinScreen(),
  ),
  GoRoute(
    path: Routes.authProfile,
    redirect: _requireFlow((flow) => flow.session != null, Routes.welcome),
    builder: (context, state) => const ProfileScreen(),
  ),
  GoRoute(
    path: Routes.authIndustry,
    redirect: _requireFlow((flow) => flow.session != null, Routes.welcome),
    builder: (context, state) => const IndustryScreen(),
  ),
  GoRoute(
    path: Routes.authEmail,
    builder: (context, state) => const EmailSignInScreen(),
  ),
  GoRoute(path: Routes.tour, builder: (context, state) => const TourScreen()),
  GoRoute(
    path: Routes.features,
    builder: (context, state) => const FeaturesScreen(),
  ),
  GoRoute(
    path: Routes.createTeam,
    redirect: (context, state) =>
        ProviderScope.containerOf(
              context,
              listen: false,
            ).read(sessionProvider).value ==
            null
        ? Routes.welcome
        : null,
    builder: (context, state) => const CreateTeamScreen(),
  ),
  GoRoute(
    path: Routes.acceptInvite,
    builder: (context, state) =>
        InviteScreen(code: state.pathParameters['code'] ?? ''),
  ),
  GoRoute(
    path: Routes.referralSignup,
    builder: (context, state) =>
        PhoneScreen(referralCode: state.pathParameters['code']),
  ),
];

bool _signInMode(GoRouterState state) =>
    state.uri.queryParameters['mode'] == 'signin';

/// Sends a step of sign-up opened out of order back to where it starts.
GoRouterRedirect _requireFlow(bool Function(SignUpFlow) ready, String to) =>
    (context, state) =>
        ready(
          ProviderScope.containerOf(
            context,
            listen: false,
          ).read(signUpFlowProvider),
        )
        ? null
        : to;
