import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

import '../../helpers/api_stub.dart';

/// Every call the homes make, answered from the recorded responses of the
/// test user. Reports answer per preset where a home asks for two.
ApiStub homeStub() => ApiStub()
  ..on('GET', 'home', fixture('home_home'))
  ..on('GET', 'reports/me', fixture('home_reports_me'))
  ..on('GET', 'reports/pipeline', fixture('home_pipeline'))
  ..on('GET', 'reports/targets', fixture('home_targets_report'))
  ..on('GET', 'reports/activity', fixture('home_activity_today'))
  ..on(
    'GET',
    'reports/collection',
    (RequestOptions r) => r.queryParameters['group'] == 'month'
        ? fixture('home_collection_months')
        : fixture('home_collection_days'),
  )
  ..on('GET', 'reports/sales', fixture('home_sales_weeks'))
  ..on('GET', 'quotes', fixture('home_quotes_sent'))
  ..on('GET', 'attendance', fixture('home_attendance'))
  ..on('GET', 'ai/daily-summary', fixture('home_daily_summary'))
  ..on('GET', 'targets', fixture('home_targets'))
  ..on('GET', 'dues', fixture('home_dues_overdue'))
  ..on('GET', 'notifications', fixture('home_notifications'));

/// `GET home` with its counts set to [kpis] and today's plan to [today].
Map<String, dynamic> homeWith({
  Map<String, Object?> kpis = const {},
  List<Object?>? today,
}) {
  final home = fixtureMap('home_home');
  return {
    ...home,
    'kpis': {...home['kpis'] as Map<String, dynamic>, ...kpis},
    'today': ?today,
  };
}

/// A workspace with nothing in it yet.
Map<String, dynamic> emptyHome() => homeWith(
  kpis: const {
    'newLeadsQueue': 0,
    'newLeadsWeek': 0,
    'followupsDue': 0,
    'openLeads': 0,
    'toCollect': 0,
    'overdue': 0,
    'wonMonth': 0,
    'sleeping': 0,
  },
  today: const [],
)..['queue'] = const <Object>[];

/// A signed-in container over [stub] whose workspace, role and grants are
/// loaded.
Future<ProviderContainer> homeContainer(
  ApiStub stub, {
  String role = 'executive',
  String level = 'easy',
}) async {
  final container = await apiContainer(
    stub,
    me: meWith(role: role, level: level),
  );
  container.listen(currentWorkspaceProvider, (_, _) {});
  await container.read(workspacesProvider.future);
  await container.read(permissionsProvider.future);
  return container;
}
