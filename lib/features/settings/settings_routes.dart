import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final settingsBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.more,
      builder: (context, state) =>
          SrComingSoonScreen(title: state.matchedLocation),
    ),
  ],
);

final List<RouteBase> settingsRoutes = [
  GoRoute(
    path: Routes.settings,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.settingsLanguage,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.settingsNotifications,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.settingsSecurity,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.settingsPipelines,
    redirect: requireAccess(AppModule.pipelines),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.settingsFormFields,
    redirect: requireAccess(AppModule.formFields),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.settingsImport,
    redirect: requireAccess(AppModule.dataImport, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.sync,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.syncConflict,
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.reports,
    redirect: requireAccess(AppModule.reports),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.reportSales,
    redirect: requireAccess(AppModule.reports),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
