import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final salesBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: Routes.sales,
      redirect: requireAccess(AppModule.quotation),
      builder: (context, state) =>
          SrComingSoonScreen(title: state.matchedLocation),
    ),
  ],
);

final List<RouteBase> salesRoutes = [
  GoRoute(
    path: Routes.products,
    redirect: requireAccess(AppModule.product),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.quotations,
    redirect: requireAccess(AppModule.quotation),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.quotationNew,
    redirect: requireAccess(AppModule.quotation, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.quotation,
    redirect: requireAccess(AppModule.quotation),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.order,
    redirect: requireAccess(AppModule.order),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.orderDelivery,
    redirect: requireAccess(AppModule.order, ModuleRight.edit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.invoice,
    redirect: requireAccess(AppModule.invoice),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.collection,
    redirect: requireAccess(AppModule.collection),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.collectionNew,
    redirect: requireAccess(AppModule.collection, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.receipt,
    redirect: requireAccess(AppModule.collection),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.outstanding,
    redirect: requireAccess(AppModule.collection),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
