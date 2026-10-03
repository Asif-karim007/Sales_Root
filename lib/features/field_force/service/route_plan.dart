import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/service/geo.dart';

/// The day's stops in order, with the road leg into each one.
class RoutePlan {
  const RoutePlan._(this.stops, this.legs);

  factory RoutePlan.of(List<Visit> visits) {
    final legs = <RouteLeg?>[];
    Visit? previous;
    for (final visit in visits) {
      final from = previous;
      legs.add(from == null ? null : _leg(from, visit));
      if (visit.latitude != null && visit.longitude != null) previous = visit;
    }
    return RoutePlan._(visits, legs);
  }

  final List<Visit> stops;

  /// The leg into each stop; null for the first one.
  final List<RouteLeg?> legs;

  double get km => legs.fold(0, (sum, leg) => sum + (leg?.km ?? 0));

  static RouteLeg? _leg(Visit from, Visit to) {
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
