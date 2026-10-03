import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/widgets/sr_coming_soon.dart';

final List<RouteBase> billingRoutes = [
  GoRoute(
    path: Routes.planUsage,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.planCompare,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.planChoose,
    redirect: requireAccess(AppModule.billing, ModuleRight.edit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.checkout,
    redirect: requireAccess(AppModule.billing, ModuleRight.edit),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.planActivated,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.addOns,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.addOnsLater,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.billingHistory,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.refer,
    redirect: requireAccess(AppModule.referral),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.referInvite,
    redirect: requireAccess(AppModule.referral, ModuleRight.add),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.referList,
    redirect: requireAccess(AppModule.referral),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.referWallet,
    redirect: requireAccess(AppModule.referral),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
  GoRoute(
    path: Routes.referQr,
    redirect: requireAccess(AppModule.referral),
    builder: (context, state) =>
        SrComingSoonScreen(title: state.matchedLocation),
  ),
];
