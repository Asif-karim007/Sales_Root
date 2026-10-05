import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/billing/data/billing_api.dart';
import 'package:salesroot/features/billing/data/billing_repository.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

class ApiBillingRepository implements BillingRepository {
  ApiBillingRepository(this._api);

  final BillingApi _api;

  @override
  Future<BillingCatalog> catalog() async {
    final json = await apiRequest('Billing catalogue', () => _api.catalogue());
    return BillingCatalog.fromJson(jsonMap(json));
  }

  @override
  Future<Subscription> subscription() async {
    final json = await apiRequest('Billing', () => _api.billing());
    return Subscription.fromJson(jsonMap(json));
  }

  @override
  Future<List<Invoice>> invoices() async {
    final json = await apiRequest('Billing history', () => _api.history());
    return jsonList(jsonMap(json)['invoices'], Invoice.fromJson);
  }

  @override
  Future<Quote> quote(Map<String, dynamic> order) async {
    final json = await apiRequest('Billing quote', () => _api.quote(order));
    return Quote.fromJson(jsonMap(json));
  }

  @override
  Future<CheckoutResult> checkout(Map<String, dynamic> order) async {
    final json = await apiRequest(
      'Billing checkout',
      () => _api.checkout(order),
    );
    return CheckoutResult.fromJson(jsonMap(json));
  }

  @override
  Future<void> verify(String transactionId) =>
      apiRequest('Billing verify', () => _api.verify(transactionId));
}
