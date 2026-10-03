import 'dart:math';

import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/data/visit_fixtures.dart';

const officeName = 'Gulshan-1, Dhaka';

/// Minutes after the shift starts before a check-in counts as late.
const lateGraceMinutes = 15;

/// Two months of punches for every field member. Fridays are off; a few
/// days are leave or absent. Today follows the prototype: the user checked in
/// at 9:12, Bushra Nowshin came in late, Abdul Malek has not checked in and
/// asked for a correction, and Tanvir Ahmed is on leave.
List<Map<String, dynamic>> attendanceFixtures(SeedGraph graph) {
  final rows = <Map<String, dynamic>>[];
  for (final member in fieldMembers(graph)) {
    final random = graph.random('attendance-${member.id}');
    for (var day = 62; day >= 0; day--) {
      final date = graph.daysAgo(day, hour: 0);
      if (date.weekday == DateTime.friday) continue;
      final row = day == 0
          ? _today(graph, member, random)
          : _pastDay(member, date, random);
      if (row != null) rows.add({...row, 'Id': rows.length + 1});
    }
  }
  return rows;
}

/// Correction requests: Abdul Malek's missing check-in today.
List<Map<String, dynamic>> correctionFixtures(SeedGraph graph) {
  if (!graph.members.any((m) => m.id == _correctionMemberId)) return const [];
  return [
    {
      'Id': 1,
      'EmployeeId': _correctionMemberId,
      'Date': jsonUtc(AppDateUtils.dateOnly(graph.anchor)),
      'Reason': 'Phone switched off — I was at the Savar site from 9:30.',
      'Status': 'Pending',
    },
  ];
}

const _correctionMemberId = 6;
const _lateMemberId = 5;
const _leaveMemberId = 8;

Map<String, dynamic>? _today(
  SeedGraph graph,
  SeedMember member,
  Random random,
) {
  final date = AppDateUtils.dateOnly(graph.anchor);
  if (member.id == _correctionMemberId) return null;
  if (member.id == _leaveMemberId) return _leave(member, date);
  final minute = switch (member.id) {
    SeedGraph.meId => 9 * 60 + 12,
    _lateMemberId => 9 * 60 + 20,
    _ => 8 * 60 + 48 + random.nextInt(27),
  };
  final checkIn = date.add(Duration(minutes: minute));
  if (checkIn.isAfter(graph.anchor)) return null;
  return _log(member, date, checkIn, null, random);
}

Map<String, dynamic>? _pastDay(
  SeedMember member,
  DateTime date,
  Random random,
) {
  final roll = random.nextInt(100);
  if (roll < 3) return _leave(member, date);
  if (roll < 6) return null;
  final late = roll < 14;
  final minute = late
      ? 9 * 60 + lateGraceMinutes + 1 + random.nextInt(35)
      : 8 * 60 + 45 + random.nextInt(25);
  final checkIn = date.add(Duration(minutes: minute));
  final earlyOut = random.nextInt(100) < 5;
  final checkOut = date.add(
    Duration(
      minutes: earlyOut ? 16 * 60 + 20 : 17 * 60 + 50 + random.nextInt(50),
    ),
  );
  return _log(member, date, checkIn, checkOut, random, earlyOut: earlyOut);
}

Map<String, dynamic> _leave(SeedMember member, DateTime date) => {
  'EmployeeId': member.id,
  'Date': jsonUtc(date),
  'Kind': 'Leave',
};

Map<String, dynamic> _log(
  SeedMember member,
  DateTime date,
  DateTime checkIn,
  DateTime? checkOut,
  Random random, {
  bool earlyOut = false,
}) {
  final distance = 5 + random.nextInt(40);
  final (lat, lng) = offsetBy(
    officeLat,
    officeLng,
    distance.toDouble(),
    random.nextDouble() * 2 * pi,
  );
  final lateMinutes = checkIn.difference(date).inMinutes - 9 * 60;
  final hasBreak = checkOut != null && random.nextInt(100) < 60;
  final breakStart = date.add(Duration(minutes: 13 * 60 + random.nextInt(20)));
  final breakEnd = breakStart.add(Duration(minutes: 20 + random.nextInt(20)));
  final breakMinutes = hasBreak ? breakEnd.difference(breakStart).inMinutes : 0;
  return {
    'EmployeeId': member.id,
    'Date': jsonUtc(date),
    'Kind': 'Log',
    'CheckInAt': jsonUtc(checkIn),
    'CheckOutAt': jsonUtc(checkOut),
    'WorkedMinutes': checkOut == null
        ? null
        : checkOut.difference(checkIn).inMinutes - breakMinutes,
    'CheckInPlace': {'Latitude': lat, 'Longitude': lng, 'Location': officeName},
    'CheckInDistance': distance,
    'IsLate': lateMinutes > lateGraceMinutes,
    'LateMinutes': lateMinutes > 0 ? lateMinutes : 0,
    'IsEarlyOut': earlyOut,
    'Breaks': [
      if (hasBreak) {'Start': jsonUtc(breakStart), 'End': jsonUtc(breakEnd)},
    ],
  }..removeWhere((_, value) => value == null);
}
