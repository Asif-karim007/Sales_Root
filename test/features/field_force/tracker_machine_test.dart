import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/field_force/models/tracker_config.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';

void main() {
  group('TrackerMachine', () {
    test('walks hidden → available → consented → ready → active', () {
      var machine = const TrackerMachine();
      expect(machine.state, TrackerState.hidden);
      machine = machine.on(TrackerEvent.enabled);
      expect(machine.state, TrackerState.available);
      machine = machine.on(TrackerEvent.consentGiven);
      expect(machine.state, TrackerState.consented);
      machine = machine.on(TrackerEvent.permissionsGranted);
      expect(machine.state, TrackerState.ready);
      machine = machine.on(TrackerEvent.started);
      expect(machine.state, TrackerState.active);
      machine = machine.on(TrackerEvent.stopped);
      expect(machine.state, TrackerState.ready);
    });

    test('cannot start before consent and permissions', () {
      final available = const TrackerMachine(enabled: true);
      expect(available.on(TrackerEvent.started).state, TrackerState.available);
      final consented = available.on(TrackerEvent.consentGiven);
      expect(consented.on(TrackerEvent.started).running, isFalse);
    });

    test('losing a permission while active stops tracking', () {
      final active = const TrackerMachine(
        enabled: true,
        consented: true,
        permissionsOk: true,
        running: true,
      );
      final lost = active.on(TrackerEvent.permissionsLost);
      expect(lost.state, TrackerState.consented);
      expect(lost.running, isFalse);
      expect(
        lost.on(TrackerEvent.permissionsGranted).state,
        TrackerState.ready,
      );
    });

    test('withdrawing consent or disabling falls all the way back', () {
      final active = const TrackerMachine(
        enabled: true,
        consented: true,
        permissionsOk: true,
        running: true,
      );
      expect(
        active.on(TrackerEvent.consentWithdrawn).state,
        TrackerState.available,
      );
      final disabled = active.on(TrackerEvent.disabled);
      expect(disabled.state, TrackerState.hidden);
      expect(disabled.on(TrackerEvent.enabled).state, TrackerState.ready);
    });
  });

  group('TrackerConfig window', () {
    const config = TrackerConfig(
      isEnabled: true,
      startTime: '09:00',
      endTime: '18:00',
      workDays: [6, 7, 1, 2, 3, 4],
    );

    test('captures inside duty hours on a work day', () {
      expect(config.isInsideWindow(DateTime(2026, 10, 1, 9, 0)), isTrue);
      expect(config.isInsideWindow(DateTime(2026, 10, 1, 18, 0)), isTrue);
    });

    test('stays quiet outside hours and on Friday', () {
      expect(config.isInsideWindow(DateTime(2026, 10, 1, 8, 59)), isFalse);
      expect(config.isInsideWindow(DateTime(2026, 10, 1, 18, 1)), isFalse);
      expect(config.isInsideWindow(DateTime(2026, 10, 2, 12, 0)), isFalse);
    });

    test('round-trips through its stored JSON', () {
      final copy = TrackerConfig.fromJson(config.toJson());
      expect(copy.sameSchedule(config), isTrue);
      expect(copy.interval, const Duration(minutes: 5));
    });
  });
}
