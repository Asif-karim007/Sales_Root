import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/service/geo.dart';

/// The day's stops in order, with the road leg into each one.
class RoutePlan {
  const RoutePlan._(this.stops, this.legs);

  factory RoutePlan.of(List<PlanStop> stops) {
    final legs = <RouteLeg?>[];
    PlanStop? previous;
    for (final stop in stops) {
      final from = previous;
      legs.add(from == null ? null : _leg(from, stop));
      if (stop.latitude != null && stop.longitude != null) previous = stop;
    }
    return RoutePlan._(stops, legs);
  }

  final List<PlanStop> stops;

  /// The leg into each stop; null for the first one.
  final List<RouteLeg?> legs;

  double get km => legs.fold(0, (sum, leg) => sum + (leg?.km ?? 0));

  static RouteLeg? _leg(PlanStop from, PlanStop to) {
    final fromLat = from.latitude;
    final fromLng = from.longitude;
    final toLat = to.latitude;
    final toLng = to.longitude;
    if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
      return null;
    }
    return RouteLeg.between(fromLat, fromLng, toLat, toLng);
  }
}
