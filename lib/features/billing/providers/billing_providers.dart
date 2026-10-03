import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/billing/data/billing_repository.dart';
import 'package:salesroot/features/billing/data/fake_billing_repository.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/billing_overview.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';

part 'billing_providers.g.dart';

@Riverpod(keepAlive: true)
BillingRepository billingRepository(Ref ref) =>
    FakeBillingRepository(ref.watch(fakeBackendProvider));

@riverpod
Future<BillingCatalog> billingCatalog(Ref ref) =>
    ref.watch(billingRepositoryProvider).catalog();

@riverpod
Future<Subscription> subscription(Ref ref) =>
    ref.watch(billingRepositoryProvider).subscription();

@riverpod
Future<BillingOverview> billingOverview(Ref ref) async {
  final values = await Future.wait<Object?>([
    ref.watch(planProvider.future),
    ref.watch(billingCatalogProvider.future),
    ref.watch(subscriptionProvider.future),
  ]);
  final usage = values[0];
  if (usage is! Plan) throw const ApiFailure(404, 'No workspace selected');
  return BillingOverview(
    usage: usage,
    catalog: values[1] as BillingCatalog,
    subscription: values[2] as Subscription,
  );
}

@riverpod
class InvoicesNotifier extends _$InvoicesNotifier {
  @override
  Future<Paged<Invoice>> build() async =>
      Paged.first(await ref.watch(billingRepositoryProvider).invoices(1));

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(billingRepositoryProvider)
          .invoices(current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }
}

@riverpod
Future<Invoice> invoice(Ref ref, int id) =>
    ref.watch(billingRepositoryProvider).invoice(id);

/// What checkout prices against: the catalog, the current subscription and
/// the referral credit available.
class CheckoutData {
  const CheckoutData({
    required this.catalog,
    required this.subscription,
    required this.walletBalance,
  });

  final BillingCatalog catalog;
  final Subscription subscription;
  final int walletBalance;
}

@riverpod
Future<CheckoutData> checkoutData(Ref ref) async {
  final values = await Future.wait<Object?>([
    ref.watch(billingCatalogProvider.future),
    ref.watch(subscriptionProvider.future),
  ]);
  var balance = 0;
  try {
    balance = (await ref.watch(referralOverviewProvider.future)).balance;
  } on ApiFailure catch (failure) {
    if (!failure.isForbidden) rethrow;
  }
  return CheckoutData(
    catalog: values[0] as BillingCatalog,
    subscription: values[1] as Subscription,
    walletBalance: balance,
  );
}

enum CheckoutPhase { review, processing, failed, done }

class CheckoutFlow {
  const CheckoutFlow({
    this.method,
    this.useCredits = true,
    this.phase = CheckoutPhase.review,
    this.failure,
    this.purchase,
  });

  /// Null until the user picks one; the saved method is used meanwhile.
  final PaymentKind? method;
  final bool useCredits;
  final CheckoutPhase phase;
  final ApiFailure? failure;
  final Purchase? purchase;

  CheckoutFlow copyWith({
    PaymentKind? method,
    bool? useCredits,
    CheckoutPhase? phase,
    ApiFailure? failure,
    Purchase? purchase,
  }) => CheckoutFlow(
    method: method ?? this.method,
    useCredits: useCredits ?? this.useCredits,
    phase: phase ?? this.phase,
    failure: failure,
    purchase: purchase ?? this.purchase,
  );
}

/// The payment run: review → processing → done, or failed with a retry.
@riverpod
class CheckoutFlowNotifier extends _$CheckoutFlowNotifier {
  @override
  CheckoutFlow build() => const CheckoutFlow();

  void selectMethod(PaymentKind method) =>
      state = state.copyWith(method: method, phase: CheckoutPhase.review);

  void setUseCredits(bool value) =>
      state = state.copyWith(useCredits: value, phase: CheckoutPhase.review);

  void backToReview() => state = state.copyWith(phase: CheckoutPhase.review);

  Future<void> pay(
    CheckoutRequest request, {
    required PaymentKind method,
    required int expectedTotal,
  }) async {
    if (state.phase == CheckoutPhase.processing) return;
    state = state.copyWith(phase: CheckoutPhase.processing);
    try {
      final purchase = await ref
          .read(billingRepositoryProvider)
          .pay(
            request,
            method: method,
            useCredits: state.useCredits,
            expectedTotal: expectedTotal,
          );
      if (!ref.mounted) return;
      _unlock(request, purchase.subscription);
      state = state.copyWith(phase: CheckoutPhase.done, purchase: purchase);
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(phase: CheckoutPhase.failed, failure: failure);
    }
  }

  /// Core's plan reads the add-ons from the dev settings, so a purchase that
  /// may change them writes them there before the plan reloads.
  void _unlock(CheckoutRequest request, Subscription subscription) {
    final current = ref.read(planProvider).value?.addOns;
    final touchesAddOns = request.addOns != null || request.plan != null;
    if (touchesAddOns &&
        !const SetEquality<AddOn>().equals(current, subscription.grants)) {
      ref
          .read(devSettingsProvider.notifier)
          .update((s) => s.copyWith(addOns: () => subscription.grants));
    }
    ref
      ..invalidate(planProvider)
      ..invalidate(subscriptionProvider)
      ..invalidate(invoicesProvider)
      ..invalidate(referralOverviewProvider)
      ..invalidate(walletEntriesProvider);
  }
}
