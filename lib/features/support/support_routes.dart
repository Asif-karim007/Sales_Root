import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final List<RouteBase> supportRoutes = [
  GoRoute(
    path: Routes.feedback,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.help,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.helpArticle,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.supportNew,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.supportTicket,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.aiGuide,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.dataSafety,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.academy,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.lesson,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.career,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.about,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.enquiry,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
