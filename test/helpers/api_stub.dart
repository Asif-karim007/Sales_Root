import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/network/api_extras.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/network/interceptors.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';

/// A server answer: a fixed body, or one built from the request. Return a
/// [StubReply] to choose the status per request.
typedef StubAnswer = Object? Function(RequestOptions request);

class StubReply {
  const StubReply(this.status, [this.body]);

  final int status;
  final Object? body;
}

/// Plays the API in tests. Register answers by method and path relative to
/// the base (`leads`, `leads/{id}/stage`); unregistered calls answer 404.
class ApiStub implements HttpClientAdapter {
  final _routes = <_Route>[];

  /// Every request made, oldest first.
  final requests = <RequestOptions>[];

  /// When true, every request fails as if there were no connection.
  bool offline = false;

  void on(String method, String path, Object? body, {int status = 200}) =>
      _routes.insert(
        0,
        _Route(
          method.toUpperCase(),
          _pattern(path),
          status,
          body is StubAnswer ? body : (_) => body,
        ),
      );

  /// Like [on], but only answers when no other route matches.
  void fallback(String method, String path, Object? body) => _routes.add(
    _Route(
      method.toUpperCase(),
      _pattern(path),
      200,
      body is StubAnswer ? body : (_) => body,
    ),
  );

  /// Answers with the server's error body: `{code, message: {bn, en}, field}`.
  void fail(
    String method,
    String path,
    int status, {
    String message = 'Failed',
    String? field,
    String code = 'E-000',
  }) => on(method, path, {
    'code': code,
    'message': {'en': message, 'bn': message},
    'field': ?field,
  }, status: status);

  /// The last request to [path], or null.
  RequestOptions? last(String method, String path) {
    final pattern = _pattern(path);
    for (final request in requests.reversed) {
      if (request.method == method.toUpperCase() &&
          pattern.hasMatch(_relative(request))) {
        return request;
      }
    }
    return null;
  }

  /// The decoded JSON body of the last request to [path].
  Map<String, dynamic> lastBody(String method, String path) {
    final data = last(method, path)?.data;
    if (data is Map<String, dynamic>) return data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return const {};
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
        error: const SocketException('offline'),
      );
    }
    final path = _relative(options);
    for (final route in _routes) {
      if (route.method == options.method && route.path.hasMatch(path)) {
        final answer = route.answer(options);
        return answer is StubReply
            ? _json(answer.body, answer.status)
            : _json(answer, route.status);
      }
    }
    return _json({
      'code': 'E-404',
      'message': {'en': 'Not stubbed: ${options.method} $path'},
    }, 404);
  }

  @override
  void close({bool force = false}) {}

  static ResponseBody _json(Object? body, int status) =>
      ResponseBody.fromString(
        body == null ? '' : jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  static String _relative(RequestOptions options) {
    final base = Uri.parse(ApiConfig.baseUrl).path;
    final path = options.uri.path;
    return path.startsWith(base) ? path.substring(base.length) : path;
  }

  static RegExp _pattern(String path) => RegExp(
    '^${path.split('/').map((part) => part.startsWith('{') ? '[^/]+' : RegExp.escape(part)).join('/')}\$',
  );
}

class _Route {
  const _Route(this.method, this.path, this.status, this.answer);

  final String method;
  final RegExp path;
  final int status;
  final StubAnswer answer;
}

/// A recorded server response from `test/fixtures/api/<name>.json`.
dynamic fixture(String name) =>
    jsonDecode(File('test/fixtures/api/$name.json').readAsStringSync());

Map<String, dynamic> fixtureMap(String name) =>
    fixture(name) as Map<String, dynamic>;

/// `GET auth/me` for one workspace, with the server's role, level and layers.
Map<String, dynamic> meWith({
  String role = 'owner',
  String level = 'advanced',
  bool levelLocked = false,
  List<String>? layers,
}) {
  final me = fixtureMap('auth_me');
  final workspaces = me['workspaces'] as List;
  final workspace = {
    ...workspaces.first as Map<String, dynamic>,
    'role': role,
    'level': level,
    'levelLocked': levelLocked,
    'layers': ?layers,
  };
  return {
    ...me,
    'workspaces': [workspace],
  };
}

/// Dio as the app builds it, answering from [stub].
Dio stubDio(ApiStub stub) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      contentType: Headers.jsonContentType,
      validateStatus: (_) => true,
    ),
  )..httpClientAdapter = stub;
  dio.interceptors.addAll([
    AuthInterceptor(token: () => 'test.access'),
    StatusInterceptor(bangla: () => false),
  ]);
  return dio;
}

/// A signed-in container whose API is [stub]. `auth/me` and `billing`
/// answer from the recorded fixtures unless the test registers its own
/// first; pass [me] to change the role, level or layers.
Future<ProviderContainer> apiContainer(
  ApiStub stub, {
  Map<String, dynamic>? me,
  bool signedIn = true,
  List<Override> overrides = const [],
}) async {
  final tokens = fixtureMap('auth_tokens');
  final profile = me ?? meWith();
  FlutterSecureStorage.setMockInitialValues({
    if (signedIn)
      'session': jsonEncode({
        'token': tokens['accessToken'],
        'refreshToken': tokens['refreshToken'],
        'userId': profile['userId'],
        'name': profile['name'],
        'phone': profile['phone'],
        'workspaceId': profile['workspaceId'],
      }),
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  stub
    ..fallback('GET', 'auth/me', profile)
    ..fallback('GET', 'billing', fixture('billing'));
  final dio = stubDio(stub);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      dioProvider.overrideWithValue(dio),
      bareDioProvider.overrideWithValue(dio),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}
