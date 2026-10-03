import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/session/auth_session.dart';
import 'package:salesroot/core/session/session_store.dart';

part 'session_provider.g.dart';

/// The signed-in user, or null. Restored from secure storage at start.
@Riverpod(keepAlive: true)
class SessionNotifier extends _$SessionNotifier {
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

  /// A request carrying the token was rejected: drop the session and tell
  /// the user why.
  Future<void> expire() async {
    if (state.value == null) return;
    ref.read(sessionExpiredProvider.notifier).raise();
    await signOut();
  }

  Future<void> signOut() async {
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
