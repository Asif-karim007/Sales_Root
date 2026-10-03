import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';

abstract interface class QuotationRepository {
  /// A page of quotations, with a `StatusCounts` facet.
  Future<PageResult<Quotation>> list(QuotationQuery query);

  Future<Quotation> get(int id);

  /// Saves a new quotation; sent at once when the input names a channel.
  Future<Quotation> create(QuotationInput input);

  /// Replaces the quotation's terms as its next version.
  Future<Quotation> revise(int id, QuotationInput input);

  Future<Quotation> send(int id, SendChannel channel);

  Future<Quotation> markAccepted(int id);

  Future<Quotation> markRejected(int id);

  /// Marks the quotation accepted and opens an order on its payment terms.
  Future<SalesOrder> convertToOrder(int id);

  Future<void> delete(int id);

  Future<List<SalesCustomer>> customers(String search, int page);

  Future<SalesCustomer> customer(int companyId);

  Future<SalesCustomer> customerForLead(int leadId);

  Future<SellerProfile> seller();
}
