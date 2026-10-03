import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';

abstract interface class CollectionRepository {
  Future<CollectionSummary> summary();

  /// Open instalments due within a month or overdue, most urgent first.
  Future<PageResult<DueRow>> dues(int page);

  Future<PageResult<Collection>> list(int page);

  Future<Collection> get(int id);

  Future<CustomerDues> customerDues(int companyId);

  Future<Collection> record(CollectionInput input);

  Future<OutstandingSummary> outstandingSummary();

  Future<PageResult<CustomerOutstanding>> outstanding(
    OutstandingFilter filter, {
    String search = '',
    int page = 1,
  });
}
