import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/expense_repository.dart';
import 'package:salesroot/features/hr/data/hr_api.dart';
import 'package:salesroot/features/hr/data/hr_sources.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/models/hr_member.dart';

class ApiExpenseRepository implements ExpenseRepository {
  ApiExpenseRepository(this._api, {this.membershipId});

  final HrApi _api;

  /// The signed-in member, whose visits can be linked.
  final String? membershipId;

  @override
  Future<ExpenseLookups> lookups() async {
    final [categories, visits] = await Future.wait([
      apiRequest('Expense categories', _api.expenseCategories),
      apiRequest(
        'Recent visits',
        () => _api.visits({'membershipId': ?membershipId, ...pageQuery(1)}),
      ),
    ]);
    final members = await hrMembers(_api);
    return ExpenseLookups(
      types: [
        for (final row in jsonList(categories, (row) => row))
          if (row['isActive'] != false) ExpenseType.fromJson(row),
      ],
      visits: jsonList(jsonMap(visits)['items'], ExpenseVisit.fromJson),
      approverName: members.managerOf(membershipId)?.name,
    );
  }

  @override
  Future<PageResult<ExpenseClaim>> list(ExpenseQuery query) async {
    final json = await apiRequest(
      'Expense list',
      () => _api.expenses(query.toQuery()),
    );
    return PageResult.fromJson(jsonMap(json), ExpenseClaim.fromJson);
  }

  @override
  Future<String> create(ExpenseInput input) async {
    final path = input.receiptPath;
    final receiptKey = path == null ? null : await uploadHrPhoto(_api, path);
    final json = await apiRequest(
      'Expense create',
      () => _api.createExpense(input.toJson(receiptKey: receiptKey)),
    );
    return jsonId(jsonMap(json)['id']) ?? '';
  }

  @override
  Future<void> withdraw(String id) =>
      apiRequest('Expense delete', () => _api.deleteExpense(id));
}
