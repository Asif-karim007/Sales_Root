import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/data/billing_fixtures.dart';
import 'package:salesroot/features/billing/data/billing_repository.dart';
import 'package:salesroot/features/billing/data/fake_referral_ledger.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/models/pricing.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

class FakeBillingRepository implements BillingRepository {
  FakeBillingRepository(this._backend) : _ledger = FakeReferralLedger(_backend);

  final FakeBackend _backend;
  final FakeReferralLedger _ledger;

  static final BillingCatalog _catalog = BillingCatalog.fromJson(
    billingCatalogJson,
  );

  static const Map<PaymentKind, String> _accounts = {
    PaymentKind.bkash: '01711••••67',
    PaymentKind.nagad: '01711••••67',
    PaymentKind.card: '•••• 4242',
  };

  /// Account state, so it keeps its seed even in an empty workspace.
  FakeTable get _subscriptions => _backend.store.table(
    '${_backend.graph.workspaceId}/billing_subscription',
    () => subscriptionFixtures(_backend.graph),
    always: true,
  );

  FakeTable get _invoices =>
      _backend.table('billing_invoices', invoiceFixtures);

  Map<String, dynamic> get _subscriptionRow => _subscriptions.byId(1);

  Map<String, dynamic> _subscriptionJson(Map<String, dynamic> row) {
    final renewsAt = jsonDate(row['RenewsAt']);
    final hours = renewsAt == null
        ? 0
        : AppDateUtils.dateOnly(
            renewsAt,
          ).difference(AppDateUtils.dateOnly(_backend.graph.anchor)).inHours;
    return {
      ...row,
      'UnusedDays': hours <= 0 ? 0 : (hours / 24).round(),
      'Grants': [
        for (final code in jsonStrings(row['AddOns']))
          ?_catalog.addOnOrNull(code)?.grants?.wire,
      ],
    };
  }

  Subscription get _current =>
      Subscription.fromJson(_subscriptionJson(_subscriptionRow));

  @override
  Future<BillingCatalog> catalog() => _backend.run(
    'Billing catalog',
    () => _catalog,
    module: AppModule.billing,
  );

  @override
  Future<Subscription> subscription() => _backend.run(
    'Billing subscription',
    () => _current,
    module: AppModule.billing,
  );

  @override
  Future<PageResult<Invoice>> invoices(int page) => _backend.run(
    'Billing invoices',
    () => PageResult.fromJson(
      fakePage(_invoices.rows, page: page),
      Invoice.fromJson,
    ),
    module: AppModule.billing,
  );

  @override
  Future<List<Invoice>> receipts() => _backend.run(
    'Billing receipts',
    () => [for (final row in _invoices.rows) Invoice.fromJson(row)],
    module: AppModule.billing,
    right: ModuleRight.export,
  );

  @override
  Future<Invoice> invoice(int id) => _backend.run(
    'Billing invoice $id',
    () => Invoice.fromJson(_invoices.byId(id)),
    module: AppModule.billing,
  );

  @override
  Future<Purchase> pay(
    CheckoutRequest request, {
    required PaymentKind method,
    required bool useCredits,
    required int expectedTotal,
  }) => _backend.run(
    'Billing pay',
    () {
      final current = _current;
      _validate(request, current);
      final quote = BillingPricing.quote(
        catalog: _catalog,
        current: current,
        request: request,
        walletBalance: _ledger.balance,
        useCredits: useCredits,
      );
      if (quote.lines.isEmpty) {
        throw const ApiFailure(400, 'There is nothing to pay for.');
      }
      if (quote.total != expectedTotal) {
        throw const ApiFailure(
          409,
          'The price has changed. Check the order and try again.',
        );
      }
      if (quote.total > 0) _charge(method);
      final payment = quote.total > 0
          ? {'Kind': method.wire, 'Account': _accounts[method]}
          : null;
      final row = _apply(current, request, payment);
      final invoice = _issue(quote, row, payment);
      if (quote.credits > 0) {
        _ledger.redeem(
          quote.credits,
          invoice['Number'] as String,
          row['PlanCode'] as String,
        );
      }
      return Purchase(
        invoice: Invoice.fromJson(invoice),
        subscription: Subscription.fromJson(_subscriptionJson(row)),
      );
    },
    module: AppModule.billing,
    right: ModuleRight.edit,
  );

