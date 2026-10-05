import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';

abstract interface class QuotationRepository {
  Future<PageResult<Quotation>> list(QuotationQuery query);

  /// The quotation with its lines, and the order made from it once accepted.
  Future<Quotation> get(String id);

  Future<Quotation> create(QuotationInput input);

  /// Replaces the quotation's lines and terms.
  Future<Quotation> save(String id, QuotationInput input);

  /// A manager clears a quotation sent for approval.
  Future<Quotation> approve(String id);

  /// The server sends the customer the link to the quotation.
  Future<Quotation> send(String id);

  /// A new draft with the same customer, lines and terms.
  Future<Quotation> duplicate(String id);

  /// Marks the quotation accepted and opens an order from it.
  Future<SalesOrder> convertToOrder(String id);

  Future<List<SalesCustomer>> customers(String search, int page);

  Future<SalesCustomer> customer(String companyId);

  Future<SalesCustomer> customerForLead(String leadId);

  Future<SellerProfile> seller();
}
