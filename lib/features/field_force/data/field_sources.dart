import 'package:dio/dio.dart';

import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/data/field_api.dart';
import 'package:salesroot/features/field_force/models/field_workspace.dart';

/// `GET workspaces/current`, read once per repository; a failed read is
/// tried again next time.
class FieldWorkspaceSource {
  FieldWorkspaceSource(this._api);

  final FieldApi _api;
  Future<FieldWorkspace>? _workspace;

  Future<FieldWorkspace> get() => _workspace ??= _load();

  Future<FieldWorkspace> _load() async {
    try {
      final json = await apiRequest('Workspace', _api.workspace);
      return FieldWorkspace.fromJson(jsonMap(json));
    } catch (_) {
      _workspace = null;
      rethrow;
    }
  }
}

/// Uploads the photo at [path] against [entityType] [entityId] and returns
/// its file key.
Future<String> uploadPhoto(
  FieldApi api, {
  required String entityType,
  required String entityId,
  required String path,
}) async {
  final json = await apiRequest(
    'Photo upload',
    () async => api.upload(
      FormData.fromMap({
        'file': await MultipartFile.fromFile(path),
        'entityType': entityType,
        'entityId': entityId,
      }),
    ),
  );
  return jsonMap(json)['key'] as String? ?? '';
}
