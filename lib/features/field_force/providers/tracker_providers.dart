import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/debug_log.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/field_force/data/tracker_prefs.dart';
import 'package:salesroot/features/field_force/models/tracker_config.dart';
import 'package:salesroot/features/field_force/models/tracker_ping.dart';
import 'package:salesroot/features/field_force/providers/tracking_providers.dart';
import 'package:salesroot/features/field_force/service/oem_helper.dart';
import 'package:salesroot/features/field_force/service/tracker_engine.dart';
import 'package:salesroot/features/field_force/service/tracker_machine.dart';
import 'package:salesroot/features/field_force/service/tracker_messages.dart';
import 'package:salesroot/features/field_force/service/tracker_permissions.dart';
import 'package:salesroot/features/field_force/service/tracker_runner.dart';
import 'package:salesroot/features/field_force/service/tracker_task_handler.dart';
import 'package:salesroot/translations/translations.dart';

part 'tracker_providers.g.dart';

class TrackerStatus {
  const TrackerStatus({
    this.state = TrackerState.hidden,
    this.config = TrackerConfig.disabled,
    this.checklist = const [],
    this.buffered = 0,
    this.insideWindow = false,
    this.moving = false,
    this.gpsOn = false,
    this.busy = false,
    this.lastUploadAt,
    this.lastCaptureAt,
    this.stoppedAt,
    this.pausedAt,
  });

  final TrackerState state;
  final TrackerConfig config;
  final List<TrackerPermissionRow> checklist;

  /// Pings captured but not uploaded yet.
  final int buffered;
  final bool insideWindow;
  final bool moving;
  final bool gpsOn;
  final bool busy;
  final DateTime? lastUploadAt;
  final DateTime? lastCaptureAt;

  /// When tracking stopped without the member stopping it.
  final DateTime? stoppedAt;

  /// When the member paused sharing, while the pause lasts.
  final DateTime? pausedAt;

  bool get isActive => state == TrackerState.active;

  TrackerStatus copyWith({
    TrackerState? state,
    int? buffered,
    bool? insideWindow,
    bool? moving,
    bool? gpsOn,
    bool? busy,
    DateTime? lastUploadAt,
    DateTime? lastCaptureAt,
  }) => TrackerStatus(
    state: state ?? this.state,
    config: config,
    checklist: checklist,
    buffered: buffered ?? this.buffered,
    insideWindow: insideWindow ?? this.insideWindow,
    moving: moving ?? this.moving,
    gpsOn: gpsOn ?? this.gpsOn,
    busy: busy ?? this.busy,
    lastUploadAt: lastUploadAt ?? this.lastUploadAt,
    lastCaptureAt: lastCaptureAt ?? this.lastCaptureAt,
    stoppedAt: stoppedAt,
    pausedAt: pausedAt,
  );
}

/// Live tracking for the signed-in member: the state machine, the
/// foreground service on Android, the in-app runner on iOS, and the flush of
/// buffered pings to the tracking repository.
@Riverpod(keepAlive: true)
class TrackerNotifier extends _$TrackerNotifier {
  static const _permissions = TrackerPermissions();

  @override
  Future<TrackerStatus> build() async {
    ref.watch(currentWorkspaceProvider.select((w) => w?.id));
    if (Platform.isAndroid) {
      FlutterForegroundTask.initCommunicationPort();
      FlutterForegroundTask.addTaskDataCallback(_onServiceData);
      ref.onDispose(
        () => FlutterForegroundTask.removeTaskDataCallback(_onServiceData),
      );
    }
    final lifecycle = AppLifecycleListener(
      onResume: () => unawaited(refresh()),
    );
    ref.onDispose(lifecycle.dispose);
    final connectivity = Connectivity().onConnectivityChanged.listen((result) {
      if (result.any((r) => r != ConnectivityResult.none)) {
        unawaited(flushNow());
      }
    }, onError: (Object error) => logDebug('Tracker: connectivity $error'));
    ref.onDispose(connectivity.cancel);

    final status = await _evaluate();
    if (status.state == TrackerState.ready &&
        await TrackerPrefs.wasActive() &&
        status.pausedAt == null) {
      unawaited(Future.microtask(start));
    }
    unawaited(Future.microtask(flushNow));
    return status;
  }

