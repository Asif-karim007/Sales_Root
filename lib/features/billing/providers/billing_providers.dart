import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/billing/data/billing_repositories.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/billing_overview.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';

part 'billing_providers.g.dart';

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
Future<List<Invoice>> invoices(Ref ref) =>
    ref.watch(billingRepositoryProvider).invoices();

@riverpod
Future<Invoice> invoice(Ref ref, String id) async {
  final list = await ref.watch(invoicesProvider.future);
  return list.where((i) => i.id == id).firstOrNull ??
      (throw const ApiFailure(404, 'Invoice not found'));
}

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

  Map<String, dynamic> order(
    CheckoutRequest request, {
    required PaymentKind method,
    required bool useCredits,
  }) => request.toCheckout(
    current: subscription,
    catalog: catalog,
    method: method,
    useCredits: useCredits,
  );
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

/// The server's price for [request] paid by [method].
@riverpod
Future<Quote> checkoutQuote(
  Ref ref,
  CheckoutRequest request,
  PaymentKind method,
  bool useCredits,
) async {
  final data = await ref.watch(checkoutDataProvider.future);
  return ref
      .watch(billingRepositoryProvider)
      .quote(data.order(request, method: method, useCredits: useCredits));
}

enum CheckoutPhase { review, processing, awaitingPayment, failed, done }

class CheckoutFlow {
  const CheckoutFlow({
    this.method = PaymentKind.bkash,
    this.useCredits = true,
    this.phase = CheckoutPhase.review,
    this.failure,
    this.result,
  });

  final PaymentKind method;
  final bool useCredits;
  final CheckoutPhase phase;
  final ApiFailure? failure;
  final CheckoutResult? result;

  CheckoutFlow copyWith({
    PaymentKind? method,
    bool? useCredits,
    CheckoutPhase? phase,
    ApiFailure? failure,
    CheckoutResult? result,
  }) => CheckoutFlow(
    method: method ?? this.method,
    useCredits: useCredits ?? this.useCredits,
    phase: phase ?? this.phase,
    failure: failure,
    result: result ?? this.result,
  );
}

/// The payment run: review → processing → paying at the gateway → done, or
/// failed with a retry.
@riverpod
class CheckoutFlowNotifier extends _$CheckoutFlowNotifier {
  @override
  CheckoutFlow build() => const CheckoutFlow();

  void selectMethod(PaymentKind method) =>
      state = state.copyWith(method: method, phase: CheckoutPhase.review);

  void setUseCredits(bool value) =>
      state = state.copyWith(useCredits: value, phase: CheckoutPhase.review);

  void backToReview() => state = state.copyWith(phase: CheckoutPhase.review);

  Future<void> pay(CheckoutRequest request) async {
    if (state.phase == CheckoutPhase.processing) return;
    state = state.copyWith(phase: CheckoutPhase.processing);
    final pricing = ref.listen(checkoutDataProvider.future, (_, _) {});
    try {
      final data = await pricing.read();
      if (!ref.mounted) return;
      final result = await ref
          .read(billingRepositoryProvider)
          .checkout(
            data.order(
              request,
              method: state.method,
              useCredits: state.useCredits,
            ),
          );
      if (!ref.mounted) return;
      final waiting = !result.paid && result.paymentUrl != null;
      if (!waiting) _refresh();
      state = state.copyWith(
        phase: waiting ? CheckoutPhase.awaitingPayment : CheckoutPhase.done,
        result: result,
      );
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(phase: CheckoutPhase.failed, failure: failure);
    } finally {
      pricing.close();
    }
  }

  /// After paying at the gateway: has the payment arrived?
  Future<void> confirm() async {
    final transaction = state.result?.transactionId;
    if (state.phase == CheckoutPhase.processing) return;
    state = state.copyWith(phase: CheckoutPhase.processing);
    try {
      if (transaction != null) {
        await ref.read(billingRepositoryProvider).verify(transaction);
      }
      if (!ref.mounted) return;
      _refresh();
      state = state.copyWith(phase: CheckoutPhase.done);
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(phase: CheckoutPhase.failed, failure: failure);
    }
  }

  void _refresh() => ref
    ..invalidate(planProvider)
    ..invalidate(subscriptionProvider)
    ..invalidate(invoicesProvider)
    ..invalidate(referralOverviewProvider)
    ..invalidate(walletEntriesProvider);
}
