import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

abstract interface class BillingRepository {
  Future<BillingCatalog> catalog();

  Future<Subscription> subscription();

  /// The workspace's bills of the last year, newest first.
  Future<List<Invoice>> invoices();

  /// Prices [order], a `Checkout` body from [CheckoutRequest.toCheckout].
  Future<Quote> quote(Map<String, dynamic> order);

  /// Raises the bill for [order] and starts the payment.
  Future<CheckoutResult> checkout(Map<String, dynamic> order);

  /// Asks the gateway whether the payment went through.
  Future<void> verify(String transactionId);
}