  Future<TrackerStatus> _evaluate() async {
    final repository = ref.read(trackingRepositoryProvider);
    var config = await TrackerPrefs.config();
    var consented = await TrackerPrefs.consentAt() != null;
    try {
      config = await repository.trackerConfig();
      await TrackerPrefs.setConfig(config);
      final consent = await repository.consent();
      consented = consent.given;
      await TrackerPrefs.setConsentAt(
        consent.given ? consent.at ?? DateTime.now() : null,
      );
    } on ApiFailure catch (failure) {
      logDebug('Tracker: kept cached config (${failure.statusCode})');
    }
    final checklist = await _permissions.checklist();
    final running = await _Runtime.isRunning();
    final machine = TrackerMachine(
      enabled: config.isEnabled,
      consented: consented,
      permissionsOk: checklist.every((row) => !row.isBlocking),
      running: running,
    );
    if (running && machine.state != TrackerState.active) {
      await _Runtime.stop();
    }
    if (!running && await TrackerPrefs.wasActive()) {
      await TrackerPrefs.setStoppedAt(
        await TrackerPrefs.stoppedAt() ??
            await TrackerPrefs.lastCaptureAt() ??
            DateTime.now(),
      );
    }
    await TrackerPrefs.setState(machine.state);
    if (Platform.isAndroid && machine.state == TrackerState.active) {
      FlutterForegroundTask.sendDataToTask(
        TrackerCommands.newConfig(config.toJson()),
      );
    }
    final now = DateTime.now();
    return TrackerStatus(
      state: machine.state,
      config: config,
      checklist: checklist,
      buffered: await TrackerPrefs.bufferedCount(),
      insideWindow: config.isInsideWindow(now),
      gpsOn: _Runtime.ios?.gpsOn ?? false,
      lastUploadAt: await TrackerPrefs.lastUploadAt(),
      lastCaptureAt: await TrackerPrefs.lastCaptureAt(),
      stoppedAt: await TrackerPrefs.stoppedAt(),
      pausedAt: await TrackerPrefs.pausedAt(),
    );
  }

  /// Re-reads config, consent and permissions, as on app resume.
  Future<void> refresh() async {
    final status = await _evaluate();
    if (!ref.mounted) return;
    state = AsyncData(status);
    if (Platform.isAndroid && status.isActive) {
      FlutterForegroundTask.sendDataToTask(TrackerCommands.status());
    }
  }

  /// "I agree": records consent, then asks for the system permissions.
  Future<void> giveConsent() async {
    await ref.read(trackingRepositoryProvider).setConsent(given: true);
    await TrackerPrefs.setConsentAt(DateTime.now());
    ref.invalidate(trackingConsentProvider);
    await _permissions.requestPrompts();
    await refresh();
  }

  Future<void> declineConsent() async {
    await stop();
    await ref.read(trackingRepositoryProvider).setConsent(given: false);
    await TrackerPrefs.setConsentAt(null);
    ref.invalidate(trackingConsentProvider);
    await refresh();
  }

  Future<void> requestPermission(TrackerPermissionStep step) async {
    await _permissions.request(step);
    await refresh();
  }

  /// Starts sharing if the state machine allows it; false otherwise.
  Future<bool> start() async {
    final current = await future;
    if (!ref.mounted || !current.state.canToggle || current.busy) return false;
    if (current.isActive) return true;
    state = AsyncData(current.copyWith(busy: true));
    final l10n = lookupAppLocalizations(ref.read(appLocaleProvider));
    final started = await _Runtime.start(
      config: current.config,
      uploader: RepositoryPingUploader(ref.read(trackingRepositoryProvider)),
      title: l10n.ffTrackerNotificationTitle,
      body: l10n.ffTrackerNotificationBody(current.config.windowLabel ?? ''),
      channel: l10n.ffTrackerChannel,
      onChanged: () => unawaited(_syncCounts()),
    );
    await TrackerPrefs.setWasActive(started);
    if (started) await TrackerPrefs.setStoppedAt(null);
    await refresh();
    return started;
  }

  Future<void> stop() async {
    await _Runtime.stop();
    await TrackerPrefs.setWasActive(false);
    await TrackerPrefs.setStoppedAt(null);
    await flushNow();
    await refresh();
  }

  /// Stops sharing until [resume]; the pause is logged for the team lead.
  Future<void> pause() async {
    await _Runtime.stop();
    await TrackerPrefs.setWasActive(false);
    await TrackerPrefs.setPausedAt(DateTime.now());
    await refresh();
  }

