import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/service/geo.dart';
import 'package:salesroot/features/field_force/service/route_plan.dart';

void main() {
  group('distanceMetres', () {
    test('is zero for the same point', () {
      expect(distanceMetres(23.7808, 90.4163, 23.7808, 90.4163), 0);
    });

    test('Gulshan-1 to Banani is about 1.7 km', () {
      final metres = distanceMetres(23.7808, 90.4163, 23.7937, 90.4066);
      expect(metres, closeTo(1735, 25));
    });

    test('a thousandth of a degree of latitude is about 111 m', () {
      expect(distanceMetres(23.0, 90.0, 23.001, 90.0), closeTo(111.2, 0.5));
    });
  });

  group('far check-in rule', () {
    test('within the radius is not far', () {
      expect(isFarCheckIn(25, radius: 300), isFalse);
      expect(isFarCheckIn(300, radius: 300), isFalse);
    });

    test('beyond the radius is far', () {
      expect(isFarCheckIn(301, radius: 300), isTrue);
      expect(isFarCheckIn(850, radius: 300), isTrue);
    });

    test('follows the configured radius', () {
      expect(isFarCheckIn(250, radius: 200), isTrue);
      expect(isFarCheckIn(250, radius: 500), isFalse);
    });
  });

  test('a route sums road legs between stops', () {
    Visit stop(int id, double lat, double lng) => Visit(
      id: id,
      status: VisitStatus.planned,
      latitude: lat,
      longitude: lng,
    );
    final plan = RoutePlan.of([
      stop(1, 23.8223, 90.3654),
      stop(2, 23.7937, 90.4066),
      stop(3, 23.7330, 90.4172),
    ]);
    expect(plan.legs.first, isNull);
    expect(plan.legs[1]?.km, greaterThan(5));
    expect(
      plan.km,
      closeTo((plan.legs[1]?.km ?? 0) + (plan.legs[2]?.km ?? 0), 0.001),
    );
    expect(plan.legs[1]?.minutes, greaterThan(15));
  });
}
