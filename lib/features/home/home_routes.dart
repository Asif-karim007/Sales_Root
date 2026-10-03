import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final homeBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) =>
          SrComingSoonScreen(title: state.matchedLocation),
    ),
  ],
);

final List<RouteBase> homeRoutes = [
  GoRoute(
    path: Routes.notifications,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.search,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
