import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/workspace/workspace.dart';

part 'dev_settings.g.dart';

/// Debug-only switches that drive the fake backend into every state a screen
/// has to handle.
class DevSettings {
  const DevSettings({
    this.latency = true,
    this.offline = false,
    this.injectErrors = false,
    this.quotaReached = false,
    this.lockLevel = false,
    this.emptyWorkspace = false,
    this.role,
    this.addOns,
    this.seed = 0,
  });

  final bool latency;
  final bool offline;
  final bool injectErrors;
  final bool quotaReached;

  /// Behaves as if the owner fixed everyone's experience level.
  final bool lockLevel;
  final bool emptyWorkspace;

  /// Overrides the role the current workspace gives the user.
  final WorkspaceRole? role;

  /// Overrides the add-ons the current plan includes.
  final Set<AddOn>? addOns;

  /// Bumped to reseed the fake data.
  final int seed;

  DevSettings copyWith({
    bool? latency,
    bool? offline,
    bool? injectErrors,
    bool? quotaReached,
    bool? lockLevel,
    bool? emptyWorkspace,
    WorkspaceRole? Function()? role,
    Set<AddOn>? Function()? addOns,
    int? seed,
  }) => DevSettings(
    latency: latency ?? this.latency,
    offline: offline ?? this.offline,
    injectErrors: injectErrors ?? this.injectErrors,
    quotaReached: quotaReached ?? this.quotaReached,
    lockLevel: lockLevel ?? this.lockLevel,
    emptyWorkspace: emptyWorkspace ?? this.emptyWorkspace,
    role: role != null ? role() : this.role,
    addOns: addOns != null ? addOns() : this.addOns,
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
