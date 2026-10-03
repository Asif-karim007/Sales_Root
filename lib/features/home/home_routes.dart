import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/home/view/home_screen.dart';
import 'package:salesroot/features/home/view/notifications_screen.dart';
import 'package:salesroot/features/home/view/search_screen.dart';

final homeBranch = StatefulShellBranch(
  routes: [
    GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
  ],
);

final List<RouteBase> homeRoutes = [
  GoRoute(
    path: Routes.notifications,
    builder: (context, state) => const NotificationsScreen(),
  ),
  GoRoute(
    path: Routes.search,
    builder: (context, state) => const SearchScreen(),
  ),
];
