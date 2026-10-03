import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/models/expense.dart';

abstract interface class ExpenseRepository {
  Future<ExpenseLookups> lookups();

  /// A visit to link a claim to, with its locations.
  Future<ExpenseVisit> visit(int id);

  /// The signed-in employee's claims, newest first, with `StatusCounts` and
  /// `StatusTotals` facets keyed by stage.
  Future<PageResult<ExpenseClaim>> list(ExpenseQuery query);

  Future<ExpenseClaim> create(ExpenseInput input);

  /// Takes back a claim that is still pending.
  Future<ExpenseClaim> withdraw(int id);
}
