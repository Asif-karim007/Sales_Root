import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/models/expense.dart';

abstract interface class ExpenseRepository {
  /// The categories, the signed-in rep's recent visits and who approves.
  Future<ExpenseLookups> lookups();

  /// The signed-in employee's claims, newest first, with a `totals` facet
  /// keyed `pending`, `approvedUnpaid` and `reimbursed`.
  Future<PageResult<ExpenseClaim>> list(ExpenseQuery query);

  /// Sends the claim and returns its id.
  Future<String> create(ExpenseInput input);

  /// Takes back a claim that is still pending.
  Future<void> withdraw(String id);
}
