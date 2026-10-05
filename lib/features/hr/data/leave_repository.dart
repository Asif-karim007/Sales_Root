import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/hr/models/leave.dart';

abstract interface class LeaveRepository {
  Future<LeaveLookups> lookups();

  /// The signed-in employee's balances this year.
  Future<List<LeaveBalance>> balances();

  /// The signed-in employee's requests, newest first.
  Future<PageResult<LeaveRequest>> list(LeaveQuery query);

  /// Sends the request and returns its id.
  Future<String> create(LeaveInput input);

  /// Takes back a request that is still pending.
  Future<void> withdraw(String id);
}
