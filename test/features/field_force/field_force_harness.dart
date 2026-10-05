import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/field_force/providers/location_providers.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';

import '../../helpers/api_stub.dart';

/// Rafi's membership in Dhaka Sales Ltd.
const rafiId = '01a10101-8656-7886-b8e5-4f197fbd9159';

/// The visit the recorded responses started.
const visitId = '01a10d05-f45b-710c-9095-806e0018311f';

/// Rahim Traders, a customer with a location.
const rahimId = '01a10101-8657-7f15-8630-b08119f1ae61';

/// A phone standing still at one spot.
class StillLocation implements LocationSource {
  StillLocation(this.latitude, this.longitude, {this.fails = false});

  double latitude;
  double longitude;
  bool fails;

  @override
  Future<GeoFix> current() async {
    if (fails) throw const LocationFailure(LocationIssue.serviceOff);
    return GeoFix(
      latitude: latitude,
      longitude: longitude,
      accuracy: 12,
      time: DateTime.now(),
    );
  }

  @override
  Future<String?> placeName(double latitude, double longitude) async => null;
}

/// The Field Force endpoints, answering from the recorded responses.
ApiStub fieldStub() => ApiStub()
  ..on('GET', 'attendance/today', fixture('field_today_on_visit'))
  ..on('GET', 'attendance', (RequestOptions r) {
    return r.queryParameters.containsKey('period')
        ? fixture('field_attendance_month')
        : fixture('field_attendance_day');
  })
  ..on('GET', 'reports/field', fixture('field_report'))
  ..on('GET', 'visits', fixture('field_visits_open'))
  ..on('GET', 'workspaces/current', fixture('field_workspace'))
  ..on('GET', 'workspaces/members', fixture('field_members'))
  ..on('GET', 'companies', fixture('field_companies'))
  ..on('GET', 'companies/{id}', fixture('field_company'))
  ..on('GET', 'team/map', fixture('field_team_map_forbidden'), status: 403)
  ..on('POST', 'attendance/check-in', fixture('field_checked_in'))
  ..on('POST', 'attendance/check-out', fixture('field_checked_out'))
  ..on('POST', 'visits/start', fixture('field_visit_started'))
  ..on('POST', 'locations', fixture('field_locations_stored'))
  ..on('POST', 'files', fixture('field_uploaded'));

/// Signed in as Rafi over [stub], with the workspace loaded. [fullAccess]
/// opens every Field Force module, as a team lead would see it.
Future<ProviderContainer> fieldContainer(
  ApiStub stub, {
  String role = 'executive',
  bool fullAccess = false,
  LocationSource? location,
  List<Override> overrides = const [],
}) async {
  final container = await apiContainer(
    stub,
    me: meWith(role: role, level: 'standard'),
    overrides: [
      locationSourceProvider.overrideWithValue(
        location ?? StillLocation(23.8069, 90.3687),
      ),
      if (fullAccess)
        moduleAccessProvider.overrideWith(
          (ref, module) => const ModuleAccess(
            canView: true,
            canAdd: true,
            canEdit: true,
            canDelete: true,
            canApprove: true,
            canExport: true,
          ),
        ),
      ...overrides,
    ],
  );
  await container.read(workspacesProvider.future);
  await container.read(permissionsProvider.future);
  return container;
}

/// Keeps an auto-dispose provider alive for the rest of the test.
void keepAlive(
  ProviderContainer container,
  ProviderListenable<Object?> provider,
) {
  final sub = container.listen(provider, (_, _) {});
  addTearDown(sub.close);
}

/// The JSON body of [request].
Map<String, dynamic> sent(RequestOptions? request) {
  final data = request?.data;
  if (data is Map<String, dynamic>) return data;
  if (data is String) return jsonDecode(data) as Map<String, dynamic>;
  return const {};
}

/// The recorded open visit, ended as [body] asked.
Map<String, dynamic> endedVisit(Map<String, dynamic> body) {
  final row = Map<String, dynamic>.of(
    (fixtureMap('field_visits_open')['items'] as List).first
        as Map<String, dynamic>,
  );
  return {
    ...row,
    'endedAt': '2026-10-05T17:20:00Z',
    'outcome': body['outcome'],
    'note': body['note'],
    'photos': body['photos'] ?? const <String>[],
  };
}
