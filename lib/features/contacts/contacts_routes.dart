import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final List<RouteBase> contactsRoutes = [
  GoRoute(
    path: Routes.contacts,
    redirect: requireAccess(AppModule.contact),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.contactsImport,
    redirect: requireAccess(AppModule.contact, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.contactNew,
    redirect: requireAccess(AppModule.contact, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.contact,
    redirect: requireAccess(AppModule.contact),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.companies,
    redirect: requireAccess(AppModule.company),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.companyNew,
    redirect: requireAccess(AppModule.company, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.company,
    redirect: requireAccess(AppModule.company),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.customer,
    redirect: requireAccess(AppModule.company),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.customerDocuments,
    redirect: requireAccess(AppModule.company),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
