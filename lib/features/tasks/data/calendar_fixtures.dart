import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';

/// The user's private events, spread around today.
List<Map<String, dynamic>> calendarFixtures(SeedGraph graph) {
  Map<String, dynamic> event(
    String title,
    DateTime start, {
    String? location,
    bool allDay = false,
    int? reminder = 60,
  }) => {
    'Title': title,
    'Start': jsonUtc(start),
    'Location': location,
    'AllDay': allDay,
    'IsPrivate': true,
    'ReminderMinutes': reminder,
    'OwnerId': SeedGraph.meId,
  }..removeWhere((_, value) => value == null);

  final rows = [
    event(
      'Doctor appointment',
      graph.daysAgo(0, hour: 18),
      location: 'Labaid, Dhanmondi',
    ),
    event(
      'মেয়ের স্কুলের PTA মিটিং',
      graph.daysAhead(2, hour: 9, minute: 30),
      location: 'Mohammadpur',
    ),
    event('Bank — loan papers', graph.daysAhead(3, hour: 12), reminder: 30),
    event(
      'Ammu-r checkup',
      graph.daysAhead(6, hour: 17),
      location: 'Square Hospital',
    ),
    event('Family dinner', graph.daysAhead(8, hour: 20), reminder: null),
    event(
      'Bike servicing',
      graph.daysAhead(11, hour: 8),
      location: 'Mirpur 10',
      reminder: 120,
    ),
    event(
      'Annual leave',
      graph.daysAhead(15, hour: 0),
      allDay: true,
      reminder: null,
    ),
    event('Cousin-er biye', graph.daysAhead(19, hour: 0), allDay: true),
    event('Dentist', graph.daysAgo(3, hour: 19), location: 'Banani'),
    event('Gym', graph.daysAgo(5, hour: 7), reminder: null),
    event('Utility bill pay', graph.daysAgo(9, hour: 11), reminder: 30),
    event('Friday jumma + bazar', graph.daysAgo(12, hour: 13), reminder: null),
    event(
      'Passport renewal',
      graph.daysAgo(18, hour: 10),
      location: 'Agargaon',
    ),
  ];
  return [
    for (var i = 0; i < rows.length; i++) {...rows[i], 'Id': i + 1},
  ];
}
