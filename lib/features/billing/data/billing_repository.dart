import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/models/subscription.dart';

abstract interface class BillingRepository {
  Future<BillingCatalog> catalog();

  Future<Subscription> subscription();

  Future<PageResult<Invoice>> invoices(int page);

  /// Every bill, for the all-receipts PDF.
  Future<List<Invoice>> receipts();

  Future<Invoice> invoice(int id);

  /// Charges [method] for [request]. The server prices it again and answers
  /// 409 when the total differs from [expectedTotal].
  Future<Purchase> pay(
    CheckoutRequest request, {
    required PaymentKind method,
    required bool useCredits,
    required int expectedTotal,
  });
}
