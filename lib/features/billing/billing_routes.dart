import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/guards.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/view/add_on_store_screen.dart';
import 'package:salesroot/features/billing/view/add_ons_later_screen.dart';
import 'package:salesroot/features/billing/view/billing_history_screen.dart';
import 'package:salesroot/features/billing/view/checkout_screen.dart';
import 'package:salesroot/features/billing/view/choose_plan_screen.dart';
import 'package:salesroot/features/billing/view/plan_activated_screen.dart';
import 'package:salesroot/features/billing/view/plan_compare_screen.dart';
import 'package:salesroot/features/billing/view/plan_usage_screen.dart';
import 'package:salesroot/features/billing/view/refer_screen.dart';
import 'package:salesroot/features/billing/view/referral_list_screen.dart';
import 'package:salesroot/features/billing/view/referral_qr_screen.dart';
import 'package:salesroot/features/billing/view/referral_wallet_screen.dart';

/// Anyone who hit a quota may see the limit prompt; choosing a plan otherwise
/// needs the billing edit right.
GoRouterRedirect _quotaOrEdit() {
  final edit = requireAccess(AppModule.billing, ModuleRight.edit);
  return (context, state) =>
      _quota(state) == null ? edit(context, state) : null;
}

QuotaKind? _quota(GoRouterState state) {
  final query = state.uri.queryParameters;
  if (query['reason'] != 'quota') return null;
  return QuotaKind.values.asNameMap()[query['kind']];
}

CheckoutRequest _request(GoRouterState state) =>
    CheckoutRequest.fromQuery(state.uri.queryParameters);

final List<RouteBase> billingRoutes = [
  GoRoute(
    path: Routes.planUsage,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) => const PlanUsageScreen(),
  ),
  GoRoute(
    path: Routes.planCompare,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) =>
        PlanCompareScreen(target: state.uri.queryParameters['plan']),
  ),
  GoRoute(
    path: Routes.planChoose,
    redirect: _quotaOrEdit(),
    builder: (context, state) => ChoosePlanScreen(
      quota: _quota(state),
      preselect: state.uri.queryParameters['plan'],
    ),
  ),
  GoRoute(
    path: Routes.checkout,
    redirect: requireAccess(AppModule.billing, ModuleRight.edit),
    builder: (context, state) => CheckoutScreen(request: _request(state)),
  ),
  GoRoute(
    path: Routes.planActivated,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) => PlanActivatedScreen(
      invoiceId: int.tryParse(state.uri.queryParameters['invoice'] ?? '') ?? 0,
    ),
  ),
  GoRoute(
    path: Routes.addOns,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) => const AddOnStoreScreen(),
  ),
  GoRoute(
    path: Routes.addOnsLater,
    redirect: requireAccess(AppModule.billing, ModuleRight.edit),
    builder: (context, state) => AddOnsLaterScreen(request: _request(state)),
  ),
  GoRoute(
    path: Routes.billingHistory,
    redirect: requireAccess(AppModule.billing),
    builder: (context, state) => const BillingHistoryScreen(),
  ),
  GoRoute(
    path: Routes.refer,
    redirect: requireAccess(AppModule.referral),
    builder: (context, state) => const ReferScreen(),
  ),
  GoRoute(
    path: Routes.referInvite,
    redirect: requireAccess(AppModule.referral, ModuleRight.add),
    builder: (context, state) => const ReferScreen(openInvite: true),
  ),
  GoRoute(
    path: Routes.referList,
    redirect: requireAccess(AppModule.referral),
    builder: (context, state) => const ReferralListScreen(),
  ),
  GoRoute(
    path: Routes.referWallet,
    redirect: requireAccess(AppModule.referral),
    builder: (context, state) => const ReferralWalletScreen(),
  ),
  GoRoute(
    path: Routes.referQr,
    redirect: requireAccess(AppModule.referral),
    builder: (context, state) => const ReferralQrScreen(),
  ),
];
