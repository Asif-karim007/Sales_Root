import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/dev/dev_menu_screen.dart';
import 'package:salesroot/core/routing/no_access_screen.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/shell/main_shell.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/auth/auth_routes.dart';
import 'package:salesroot/features/billing/billing_routes.dart';
import 'package:salesroot/features/contacts/contacts_routes.dart';
import 'package:salesroot/features/field_force/field_force_routes.dart';
import 'package:salesroot/features/growth/growth_routes.dart';
import 'package:salesroot/features/home/home_routes.dart';
import 'package:salesroot/features/hr/hr_routes.dart';
import 'package:salesroot/features/leads/leads_routes.dart';
import 'package:salesroot/features/sales/sales_routes.dart';
import 'package:salesroot/features/settings/settings_routes.dart';
import 'package:salesroot/features/support/support_routes.dart';
import 'package:salesroot/features/tasks/tasks_routes.dart';
import 'package:salesroot/features/team/team_routes.dart';
import 'package:salesroot/widgets/gallery/sr_gallery_screen.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shell branch order. The tab bar shows four of these.
enum ShellBranch { home, leads, tasks, sales, team, more }

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (_, _) => refresh.value++)
    ..listen(pinLockProvider, (_, _) => refresh.value++)
    ..listen(permissionsProvider, (_, _) => refresh.value++)
    ..listen(currentWorkspaceProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          homeBranch,
          leadsBranch,
          tasksBranch,
          salesBranch,
          teamBranch,
          settingsBranch,
        ],
      ),
      ...authRoutes,
      ...homeRoutes,
      ...leadsRoutes,
      ...tasksRoutes,
      ...contactsRoutes,
      ...salesRoutes,
      ...teamRoutes,
      ...settingsRoutes,
      ...billingRoutes,
      ...supportRoutes,
      ...fieldForceRoutes,
      ...growthRoutes,
      ...hrRoutes,
      GoRoute(
        path: Routes.noAccess,
        builder: (context, state) => NoAccessScreen(
          planLocked: state.uri.queryParameters['plan'] == '1',
        ),
      ),
      GoRoute(
        path: Routes.dev,
        builder: (context, state) => const DevMenuScreen(),
      ),
      GoRoute(
        path: Routes.devGallery,
        builder: (context, state) => const SrGalleryScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
}

/// Splash until the session, PIN lock and grants are known; then signed-out
/// users stay on public routes, locked ones on the PIN screen, and everyone
/// else is kept off the entry routes.
String? _redirect(Ref ref, String location) {
  final session = ref.read(sessionProvider);
  final lock = ref.read(pinLockProvider);
  if (!session.hasValue || !lock.hasValue) {
    return location == Routes.splash ? null : Routes.splash;
  }
  if (session.value == null) {
    return Routes.isPublic(location) ? null : Routes.welcome;
  }
  if (lock.value ?? false) {
    return location == Routes.unlock ? null : Routes.unlock;
  }
  if (!ref.read(permissionsProvider).hasValue) {
    return location == Routes.splash ? null : Routes.splash;
  }
  final isEntry =
      location == Routes.splash ||
      location == Routes.unlock ||
      (Routes.isPublic(location) && !Routes.isOnboarding(location));
  return isEntry ? Routes.home : null;
}
