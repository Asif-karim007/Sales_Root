import 'dart:math' as math;

/// Great-circle distance in metres.
double distanceMetres(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  const toRad = math.pi / 180;
  final dLat = (lat2 - lat1) * toRad;
  final dLng = (lng2 - lng1) * toRad;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * toRad) *
          math.cos(lat2 * toRad) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(a)));
}

/// A check-in further than [radius] metres from the customer is a far
/// check-in: it needs a reason and a photo, and the team lead sees it.
bool isFarCheckIn(num metres, {required int radius}) => metres > radius;

/// One leg of the day's route between two stops, by road.
class RouteLeg {
  const RouteLeg({required this.km, required this.minutes});

  /// Dhaka roads run about a third longer than the straight line, at about
  /// 17 km/h door to door.
  static const roadFactor = 1.35;
  static const cityKmh = 17.0;

  factory RouteLeg.between(double lat1, double lng1, double lat2, double lng2) {
    final km = distanceMetres(lat1, lng1, lat2, lng2) / 1000 * roadFactor;
    return RouteLeg(km: km, minutes: (km / cityKmh * 60).round());
  }

  final double km;
  final int minutes;
}
