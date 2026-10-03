import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:salesroot/features/field_force/service/oem_helper.dart';

/// The permission steps, in the order the wizard asks for them.
enum TrackerPermissionStep { notifications, location, gps, precise, battery }

/// Only [blocked] rows keep tracking from starting; [pending] rows are
/// recommendations, or no first-time user would ever reach READY.
enum PermissionLevel { granted, pending, blocked, notApplicable }

/// How far the location permission goes.
enum LocationGrant { always, whileUsing, denied, deniedForever }

class TrackerPermissionRow {
  const TrackerPermissionRow({
    required this.step,
    required this.level,
    this.location,
  });

  final TrackerPermissionStep step;
  final PermissionLevel level;

  /// Set on the [TrackerPermissionStep.location] row.
  final LocationGrant? location;

  bool get isBlocking => level == PermissionLevel.blocked;
  bool get isGreen =>
      level == PermissionLevel.granted ||
      level == PermissionLevel.notApplicable;
}

/// Reads and requests what background tracking needs on this phone.
class TrackerPermissions {
  const TrackerPermissions();

  Future<List<TrackerPermissionRow>> checklist() async => [
    await _notifications(),
    await _location(),
    await _gps(),
    await _precise(),
    await _battery(),
  ];

  Future<TrackerPermissionRow> _notifications() async {
    if (!Platform.isAndroid) {
      return const TrackerPermissionRow(
        step: TrackerPermissionStep.notifications,
        level: PermissionLevel.notApplicable,
      );
    }
    final granted =
        await FlutterForegroundTask.checkNotificationPermission() ==
        NotificationPermission.granted;
    return TrackerPermissionRow(
      step: TrackerPermissionStep.notifications,
      level: granted ? PermissionLevel.granted : PermissionLevel.blocked,
    );
  }

  Future<LocationGrant> locationGrant() async {
    final whenInUse = await Permission.locationWhenInUse.status;
    if (whenInUse.isPermanentlyDenied) return LocationGrant.deniedForever;
    if (!whenInUse.isGranted && !whenInUse.isLimited) {
      return LocationGrant.denied;
    }
    final always = await Permission.locationAlways.status;
    return always.isGranted ? LocationGrant.always : LocationGrant.whileUsing;
  }

  Future<TrackerPermissionRow> _location() async {
    final grant = await locationGrant();
    return TrackerPermissionRow(
      step: TrackerPermissionStep.location,
      location: grant,
      level: switch (grant) {
        LocationGrant.always => PermissionLevel.granted,
        LocationGrant.whileUsing => PermissionLevel.pending,
        LocationGrant.denied ||
        LocationGrant.deniedForever => PermissionLevel.blocked,
      },
    );
  }

  Future<TrackerPermissionRow> _gps() async => TrackerPermissionRow(
    step: TrackerPermissionStep.gps,
    level: await Geolocator.isLocationServiceEnabled()
        ? PermissionLevel.granted
        : PermissionLevel.blocked,
  );

  Future<TrackerPermissionRow> _precise() async {
    if (!Platform.isIOS) {
      return const TrackerPermissionRow(
        step: TrackerPermissionStep.precise,
        level: PermissionLevel.notApplicable,
      );
    }
    final accuracy = await Geolocator.getLocationAccuracy();
    return TrackerPermissionRow(
      step: TrackerPermissionStep.precise,
      level: accuracy == LocationAccuracyStatus.precise
          ? PermissionLevel.granted
          : PermissionLevel.pending,
    );
  }

  Future<TrackerPermissionRow> _battery() async {
    if (!Platform.isAndroid) {
      return const TrackerPermissionRow(
        step: TrackerPermissionStep.battery,
        level: PermissionLevel.notApplicable,
      );
    }
    final unrestricted =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    return TrackerPermissionRow(
      step: TrackerPermissionStep.battery,
      level: unrestricted ? PermissionLevel.granted : PermissionLevel.pending,
    );
  }

  /// Asks for [step], or opens the settings screen where it is fixed.
  Future<void> request(TrackerPermissionStep step) async {
    switch (step) {
      case TrackerPermissionStep.notifications:
        await FlutterForegroundTask.requestNotificationPermission();
      case TrackerPermissionStep.location:
        await _requestLocation();
      case TrackerPermissionStep.gps:
        await Geolocator.openLocationSettings();
      case TrackerPermissionStep.precise || TrackerPermissionStep.battery:
        await openAppSettings();
    }
  }

  Future<void> _requestLocation() async {
    final grant = await locationGrant();
    switch (grant) {
      case LocationGrant.deniedForever:
        await openAppSettings();
      case LocationGrant.denied:
        final status = await Permission.locationWhenInUse.request();
        if (status.isGranted) await Permission.locationAlways.request();
      case LocationGrant.whileUsing:
        final always = await Permission.locationAlways.request();
        if (!always.isGranted) await openAppSettings();
      case LocationGrant.always:
        break;
    }
  }

  /// The wizard after consent: the two system prompts, in order. Settings
  /// screens are left to the help screen's Fix buttons.
  Future<void> requestPrompts() async {
    for (final row in await checklist()) {
      if (row.isGreen) continue;
      if (row.step == TrackerPermissionStep.notifications ||
          row.step == TrackerPermissionStep.location) {
        await request(row.step);
      }
    }
  }

  Future<PhoneInfo> phone() => const OemHelper().phone();
}
