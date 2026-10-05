import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_api.dart';

abstract interface class WorkspaceRepository {
  Future<List<Workspace>> list();

  /// Creates a team workspace and returns its id.
  Future<String> create(String name, {String? industryPack});
}

class ApiWorkspaceRepository implements WorkspaceRepository {
  ApiWorkspaceRepository(this._api);

  final WorkspaceApi _api;

  @override
  Future<List<Workspace>> list() async {
    final me = jsonMap(await apiRequest('Workspace list', _api.me));
    return jsonList(me['workspaces'], Workspace.fromJson);
  }

  @override
  Future<String> create(String name, {String? industryPack}) async {
    final body = {
      'name': name.trim(),
      'type': 'sme',
      'industryPack': industryPack,
      'loadSampleData': false,
    }..removeWhere((_, value) => value == null);
    final json = jsonMap(
      await apiRequest('Workspace create', () => _api.create(body)),
    );
    return jsonId(json['id']) ??
        jsonId(json['workspaceId']) ??
        jsonId(jsonMap(json['workspace'])['id']) ??
        jsonId(jsonMap(json['me'])['workspaceId']) ??
        '';
  }
}