  void _charge(PaymentKind method) {
    if (!method.inApp) {
      throw const ApiFailure(
        400,
        'Bank transfers are paid on the web.',
        fieldErrors: {'PaymentMethod': 'Pay by bank on the web'},
      );
    }
    if (_backend.settings.injectErrors) {
      throw const ApiFailure(
        400,
        'The payment was not confirmed. No money was taken.',
        fieldErrors: {'Payment': 'Declined'},
      );
    }
  }

  void _validate(CheckoutRequest request, Subscription current) {
    final plan = _catalog.plan(request.plan ?? current.planCode);
    final seats = request.seats ?? current.seats;
    if (seats < 1 || !plan.fits(seats)) {
      throw ApiFailure(
        400,
        '${plan.name} allows ${plan.maxUsers ?? seats} user(s).',
        fieldErrors: const {'Seats': 'Too many seats for this plan'},
      );
    }
    if (seats < current.activeUsers) {
      throw ApiFailure(
        400,
        '${current.activeUsers} members are active. Remove members first.',
        fieldErrors: const {'Seats': 'Fewer seats than active members'},
      );
    }
    for (final code in request.addOns ?? const <String>{}) {
      final offer = _catalog.addOn(code);
      if (offer.isPack || !_catalog.available(offer, plan)) {
        throw ApiFailure(
          400,
          '${offer.name.en} is not available on ${plan.name}.',
        );
      }
    }
    for (final code in request.packs) {
      if (!_catalog.addOn(code).isPack) {
        throw ApiFailure(400, '$code is not a pack.');
      }
    }
  }

  Map<String, dynamic> _apply(
    Subscription current,
    CheckoutRequest request,
    Map<String, dynamic>? payment,
  ) {
    final plan = _catalog.plan(request.plan ?? current.planCode);
    final cycle = request.cycle ?? current.cycle;
    final newPeriod = plan.code != current.planCode || cycle != current.cycle;
    final addOns = (request.addOns ?? current.addOns).where((code) {
      final offer = _catalog.addOn(code);
      return !offer.isPack && offer.includedIn != plan.code;
    });
    var scans = current.extraCardScans;
    var sms = current.extraSmsCredits;
    var storage = current.extraStorageGb;
    for (final code in request.packs) {
      final pack = _catalog.addOn(code);
      switch (pack.quota) {
        case QuotaKind.cardScans:
          scans += pack.amount;
        case QuotaKind.smsCredits:
          sms += pack.amount;
        case QuotaKind.storage:
          storage += pack.amount;
        case QuotaKind.users || QuotaKind.records || null:
          break;
      }
    }
    return _subscriptions.update(1, {
      'PlanCode': plan.code,
      'Seats': request.seats ?? current.seats,
      'Cycle': cycle.wire,
      'AddOns': addOns.toList(),
      'ExtraCardScans': scans,
      'ExtraSmsCredits': sms,
      'ExtraStorageGb': storage,
      if (newPeriod)
        'RenewsAt': AppDateUtils.toApiUtc(
          _backend.graph.anchor.add(Duration(days: cycle.days)),
        ),
      'PaymentMethod': ?payment,
    });
  }

  Map<String, dynamic> _issue(
    Quote quote,
    Map<String, dynamic> subscription,
    Map<String, dynamic>? payment,
  ) {
    final first = quote.lines.first;
    final kind = switch (first.kind) {
      OrderLineKind.plan ||
      OrderLineKind.seats ||
      OrderLineKind.planCredit => InvoiceKind.plan,
      OrderLineKind.addOn || OrderLineKind.addOnProrated => InvoiceKind.addOn,
      OrderLineKind.pack => InvoiceKind.pack,
    };
    final now = AppDateUtils.toApiUtc(_backend.graph.anchor);
    return _invoices.insert({
      'Number': 'INV-SR-${4470 + _invoices.nextId()}',
      'Kind': kind.wire,
      'ItemName': first.name.en,
      'ItemNameBn': first.name.bn,
      'IssuedAt': now,
      if (kind == InvoiceKind.plan) 'PeriodStart': now,
      'Seats': subscription['Seats'],
      'Status': InvoiceStatus.paid.wire,
      'PaymentMethod': ?payment,
      ...quote.toJson(),
    });
  }
}
