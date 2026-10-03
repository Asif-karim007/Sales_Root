import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/session/session_provider.dart';
import 'package:salesroot/core/session/session_store.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/features/auth/models/pin_entry.dart';
import 'package:salesroot/features/auth/providers/auth_providers.dart';

part 'pin_providers.g.dart';

@riverpod
class PinSetupNotifier extends _$PinSetupNotifier {
  @override
  PinSetup build() => const PinSetup();

  void digit(int value) {
    if (state.complete || state.saving) return;
    state = PinSetup(
      entry: '${state.entry}$value',
      first: state.first,
      mistakes: state.mistakes,
    );
  }

  void backspace() {
    final entry = state.entry;
    if (entry.isEmpty || state.saving) return;
    state = PinSetup(
      entry: entry.substring(0, entry.length - 1),
      first: state.first,
      error: state.error,
      mistakes: state.mistakes,
    );
  }

  /// First entry: rejects weak PINs. Second: must match, then the PIN is
  /// stored for the verified account.
  Future<void> submit() async {
    final entry = state.entry;
    if (!state.complete || state.saving) return;
    final first = state.first;
    if (first == null) {
      state = PinSetup.isWeak(entry)
          ? _rejected(PinSetupError.weak)
          : PinSetup(first: entry, mistakes: state.mistakes);
      return;
    }
    if (first != entry) {
      state = _rejected(PinSetupError.mismatch);
      return;
    }
    final session = ref.read(signUpFlowProvider).session;
    if (session == null) return;
    state = PinSetup(entry: entry, first: first, saving: true);
    await ref.read(sessionStoreProvider).writePin(entry, session.userId);
    if (!ref.mounted) return;
    state = PinSetup(entry: entry, first: first, saved: true);
  }

  PinSetup _rejected(PinSetupError error) =>
      PinSetup(error: error, mistakes: state.mistakes + 1);
}

/// The lock screen. Wrong tries survive a restart; after
/// [PinUnlock.maxAttempts] the session is signed out.
@riverpod
class PinUnlockNotifier extends _$PinUnlockNotifier {
  static const _attemptsKey = 'pin_attempts';

  @override
  PinUnlock build() => PinUnlock(
    attempts: ref.read(sharedPreferencesProvider).getInt(_attemptsKey) ?? 0,
  );

  void digit(int value) {
    if (state.checking || state.entry.length >= pinLength) return;
    state = state.copyWith(entry: '${state.entry}$value');
    if (state.entry.length == pinLength) submit();
  }

  void backspace() {
    final entry = state.entry;
    if (entry.isEmpty || state.checking) return;
    state = state.copyWith(entry: entry.substring(0, entry.length - 1));
  }

  Future<void> submit() async {
    if (state.entry.length < pinLength || state.checking) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final session = ref.read(sessionProvider.notifier);
    state = state.copyWith(checking: true);
    final ok = await ref.read(pinLockProvider.notifier).tryUnlock(state.entry);
    if (ok) {
      await prefs.remove(_attemptsKey);
      return;
    }
    if (!ref.mounted) return;
    final attempts = state.attempts + 1;
    if (attempts >= PinUnlock.maxAttempts) {
      await prefs.remove(_attemptsKey);
      if (!ref.mounted) return;
      state = state.copyWith(attempts: attempts, lockedOut: true);
      await session.signOut();
      return;
    }
    await prefs.setInt(_attemptsKey, attempts);
    if (!ref.mounted) return;
    state = PinUnlock(attempts: attempts);
  }

  /// Forgot PIN or another account: the user signs in again with a code.
  Future<void> signOut() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final session = ref.read(sessionProvider.notifier);
    await prefs.remove(_attemptsKey);
    await session.signOut();
  }
}
