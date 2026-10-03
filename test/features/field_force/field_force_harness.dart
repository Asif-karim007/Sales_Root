import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/dev/dev_settings.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/field_force/providers/location_providers.dart';
import 'package:salesroot/features/field_force/service/location_source.dart';

/// A phone standing still at one spot.
class StillLocation implements LocationSource {
  StillLocation(this.latitude, this.longitude);

  double latitude;
  double longitude;

  @override
  Future<GeoFix> current() async => GeoFix(
    latitude: latitude,
    longitude: longitude,
    accuracy: 12,
    time: DateTime.now(),
  );

  @override
  Future<String?> placeName(double latitude, double longitude) async => null;
}

/// The seed's "now": a month back at 17:00, so nothing it seeds collides
/// with what a test does today.
DateTime testAnchor() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - 30, 17);
}

/// Signed in to Dhaka Sales (team plan, Field Force on) with 25 members, the
/// fake server without latency, and [location] as the phone's position.
Future<ProviderContainer> fieldForceContainer({
  WorkspaceRole? role,
  Set<AddOn>? addOns,
  LocationSource? location,
  List<Override> overrides = const [],
  DateTime? anchor,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'session': jsonEncode({'Token': 't', 'UserId': 1, 'Name': 'Karim Hossain'}),
  });
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      seedGraphProvider.overrideWithValue(
        SeedGraph.build(
          workspaceId: 200,
          kind: WorkspaceKind.team,
          memberCount: 25,
          leadCount: 230,
          now: anchor ?? testAnchor(),
        ),
      ),
      locationSourceProvider.overrideWithValue(
        location ?? StillLocation(23.7808, 90.4163),
      ),
      ...overrides,
    ],
  );
  container
      .read(devSettingsProvider.notifier)
      .update(
        (s) =>
            s.copyWith(latency: false, role: () => role, addOns: () => addOns),
      );
  await container.read(workspacesProvider.future);
  return container;
}

/// Keeps an auto-dispose provider alive for the rest of the test.
void keepAlive(
  ProviderContainer container,
  ProviderListenable<Object?> provider,
) {
  container.listen(provider, (_, _) {});
}
