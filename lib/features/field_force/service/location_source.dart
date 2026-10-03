import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:salesroot/core/utils/debug_log.dart';

class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.time,
    this.isMocked = false,
  });

  final double latitude;
  final double longitude;

  /// Metres, as the platform reports it.
  final double accuracy;
  final DateTime time;
  final bool isMocked;
}

enum LocationIssue { serviceOff, denied, deniedForever, unavailable }

class LocationFailure implements Exception {
  const LocationFailure(this.issue);

  final LocationIssue issue;

  @override
  String toString() => 'LocationFailure(${issue.name})';
}

/// The phone's position, behind an interface so tests can stand still.
abstract interface class LocationSource {
  /// Throws [LocationFailure] when there is no usable fix.
  Future<GeoFix> current();

  /// "Banani, Dhaka", or null when the phone can't name the place.
  Future<String?> placeName(double latitude, double longitude);
}

class DeviceLocationSource implements LocationSource {
  static const _fixTimeout = Duration(seconds: 20);

  @override
  Future<GeoFix> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(LocationIssue.serviceOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(LocationIssue.deniedForever);
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationFailure(LocationIssue.denied);
    }
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _fixTimeout,
        ),
      );
    } on TimeoutException {
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) {
      throw const LocationFailure(LocationIssue.unavailable);
    }
    return GeoFix(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      time: position.timestamp.toLocal(),
      isMocked: position.isMocked,
    );
  }

  @override
  Future<String?> placeName(double latitude, double longitude) async {
    try {
      final places = await Geocoding()
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 6));
      if (places.isEmpty) return null;
      final place = places.first;
      final parts = [
        for (final part in [place.subLocality, place.locality])
          if (part != null && part.isNotEmpty) part,
      ];
      return parts.isEmpty ? null : parts.join(', ');
    } on Exception catch (error) {
      logDebug('Reverse geocode failed: $error');
      return null;
    }
  }
}
