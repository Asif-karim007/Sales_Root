import 'package:dio/dio.dart' hide LogInterceptor;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_extras.dart';
import 'package:salesroot/core/network/interceptors.dart';
import 'package:salesroot/core/session/session_api.dart';
import 'package:salesroot/core/session/session_provider.dart';

part 'dio_providers.g.dart';

BaseOptions _options() => BaseOptions(
  baseUrl: ApiConfig.baseUrl,
  connectTimeout: ApiConfig.timeout,
  sendTimeout: ApiConfig.timeout,
  receiveTimeout: ApiConfig.timeout,
  contentType: Headers.jsonContentType,
  responseType: ResponseType.json,
  validateStatus: (_) => true,
);

/// The signed API client every feature's Retrofit interface is built on.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(_options());
  dio.transformer = FusedTransformer(contentLengthIsolateThreshold: 2048);
  dio.interceptors.addAll([
    AuthInterceptor(token: () => ref.read(sessionProvider).value?.token),
    EmptyBodyInterceptor(),
    LogInterceptor(),
    StatusInterceptor(
      bangla: () => ref.read(appLocaleProvider) == bangla,
      onSessionExpired: () => ref.read(sessionProvider.notifier).expire(),
      refresh: () => ref.read(sessionProvider.notifier).refreshToken(),
      replay: dio.fetch,
    ),
  ]);
  return dio;
}

/// For the calls made without a session: sign-in codes and token refresh.
@Riverpod(keepAlive: true)
Dio bareDio(Ref ref) {
  final dio = Dio(_options());
  dio.transformer = FusedTransformer(contentLengthIsolateThreshold: 2048);
  dio.interceptors.addAll([
    EmptyBodyInterceptor(),
    LogInterceptor(),
    StatusInterceptor(bangla: () => ref.read(appLocaleProvider) == bangla),
  ]);
  return dio;
}

@Riverpod(keepAlive: true)
SessionApi sessionApi(Ref ref) => SessionApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
SessionApi bareSessionApi(Ref ref) => SessionApi(ref.watch(bareDioProvider));
