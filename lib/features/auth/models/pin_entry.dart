const pinLength = 4;

enum PinSetupError { weak, mismatch }

/// #4: the PIN typed once, then again to confirm.
class PinSetup {
  const PinSetup({
    this.entry = '',
    this.first,
    this.error,
    this.mistakes = 0,
    this.saving = false,
    this.saved = false,
  });

  final String entry;

  /// The first entry, once the user is confirming it.
  final String? first;
  final PinSetupError? error;

  /// Grows on every rejected entry, so the dots shake.
  final int mistakes;
  final bool saving;
  final bool saved;

  bool get confirming => first != null;
  bool get complete => entry.length == pinLength;

  /// Same digit four times, or a straight run like 1234 or 9876.
  static bool isWeak(String pin) {
    final digits = pin.codeUnits;
    final steps = {
      for (var i = 1; i < digits.length; i++) digits[i] - digits[i - 1],
    };
    return steps.length == 1 && steps.first.abs() <= 1;
  }
}

/// #11: the PIN typed on the lock screen and the wrong tries so far.
class PinUnlock {
  const PinUnlock({
    this.entry = '',
    this.attempts = 0,
    this.checking = false,
    this.lockedOut = false,
  });

  static const maxAttempts = 5;

  final String entry;
  final int attempts;
  final bool checking;

  /// Too many wrong tries: the session is being signed out.
  final bool lockedOut;

  int get triesLeft => maxAttempts - attempts;

  PinUnlock copyWith({
    String? entry,
    int? attempts,
    bool? checking,
    bool? lockedOut,
  }) => PinUnlock(
    entry: entry ?? this.entry,
    attempts: attempts ?? this.attempts,
    checking: checking ?? this.checking,
    lockedOut: lockedOut ?? this.lockedOut,
  );
}
