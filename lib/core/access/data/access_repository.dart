import 'package:salesroot/core/access/data/access_api.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/access/plan.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';

abstract interface class AccessRepository {
  Future<Plan> plan();

  Future<void> setLevel(ExperienceLevel level);
}

class ApiAccessRepository implements AccessRepository {
  ApiAccessRepository(this._api);

  final AccessApi _api;

  @override
  Future<Plan> plan() async =>
      Plan.fromBilling(jsonMap(await apiRequest('Plan', _api.billing)));

  @override
  Future<void> setLevel(ExperienceLevel level) => apiRequest(
    'Experience level',
    () => _api.updateMe({'level': level.wire}),
  );
}
