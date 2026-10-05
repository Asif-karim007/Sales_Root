import 'package:dio/dio.dart' hide LogInterceptor;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_extras.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/interceptors.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

part 'dio_providers.g.dart';

/// The API client. Retrofit interfaces are built on it, one keepAlive
/// provider each, when their feature goes live.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      validateStatus: (_) => true,
    ),
  );
  dio.transformer = FusedTransformer(contentLengthIsolateThreshold: 2048);
  dio.interceptors.addAll([
    AuthInterceptor(
      token: () => ref.read(sessionProvider).value?.token,
      workspaceId: () => ref.read(currentWorkspaceProvider)?.id,
    ),
    LogInterceptor(),
    StatusInterceptor(
      onSessionExpired: () => ref.read(sessionProvider.notifier).expire(),
      bangla: () => ref.read(appLocaleProvider) == bangla,
    ),
  ]);
  return dio;
}
