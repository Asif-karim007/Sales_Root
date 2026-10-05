import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/hr_api.dart';
import 'package:salesroot/features/hr/data/hr_sources.dart';
import 'package:salesroot/features/hr/data/leave_repository.dart';
import 'package:salesroot/features/hr/models/hr_json.dart';
import 'package:salesroot/features/hr/models/hr_member.dart';
import 'package:salesroot/features/hr/models/leave.dart';

class ApiLeaveRepository implements LeaveRepository {
  ApiLeaveRepository(this._api, {this.membershipId});

  final HrApi _api;

  /// The signed-in member, whose manager approves.
  final String? membershipId;

  @override
  Future<LeaveLookups> lookups() async {
    final [types, holidays] = await Future.wait([
      apiRequest('Leave types', _api.leaveTypes),
      apiRequest('Holidays', () => _api.holidays(const {})),
    ]);
    final members = await hrMembers(_api);
    return LeaveLookups(
      leaveTypes: [
        for (final row in jsonList(types, (row) => row))
          if (row['isActive'] != false) LeaveType.fromJson(row),
      ],
      holidays: {
        for (final row in jsonList(holidays, (row) => row))
          ?jsonDay(row['day']),
      },
      approverName: members.managerOf(membershipId)?.name,
    );
  }

  @override
  Future<List<LeaveBalance>> balances() async => jsonList(
    await apiRequest('Leave balance', () => _api.leaveBalance(const {})),
    LeaveBalance.fromJson,
  );

  @override
  Future<PageResult<LeaveRequest>> list(LeaveQuery query) async {
    final json = await apiRequest(
      'Leave list',
      () => _api.leaves(query.toQuery()),
    );
    return PageResult.fromJson(jsonMap(json), LeaveRequest.fromJson);
  }

  @override
  Future<String> create(LeaveInput input) async {
    final path = input.documentPath;
    final docKey = path == null ? null : await uploadHrPhoto(_api, path);
    final json = await apiRequest(
      'Leave create',
      () => _api.createLeave(input.toJson(docKey: docKey)),
    );
    return jsonId(jsonMap(json)['id']) ?? '';
  }

  @override
  Future<void> withdraw(String id) =>
      apiRequest('Leave cancel', () => _api.cancelLeave(id));
}
