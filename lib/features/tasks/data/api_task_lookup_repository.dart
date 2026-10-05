import 'package:collection/collection.dart';

import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/tasks/data/task_api.dart';
import 'package:salesroot/features/tasks/data/task_lookup_repository.dart';
import 'package:salesroot/features/tasks/models/task_lookups.dart';

class ApiTaskLookupRepository implements TaskLookupRepository {
  ApiTaskLookupRepository(this._api, {this.me});

  final TaskApi _api;

  /// The user's membership id in the current workspace.
  final String? me;

  @override
  Future<PageResult<LeadOption>> searchLeads(String term, int page) async {
    final text = term.trim();
    final json = await apiRequest(
      'Lead lookup',
      () => _api.leads({if (text.isNotEmpty) 'q': text, ...pageQuery(page)}),
    );
    return PageResult.fromJson(jsonMap(json), LeadOption.fromJson);
  }

  @override
  Future<LeadOption> lead(String id) async {
    final json = jsonMap(await apiRequest('Lead $id', () => _api.lead(id)));
    return LeadOption.fromJson(jsonMap(json['lead']));
  }

  @override
  Future<List<MemberOption>> members() async {
    final json = await apiRequest('Member lookup', _api.members);
    return [
      for (final row in jsonList(json, (row) => row))
        if ((row['status'] ?? 'active') == 'active')
          MemberOption.fromJson(row, me: me),
    ];
  }

  @override
  Future<String?> findCompany(String name) async {
    final wanted = _normalise(name);
    if (wanted.isEmpty) return null;
    final json = await apiRequest(
      'Company match',
      () => _api.companies({'q': name.trim(), ...pageQuery(1)}),
    );
    final match = jsonList(
      jsonMap(json)['items'],
      (row) => row,
    ).firstWhereOrNull((row) => _normalise('${row['name'] ?? ''}') == wanted);
    return jsonId(match?['id']);
  }

  static String _normalise(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'\b(ltd|limited|pvt|co)\b'), '')
      .replaceAll(RegExp('[^a-z0-9]'), '');
}
