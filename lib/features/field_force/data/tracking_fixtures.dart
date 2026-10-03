import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/data/visit_fixtures.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';

/// The workspace's tracking rules, as the prototype's settings screen shows.
List<Map<String, dynamic>> trackingSettingsFixtures(SeedGraph graph) => [
  {'Id': 1, ...const TrackingSettings().toJson()},
];

/// Everyone but the signed-in user has already agreed to live tracking, so
/// the consent screen is the user's first step.
List<Map<String, dynamic>> consentFixtures(SeedGraph graph) => [
  for (final member in fieldMembers(graph))
    if (member.id != SeedGraph.meId)
      {
        'Id': member.id,
        'Given': true,
        'At': jsonUtc(graph.daysAgo(30 + member.id, hour: 9)),
      },
];

/// Logged lunch-time pauses for a few members over the last week.
List<Map<String, dynamic>> pauseFixtures(SeedGraph graph) {
  final rows = <Map<String, dynamic>>[];
  for (final member in fieldMembers(graph)) {
    if (member.id == SeedGraph.meId || member.id % 3 != 1) continue;
    for (var day = 6; day >= 0; day--) {
      final start = graph.daysAgo(day, hour: 12, minute: 30);
      if (start.weekday == DateTime.friday || start.isAfter(graph.anchor)) {
        continue;
      }
      rows.add({
        'Id': rows.length + 1,
        'EmployeeId': member.id,
        'Start': jsonUtc(start),
        'End': jsonUtc(start.add(const Duration(minutes: 12))),
      });
    }
  }
  return rows;
}

/// The member whose phone stopped sharing before noon today.
const notTrackingMemberId = 10;
