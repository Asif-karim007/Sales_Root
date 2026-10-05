import 'package:dio/dio.dart';

import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/hr_api.dart';
import 'package:salesroot/features/hr/models/hr_member.dart';

/// Uploads the photo at [path] and returns its storage key.
Future<String> uploadHrPhoto(
  HrApi api,
  String path, {
  String? entityType,
  String? entityId,
}) async {
  final json = await apiRequest(
    'Photo upload',
    () async => api.upload(
      FormData.fromMap({
        'file': await MultipartFile.fromFile(path),
        'entityType': ?entityType,
        'entityId': ?entityId,
      }),
    ),
  );
  return jsonMap(json)['key'] as String? ?? '';
}

Future<List<HrMember>> hrMembers(HrApi api) async =>
    jsonList(await apiRequest('Members', api.members), HrMember.fromJson);
