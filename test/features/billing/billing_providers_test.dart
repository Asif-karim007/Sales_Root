import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/models/pricing.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';

import 'billing_test_setup.dart';

/// Prices [request] as checkout would and pays it.
Future<CheckoutFlow> checkout(
  ProviderContainer container,
  CheckoutRequest request, {
  bool useCredits = false,
  int? expectedTotal,
  void Function()? beforePay,
}) async {
  container.listen(checkoutFlowProvider, (_, _) {});
  final data = await container.read(checkoutDataProvider.future);
  beforePay?.call();
  final flow = container.read(checkoutFlowProvider.notifier)
    ..setUseCredits(useCredits);
  final quote = BillingPricing.quote(
    catalog: data.catalog,
    current: data.subscription,
    request: request,
    walletBalance: data.walletBalance,
    useCredits: useCredits,
  );
  await flow.pay(
    request,
    method: PaymentKind.bkash,
    expectedTotal: expectedTotal ?? quote.total,
  );
  return container.read(checkoutFlowProvider);
}

void main() {
  test(
    'the overview joins the plan usage with the Team subscription',
    () async {
      final container = await billingContainer();
      final overview = await container.read(billingOverviewProvider.future);
      expect(overview.plan.code, 'Team');
      expect(overview.subscription.seats, 25);
      expect(overview.subscription.unusedDays, 3);
      expect(overview.renewal, 9975 + 2475);
      final scans = overview.meters.firstWhere(
        (m) => m.kind == QuotaKind.cardScans,
      );
      expect(scans.used, 44);
      expect(scans.limit, 50);
      expect(scans.nearLimit, isTrue);
    },
  );

  test('invoices page 20 at a time', () async {
    final container = await billingContainer();
    container.listen(invoicesProvider, (_, _) {});
    final first = await container.read(invoicesProvider.future);
    expect(first.items, hasLength(20));
    expect(first.totalCount, 24);
    expect(first.hasMore, isTrue);

    await container.read(invoicesProvider.notifier).loadMore();
    final all = container.read(invoicesProvider).requireValue;
    expect(all.items, hasLength(24));
    expect(all.hasMore, isFalse);
  });

  test('the Free workspace has no bills', () async {
    final container = await billingContainer(workspaceId: 100);
    final first = await container.read(invoicesProvider.future);
    expect(first.isEmpty, isTrue);
    final overview = await container.read(billingOverviewProvider.future);
    expect(overview.plan.isFree, isTrue);
  });

  test('buying Growth unlocks it in the plan and the modules', () async {
    final container = await billingContainer();
    await container.read(permissionsProvider.future);
    final before = await container.read(planProvider.future);
    expect(before?.has(AddOn.growth), isFalse);
    expect(
      container.read(moduleAccessProvider(AppModule.inbox)).lockedByPlan,
      isTrue,
    );

    final flow = await checkout(
      container,
      const CheckoutRequest(addOns: {'FieldForce', 'Growth'}),
    );

    expect(flow.phase, CheckoutPhase.done);
    final purchase = flow.purchase;
    expect(purchase?.invoice.kind, InvoiceKind.addOn);
    expect(purchase?.subscription.grants, {AddOn.fieldForce, AddOn.growth});
    expect(container.read(devSettingsProvider).addOns, {
      AddOn.fieldForce,
      AddOn.growth,
    });

    final after = await container.read(planProvider.future);
    expect(after?.has(AddOn.growth), isTrue);
    expect(container.read(moduleAccessProvider(AppModule.inbox)).canView, true);

    final subscription = await container.read(subscriptionProvider.future);
    expect(subscription.addOns, {'FieldForce', 'Growth'});
    final invoices = await container.read(invoicesProvider.future);
    expect(invoices.items.first.id, purchase?.invoice.id);
  });

  test('a plan change starts a new period and keeps the add-ons', () async {
    final container = await billingContainer();
    final flow = await checkout(
      container,
      const CheckoutRequest(plan: 'Business', seats: 25),
    );
    expect(flow.phase, CheckoutPhase.done);
    final overview = await container.read(billingOverviewProvider.future);
    expect(overview.plan.code, 'Business');
    expect(overview.subscription.unusedDays, 30);
    expect(overview.subscription.addOns, {'FieldForce'});
  });

  test('a pack raises the quota without touching the add-ons', () async {
    final container = await billingContainer();
    final flow = await checkout(
      container,
      const CheckoutRequest(packs: ['Scans50']),
    );
    expect(flow.purchase?.invoice.kind, InvoiceKind.pack);
    expect(container.read(devSettingsProvider).addOns, isNull);
    final overview = await container.read(billingOverviewProvider.future);
    final scans = overview.meters.firstWhere(
      (m) => m.kind == QuotaKind.cardScans,
    );
    expect(scans.limit, 100);
  });

  test('credits are redeemed from the referral wallet', () async {
    final container = await billingContainer();
    final wallet = await container.read(referralOverviewProvider.future);
    final flow = await checkout(
      container,
      const CheckoutRequest(plan: 'Business'),
      useCredits: true,
    );
    final credits = flow.purchase?.invoice.quote.credits ?? 0;
    expect(credits, wallet.balance);
    final after = await container.read(referralOverviewProvider.future);
    expect(after.balance, 0);
    expect(after.used, wallet.used + credits);
  });

  test('injected errors fail the payment and change nothing', () async {
    final container = await billingContainer();
    final flow = await checkout(
      container,
      const CheckoutRequest(addOns: {'FieldForce', 'Growth'}),
      beforePay: () => container
          .read(devSettingsProvider.notifier)
          .update((s) => s.copyWith(injectErrors: true)),
    );
    expect(flow.phase, CheckoutPhase.failed);
    expect(flow.failure, isNotNull);
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(injectErrors: false));
    final plan = await container.read(planProvider.future);
    expect(plan?.has(AddOn.growth), isFalse);
  });

  test('a stale total is rejected with 409', () async {
    final container = await billingContainer();
    final flow = await checkout(
      container,
      const CheckoutRequest(plan: 'Business'),
      expectedTotal: 1,
    );
    expect(flow.phase, CheckoutPhase.failed);
    expect(flow.failure?.isConflict, isTrue);
  });

  test('seats below the active members are a 400', () async {
    final container = await billingContainer();
    final flow = await checkout(container, const CheckoutRequest(seats: 10));
    expect(flow.failure?.isValidation, isTrue);
  });

  test('offline shows as an offline failure', () async {
    final container = await billingContainer();
    container
        .read(devSettingsProvider.notifier)
        .update((s) => s.copyWith(offline: true));
    await expectLater(
      container.read(billingRepositoryProvider).subscription(),
      throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
    );
  });

  test('a member gets 403 from billing', () async {
    final container = await billingContainer(role: WorkspaceRole.member);
    await expectLater(
      container.read(billingRepositoryProvider).subscription(),
      throwsA(
        isA<ApiFailure>().having((f) => f.isForbidden, 'forbidden', true),
      ),
    );
  });
}
