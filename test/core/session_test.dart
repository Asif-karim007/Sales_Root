import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/network/api_extras.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/interceptors.dart';
import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/session/session_store.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

import '../helpers/api_stub.dart';

void main() {
  group('token refresh', () {
    Dio refreshingDio(ApiStub stub, Future<String?> Function() refresh) {
      final dio = Dio(
        BaseOptions(baseUrl: ApiConfig.baseUrl, validateStatus: (_) => true),
      )..httpClientAdapter = stub;
      var expired = 0;
      dio.interceptors.addAll([
        AuthInterceptor(token: () => 'old'),
        StatusInterceptor(
          bangla: () => false,
          refresh: refresh,
          replay: dio.fetch,
          onSessionExpired: () => expired++,
        ),
      ]);
      return dio;
    }

    test('a 401 renews the token once and replays the request', () async {
      final stub = ApiStub()
        ..on(
          'GET',
          'leads',
          (RequestOptions r) => r.headers['Authorization'] == 'Bearer new'
              ? {'items': <Object>[], 'total': 0}
              : const StubReply(401),
        );
      var refreshes = 0;
      final dio = refreshingDio(stub, () async {
        refreshes++;
        return 'new';
      });

      final response = await dio.get<dynamic>('leads');
      expect(response.statusCode, 200);
      expect(refreshes, 1);
      expect(stub.requests, hasLength(2));
    });

    test('a failed refresh rejects with the 401', () async {
      final stub = ApiStub()..fail('GET', 'leads', 401, message: 'Sign in');
      final dio = refreshingDio(stub, () async => null);

      await expectLater(
        dio.get<dynamic>('leads'),
        throwsA(
          isA<DioException>().having(
            (e) => (e.error as ApiFailure?)?.statusCode,
            'status',
            401,
          ),
        ),
      );
    });
  });

  group('stored session', () {
    test('one without real tokens is dropped with its PIN', () async {
      FlutterSecureStorage.setMockInitialValues({
        'session': jsonEncode({'Token': 'fake.1', 'UserId': 1}),
        'pin_hash': 'old',
      });
      const store = SessionStore(FlutterSecureStorage());

      expect(await store.read(), isNull);
      expect(await store.hasPin(), isFalse);
    });
  });

  group('workspace', () {
    test('the current workspace is the one the token is scoped to', () async {
      final stub = ApiStub();
      final container = await apiContainer(stub);

      final list = await container.read(workspacesProvider.future);
      final current = container.read(currentWorkspaceProvider);
      expect(list, isNotEmpty);
      expect(current?.id, list.first.id);
      expect(current?.role, WorkspaceRole.owner);
    });

    test('switching re-issues the session for the other workspace', () async {
      final stub = ApiStub();
      final tokens = fixtureMap('auth_tokens');
      final me = tokens['me'] as Map<String, dynamic>;
      stub.on('POST', 'auth/workspace/{id}', {
        ...tokens,
        'accessToken': 'switched',
        'me': {...me, 'workspaceId': 'other'},
      });
      final container = await apiContainer(stub);
      await container.read(sessionProvider.future);

      await container.read(sessionProvider.notifier).switchWorkspace('other');

      final session = container.read(sessionProvider).value;
      expect(session?.token, 'switched');
      expect(session?.workspaceId, 'other');
    });
  });

  group('access', () {
    test('an executive cannot approve; an owner can', () async {
      final member = await apiContainer(
        ApiStub(),
        me: meWith(role: 'executive', level: 'standard'),
      );
      await member.read(permissionsProvider.future);
      expect(
        member.read(moduleAccessProvider(AppModule.quotation)).canApprove,
        isFalse,
      );

      final owner = await apiContainer(ApiStub());
      await owner.read(permissionsProvider.future);
      expect(
        owner.read(moduleAccessProvider(AppModule.quotation)).canApprove,
        isTrue,
      );
    });

    test('field force needs the fieldforce layer', () async {
      final container = await apiContainer(
        ApiStub(),
        me: meWith(layers: ['sales']),
      );
      await container.read(permissionsProvider.future);
      final access = container.read(moduleAccessProvider(AppModule.visit));
      expect(access.canView, isFalse);
      expect(access.lockedByPlan, isTrue);
    });

    test('a locked level wins over the stored one', () async {
      final container = await apiContainer(
        ApiStub(),
        me: meWith(level: 'easy', levelLocked: true),
      );
      await container.read(workspacesProvider.future);
      expect(container.read(experienceLevelProvider), ExperienceLevel.easy);
      expect(container.read(experienceLevelLockedProvider), isTrue);
    });

    test('the plan comes from billing usage', () async {
      final container = await apiContainer(ApiStub());
      await container.read(workspacesProvider.future);
      final plan = await container.read(planProvider.future);
      expect(plan?.code, 'business');
      expect(plan?.users, 25);
      expect(plan?.has(AddOn.fieldForce), isTrue);
    });
  });
}
