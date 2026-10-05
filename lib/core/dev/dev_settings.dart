import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dev_settings.g.dart';

/// Debug-only switches for the screens that still run on fake data (chat,
/// files, notices, distribution, academy, help articles, search, calendar).
class DevSettings {
  const DevSettings({
    this.latency = true,
    this.offline = false,
    this.injectErrors = false,
    this.quotaReached = false,
    this.emptyWorkspace = false,
    this.seed = 0,
  });

  final bool latency;
  final bool offline;
  final bool injectErrors;
  final bool quotaReached;

  final bool emptyWorkspace;

  /// Bumped to reseed the fake data.
  final int seed;

  DevSettings copyWith({
    bool? latency,
    bool? offline,
    bool? injectErrors,
    bool? quotaReached,
    bool? emptyWorkspace,
    int? seed,
  }) => DevSettings(
    latency: latency ?? this.latency,
    offline: offline ?? this.offline,
    injectErrors: injectErrors ?? this.injectErrors,
    quotaReached: quotaReached ?? this.quotaReached,
    emptyWorkspace: emptyWorkspace ?? this.emptyWorkspace,
    seed: seed ?? this.seed,
  );
}

@Riverpod(keepAlive: true)
class DevSettingsNotifier extends _$DevSettingsNotifier {
  @override
  DevSettings build() => const DevSettings();

  void update(DevSettings Function(DevSettings current) change) =>
      state = change(state);

  void reseed() => state = state.copyWith(seed: state.seed + 1);
}
