import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';

abstract interface class CollectionRepository {
  Future<CollectionSummary> summary();

  Future<PageResult<Collection>> list(int page);

  /// The receipt, with what the customer still owes.
  Future<Collection> get(String id);

  Future<CustomerDues> customerDues(String companyId);

  Future<Collection> record(CollectionInput input);

  Future<Collection> setChequeStatus(String id, ChequeStatus status);

  Future<Collection> cancel(String id, String reason);

  Future<OutstandingSummary> outstandingSummary();

  /// Customers who owe money, most overdue first.
  Future<PageResult<CustomerOutstanding>> outstanding(OutstandingQuery query);
}
