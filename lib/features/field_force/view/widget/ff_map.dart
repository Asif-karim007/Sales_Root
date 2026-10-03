import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:salesroot/core/theme/sr_colors.dart';

enum FfPinTone { accent, muted, warn, danger, me }

class FfMapPin {
  const FfMapPin({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.title,
    this.subtitle,
    this.tone = FfPinTone.accent,
    this.onTap,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String? title;
  final String? subtitle;
  final FfPinTone tone;
  final VoidCallback? onTap;
}

/// A circle drawn around a point, such as the check-in radius.
class FfMapRing {
  const FfMapRing({
    required this.latitude,
    required this.longitude,
    required this.radiusMetres,
  });

  final double latitude;
  final double longitude;
  final double radiusMetres;
}

/// The prototype's `.mapbox`: a Google map in a rounded, outlined box that
/// fits every pin, line and ring it is given.
class FfMap extends StatefulWidget {
  const FfMap({
    super.key,
    required this.height,
    this.pins = const [],
    this.lines = const [],
    this.ring,
  });

  /// Dhaka, when there is nothing to fit.
  static const _dhaka = LatLng(23.7806, 90.4078);

  final double height;
  final List<FfMapPin> pins;

  /// Each line is a list of (latitude, longitude) points.
  final List<List<(double, double)>> lines;
  final FfMapRing? ring;

  @override
  State<FfMap> createState() => _FfMapState();
}

class _FfMapState extends State<FfMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(FfMap old) {
    super.didUpdateWidget(old);
    final ringMoved =
        old.ring?.latitude != widget.ring?.latitude ||
        old.ring?.longitude != widget.ring?.longitude;
    if (old.pins.length != widget.pins.length ||
        old.lines.length != widget.lines.length ||
        ringMoved) {
      _fit();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  List<LatLng> get _points => [
    for (final pin in widget.pins) LatLng(pin.latitude, pin.longitude),
    for (final line in widget.lines)
      for (final (lat, lng) in line) LatLng(lat, lng),
    if (widget.ring case final ring?) ..._ringBox(ring),
  ];

  List<LatLng> _ringBox(FfMapRing ring) {
    final dLat = ring.radiusMetres / 111320;
    final dLng =
        ring.radiusMetres / (111320 * math.cos(ring.latitude * math.pi / 180));
    return [
      LatLng(ring.latitude - dLat, ring.longitude - dLng),
      LatLng(ring.latitude + dLat, ring.longitude + dLng),
    ];
  }

  Future<void> _fit() async {
    final controller = _controller;
    final points = _points;
    if (controller == null || points.isEmpty) return;
    if (points.length == 1) {
      await controller.moveCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    if (north - south < 0.002 && east - west < 0.002) {
      await controller.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng((south + north) / 2, (west + east) / 2),
          16,
        ),
      );
      return;
    }
    await controller.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        40,
      ),
    );
  }

  double _hue(Color color) => HSVColor.fromColor(color).hue;

  double _toneHue(SrColors c, FfPinTone tone) => switch (tone) {
    FfPinTone.accent => _hue(c.accent),
    FfPinTone.muted => _hue(c.ink3),
    FfPinTone.warn => _hue(c.warning),
    FfPinTone.danger => _hue(c.danger),
    FfPinTone.me => _hue(c.info),
  };

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ring = widget.ring;
    final first = _points.firstOrNull ?? FfMap._dhaka;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
        border: Border.all(color: c.line),
        color: c.track,
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: first, zoom: 12),
        onMapCreated: (controller) {
          _controller = controller;
          Future<void>.delayed(const Duration(milliseconds: 300), _fit);
        },
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        gestureRecognizers: const {
          Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
        },
        markers: {
          for (final pin in widget.pins)
            Marker(
              markerId: MarkerId(pin.id),
              position: LatLng(pin.latitude, pin.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _toneHue(c, pin.tone),
              ),
              infoWindow: pin.title == null
                  ? InfoWindow.noText
                  : InfoWindow(
                      title: pin.title,
                      snippet: pin.subtitle,
                      onTap: pin.onTap,
                    ),
            ),
        },
        polylines: {
          for (var i = 0; i < widget.lines.length; i++)
            Polyline(
              polylineId: PolylineId('line$i'),
              color: c.accent,
              width: 4,
              points: [
                for (final (lat, lng) in widget.lines[i]) LatLng(lat, lng),
              ],
            ),
        },
        circles: {
          if (ring != null)
            Circle(
              circleId: const CircleId('ring'),
              center: LatLng(ring.latitude, ring.longitude),
              radius: ring.radiusMetres,
              strokeWidth: 1,
              strokeColor: c.accent,
              fillColor: c.accent.withValues(alpha: 0.12),
            ),
        },
      ),
    );
  }
}
