import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/network/dio_providers.dart';
import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/session/session_store.dart';
import 'package:salesroot/core/utils/json_fields.dart';

part 'session_provider.g.dart';

/// The signed-in user, or null. Restored from secure storage at start.
@Riverpod(keepAlive: true)
class SessionNotifier extends _$SessionNotifier {
  Future<String?>? _refreshing;

  @override
  Future<AuthSession?> build() => ref.watch(sessionStoreProvider).read();

  Future<void> signIn(AuthSession session) async {
    await ref.read(sessionStoreProvider).write(session);
    ref.read(pinLockProvider.notifier).unlock();
    state = AsyncData(session);
  }

  Future<void> replace(AuthSession session) async {
    await ref.read(sessionStoreProvider).write(session);
    state = AsyncData(session);
  }

  /// A new access token for the stored refresh token, or null when there is
  /// no session to renew. Concurrent callers share one request.
  Future<String?> refreshToken() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<String?> _refresh() async {
    final session = state.value;
    final refresh = session?.refreshToken;
    if (session == null || refresh == null) return null;
    final json = await apiRequest(
      'Token refresh',
      () => ref.read(bareSessionApiProvider).refresh({
        'refreshToken': refresh,
        'workspaceId': session.workspaceId,
      }),
    );
    if (!ref.mounted) return null;
    final next = AuthSession.fromTokens(jsonMap(json));
    await replace(next);
    return next.token;
  }

  /// Re-issues the session for [workspaceId]; every request after this is
  /// scoped to it.
  Future<void> switchWorkspace(String workspaceId) async {
    if (state.value?.workspaceId == workspaceId) return;
    final json = await apiRequest(
      'Workspace switch',
      () => ref.read(sessionApiProvider).switchWorkspace(workspaceId),
    );
    if (!ref.mounted) return;
    await replace(AuthSession.fromTokens(jsonMap(json)));
  }

  /// A request carrying the token was rejected: drop the session and tell
  /// the user why.
  Future<void> expire() async {
    if (state.value == null) return;
    ref.read(sessionExpiredProvider.notifier).raise();
    await _clear();
  }

  /// Ends the session on the server too, when it can be reached.
  Future<void> signOut() async {
    final session = state.value;
    final refresh = session?.refreshToken;
    await _clear();
    if (session == null || refresh == null) return;
    try {
      await apiRequest(
        'Sign out',
        () => ref.read(bareSessionApiProvider).logout(
          'Bearer ${session.token}',
          {'refreshToken': refresh, 'workspaceId': session.workspaceId},
        ),
      );
    } on ApiFailure {
      return;
    }
  }

  Future<void> _clear() async {
    await ref.read(sessionStoreProvider).clear();
    state = const AsyncData(null);
  }
}

/// True once per expiry, until the dialog explaining it has been shown.
@Riverpod(keepAlive: true)
class SessionExpiredNotifier extends _$SessionExpiredNotifier {
  @override
  bool build() => false;

  void raise() => state = true;

  void clear() => state = false;
}

/// The PIN screen sits in front of a restored session until it is unlocked.
@Riverpod(keepAlive: true)
class PinLockNotifier extends _$PinLockNotifier {
  @override
  Future<bool> build() async {
    final store = ref.read(sessionStoreProvider);
    final session = await store.read();
    return session != null && await store.hasPin();
  }

  void unlock() => state = const AsyncData(false);

  void lock() => state = const AsyncData(true);

  Future<bool> tryUnlock(String pin) async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return false;
    final ok = await ref
        .read(sessionStoreProvider)
        .checkPin(pin, session.userId);
    if (ok) unlock();
    return ok;
  }
}
