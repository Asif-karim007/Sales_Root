import 'dart:math' as math;

import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/service/geo.dart';

/// A run of points that stayed inside [DayAnalytics.stopRadiusMetres] of each
/// other for at least [DayAnalytics.stopMinMinutes].
class DayStop {
  const DayStop({
    required this.start,
    required this.end,
    required this.latitude,
    required this.longitude,
  });

  final DateTime start;
  final DateTime end;
  final double latitude;
  final double longitude;

  int get minutes => end.difference(start).inMinutes;
}

/// A stretch of real travel between two stops.
class DayTrip {
  const DayTrip({required this.start, required this.end, required this.metres});

  final DateTime start;
  final DateTime end;
  final double metres;

  int get minutes => math.max(1, end.difference(start).inMinutes);
  double get km => metres / 1000;
}

/// What a member's day looked like, worked out on the device from the trail
/// points alone: the server has no notion of a trip, a stop or coverage.
class DayAnalytics {
  const DayAnalytics({
    required this.metres,
    required this.movingMinutes,
    required this.parkedMinutes,
    required this.stops,
    required this.trips,
    required this.routePoints,
    required this.lastBattery,
  });

  /// Below this a "move" between two points is GPS noise, not travel.
  static const double jitterMetres = 15;

  static const double stopRadiusMetres = 40;
  static const int stopMinMinutes = 20;

  /// Movement shorter than this is noise, not a trip worth listing.
  static const double minTripMetres = 200;

  /// How far the simplified line may stray from the recorded points.
  static const double simplifyToleranceMetres = 12;

  final double metres;
  final int movingMinutes;
  final int parkedMinutes;
  final List<DayStop> stops;
  final List<DayTrip> trips;

  /// The day's points reduced to a line worth drawing.
  final List<TrailPoint> routePoints;
  final int? lastBattery;

  static const empty = DayAnalytics(
    metres: 0,
    movingMinutes: 0,
    parkedMinutes: 0,
    stops: [],
    trips: [],
    routePoints: [],
    lastBattery: null,
  );

  double get km => metres / 1000;

  factory DayAnalytics.from(List<TrailPoint> points) {
    final pts = [
      for (final p in points)
        if (p.time != null) p,
    ];
    if (pts.isEmpty) return empty;

    var metres = 0.0;
    var moving = 0;
    var parked = 0;
    final trips = <DayTrip>[];
    DayTrip? run;

    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final next = pts[i];
      final from = _timeOf(prev);
      final to = _timeOf(next);
      final d = _distance(prev, next);
      final dt = math.max(0, to.difference(from).inMinutes);
      final moved = d >= jitterMetres;
      if (moved) {
        metres += d;
        moving += dt;
        run = run == null
            ? DayTrip(start: from, end: to, metres: d)
            : DayTrip(start: run.start, end: to, metres: run.metres + d);
      } else {
        parked += dt;
        if (run != null && dt > 3) {
          trips.add(run);
          run = null;
        }
      }
    }
    if (run != null) trips.add(run);

    return DayAnalytics(
      metres: metres,
      movingMinutes: moving,
      parkedMinutes: parked,
      stops: _stops(pts),
      trips: [
        for (final trip in trips)
          if (trip.metres > minTripMetres) trip,
      ],
      routePoints: simplify(pts),
      lastBattery: pts.last.battery,
    );
  }

  static List<DayStop> _stops(List<TrailPoint> pts) {
    final stops = <DayStop>[];
    var anchor = 0;
    for (var i = 1; i <= pts.length; i++) {
      final broke =
          i == pts.length || _distance(pts[anchor], pts[i]) > stopRadiusMetres;
      if (!broke) continue;
      final start = _timeOf(pts[anchor]);
      final end = _timeOf(pts[i - 1]);
      if (end.difference(start).inMinutes >= stopMinMinutes) {
        stops.add(
          DayStop(
            start: start,
            end: end,
            latitude: pts[anchor].latitude,
            longitude: pts[anchor].longitude,
          ),
        );
      }
      anchor = i;
    }
    return stops;
  }

  /// Collapses parked scribble to one node per stop, then drops the points
  /// that carry no shape (Douglas–Peucker). The ends are always kept.
  static List<TrailPoint> simplify(
    List<TrailPoint> points, {
    double toleranceMetres = simplifyToleranceMetres,
  }) {
    if (points.length < 3) return List.of(points);
    final thinned = [points.first];
    for (var i = 1; i < points.length - 1; i++) {
      if (_distance(thinned.last, points[i]) >= jitterMetres) {
        thinned.add(points[i]);
      }
    }
    thinned.add(points.last);
    if (thinned.length < 3) return thinned;
    return _douglasPeucker(thinned, toleranceMetres);
  }

  static List<TrailPoint> _douglasPeucker(List<TrailPoint> pts, double eps) {
    if (pts.length < 3) return pts;
    var worst = 0;
    var worstDistance = 0.0;
    for (var i = 1; i < pts.length - 1; i++) {
      final d = _perpendicularMetres(pts[i], pts.first, pts.last);
      if (d > worstDistance) {
        worstDistance = d;
        worst = i;
      }
    }
    if (worstDistance <= eps) return [pts.first, pts.last];
    final left = _douglasPeucker(pts.sublist(0, worst + 1), eps);
    final right = _douglasPeucker(pts.sublist(worst), eps);
    return [...left.sublist(0, left.length - 1), ...right];
  }

  /// Distance from [p] to the segment [a]–[b] on a local flat projection,
  /// which is exact enough over a few hundred metres.
  static double _perpendicularMetres(TrailPoint p, TrailPoint a, TrailPoint b) {
    const metresPerDegree = 111320.0;
    final cosLat = math.cos(a.latitude * math.pi / 180);
    final px = p.longitude * metresPerDegree * cosLat;
    final py = p.latitude * metresPerDegree;
    final ax = a.longitude * metresPerDegree * cosLat;
    final ay = a.latitude * metresPerDegree;
    final bx = b.longitude * metresPerDegree * cosLat;
    final by = b.latitude * metresPerDegree;
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      return math.sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay));
    }
    final t = (((px - ax) * dx + (py - ay) * dy) / lengthSquared).clamp(
      0.0,
      1.0,
    );
    final cx = ax + t * dx;
    final cy = ay + t * dy;
    return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
  }

  static double _distance(TrailPoint a, TrailPoint b) =>
      distanceMetres(a.latitude, a.longitude, b.latitude, b.longitude);

  static DateTime _timeOf(TrailPoint point) => point.time ?? DateTime(2000);
}
