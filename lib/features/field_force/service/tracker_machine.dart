/// Where live tracking stands for this member.
///
/// hidden → (enabled) available → (consent) consented → (permissions)
/// ready ⇄ (start/stop) active. Disabling, withdrawing consent or losing a
/// blocking permission falls back down the chain.
enum TrackerState {
  hidden,
  available,
  consented,
  ready,
  active;

  static TrackerState fromWire(String? value) => values.firstWhere(
    (state) => state.name == value,
    orElse: () => TrackerState.hidden,
  );

  bool get canToggle => this == ready || this == active;
}

enum TrackerEvent {
  enabled,
  disabled,
  consentGiven,
  consentWithdrawn,
  permissionsGranted,
  permissionsLost,
  started,
  stopped,
}

/// The facts the state is derived from. Every event changes one fact, and
/// the state always follows from all of them, so no sequence of events can
/// leave tracking running without consent or permissions.
class TrackerMachine {
  const TrackerMachine({
    this.enabled = false,
    this.consented = false,
    this.permissionsOk = false,
    this.running = false,
  });

  final bool enabled;
  final bool consented;
  final bool permissionsOk;
  final bool running;

  TrackerState get state {
    if (!enabled) return TrackerState.hidden;
    if (!consented) return TrackerState.available;
    if (!permissionsOk) return TrackerState.consented;
    return running ? TrackerState.active : TrackerState.ready;
  }

  TrackerMachine on(TrackerEvent event) => switch (event) {
    TrackerEvent.enabled => _copy(enabled: true),
    TrackerEvent.disabled => _copy(enabled: false, running: false),
    TrackerEvent.consentGiven => _copy(consented: true),
    TrackerEvent.consentWithdrawn => _copy(consented: false, running: false),
    TrackerEvent.permissionsGranted => _copy(permissionsOk: true),
    TrackerEvent.permissionsLost => _copy(permissionsOk: false, running: false),
    TrackerEvent.started => _copy(running: state.canToggle),
    TrackerEvent.stopped => _copy(running: false),
  };

  TrackerMachine _copy({
    bool? enabled,
    bool? consented,
    bool? permissionsOk,
    bool? running,
  }) => TrackerMachine(
    enabled: enabled ?? this.enabled,
    consented: consented ?? this.consented,
    permissionsOk: permissionsOk ?? this.permissionsOk,
    running: running ?? this.running,
  );
}