  Future<void> resume() async {
    final pausedAt = await TrackerPrefs.pausedAt();
    await TrackerPrefs.setPausedAt(null);
    if (pausedAt != null) {
      await ref
          .read(trackingRepositoryProvider)
          .logPause(pausedAt, DateTime.now());
    }
    await refresh();
    await start();
  }

  Future<void> flushNow() async {
    if (Platform.isAndroid && await _Runtime.isRunning()) {
      FlutterForegroundTask.sendDataToTask(TrackerCommands.flush());
      return;
    }
    final engine = TrackerEngine(
      uploader: RepositoryPingUploader(ref.read(trackingRepositoryProvider)),
      config: await TrackerPrefs.config(),
    );
    await engine.flush(force: true);
    await _syncCounts();
  }

  Future<void> _syncCounts() async {
    final current = state.value;
    if (current == null || !ref.mounted) return;
    state = AsyncData(
      current.copyWith(
        buffered: await TrackerPrefs.bufferedCount(),
        lastUploadAt: await TrackerPrefs.lastUploadAt(),
        lastCaptureAt: await TrackerPrefs.lastCaptureAt(),
        gpsOn: _Runtime.ios?.gpsOn,
      ),
    );
  }

  void _onServiceData(Object data) {
    if (data is! Map) return;
    switch (data['type']) {
      case TrackerMessages.status:
        final current = state.value;
        if (current == null) return;
        state = AsyncData(
          current.copyWith(
            buffered: data.intOr('buffered', current.buffered),
            insideWindow: data.boolOr('insideWindow', current.insideWindow),
            moving: data.boolOr('moving', current.moving),
            gpsOn: data.boolOr('gpsOn', current.gpsOn),
            lastCaptureAt: data.timeOrNull('lastCaptureAt'),
            lastUploadAt: data.timeOrNull('lastUploadAt'),
          ),
        );
      case TrackerMessages.upload:
        unawaited(_relayUpload(data));
      case TrackerMessages.stopped:
        unawaited(refresh());
    }
  }

  /// Delivers a batch the service sent over, then tells it how that went.
  Future<void> _relayUpload(Map<Object?, Object?> data) async {
    final requestId = data.intOr('requestId', -1);
    final raw = data['pings'];
    final pings = [
      if (raw is List)
        for (final row in raw)
          if (row is Map) TrackerPing.fromDb(Map<String, Object?>.from(row)),
    ];
    final result = await RepositoryPingUploader(
      ref.read(trackingRepositoryProvider),
    ).upload(pings);
    FlutterForegroundTask.sendDataToTask(
      TrackerCommands.ack(
        requestId,
        delivered: result != null,
        rejected: result?.rejected ?? 0,
      ),
    );
  }
}

/// This phone's maker and model, for the battery tips.
@riverpod
Future<PhoneInfo> phoneInfo(Ref ref) => const OemHelper().phone();

/// The running capture loop, outside the notifier so a rebuild never loses
/// it: the Android service, or the iOS runner in this isolate.
abstract final class _Runtime {
  static IosTrackerRunner? ios;
  static bool _initialised = false;

  static Future<bool> isRunning() async {
    if (Platform.isAndroid) return FlutterForegroundTask.isRunningService;
    return ios?.isRunning ?? false;
  }

  static Future<bool> start({
    required TrackerConfig config,
    required PingUploader uploader,
    required String title,
    required String body,
    required String channel,
    required VoidCallback onChanged,
  }) async {
    await TrackerPrefs.setConfig(config);
    if (Platform.isAndroid) {
      _init(channel);
      final result = await FlutterForegroundTask.startService(
        serviceTypes: const [ForegroundServiceTypes.location],
        notificationTitle: title,
        notificationText: body,
        callback: startTrackerCallback,
      );
      return result is ServiceRequestSuccess;
    }
    final engine = TrackerEngine(uploader: uploader, config: config);
    final runner = ios ??= IosTrackerRunner(
      engine: engine,
      onChanged: onChanged,
    );
    runner.engine = engine;
    await runner.start();
    return true;
  }

  static Future<void> stop() async {
    if (Platform.isAndroid) {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
      return;
    }
    await ios?.stop();
  }

  static void _init(String channel) {
    if (_initialised) return;
    _initialised = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'salesroot_tracker',
        channelName: channel,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          TrackerTaskHandler.tickInterval.inMilliseconds,
        ),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
}
