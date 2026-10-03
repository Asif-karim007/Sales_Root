import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/models/leave.dart';

abstract interface class LeaveRepository {
  Future<LeaveLookups> lookups();

  /// The balances of the signed-in employee, or of [employeeId].
  Future<List<LeaveBalance>> balances({int? employeeId});

  Future<PageResult<LeaveRequest>> list(LeaveQuery query);

  Future<LeaveRequest> create(LeaveInput input);

  /// Takes back a request that is still pending.
  Future<void> withdraw(int id);
}
