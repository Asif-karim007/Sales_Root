import 'dart:math';

import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/data/attendance_fixtures.dart';
import 'package:salesroot/features/field_force/data/tracking_fixtures.dart';
import 'package:salesroot/features/field_force/data/visit_fixtures.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/service/geo.dart';

/// The fake server's field-force tables and the views it derives from them:
/// a member's day events, the recorded trail and the live position.
class FakeFieldData {
  FakeFieldData(this._backend);

  final FakeBackend _backend;

  SeedGraph get graph => _backend.graph;

  FakeTable get visits => _backend.table('visits', visitFixtures);
  FakeTable get attendance => _backend.table('attendance', attendanceFixtures);
  FakeTable get corrections =>
      _backend.table('attendance_corrections', correctionFixtures);
  FakeTable get settingsTable =>
      _backend.table('tracking_settings', trackingSettingsFixtures);
  FakeTable get consents =>
      _backend.table('tracking_consents', consentFixtures);
  FakeTable get pauses => _backend.table('tracking_pauses', pauseFixtures);
  FakeTable get pings => _backend.table('tracker_pings', (_) => const []);

  TrackingSettings get settings =>
      TrackingSettings.fromJson(settingsTable.byId(1));

  bool _onDay(dynamic stamp, DateTime day) {
    final at = jsonDate(stamp);
    return at != null && AppDateUtils.isSameDay(at, day);
  }

  int _employeeOf(Map<String, dynamic> row) =>
      jsonInt((row['Employee'] as Map<String, dynamic>?)?['Id']) ?? 0;

  List<Map<String, dynamic>> visitsOf(int memberId, DateTime day) =>
      [
        for (final row in visits.rows)
          if (_employeeOf(row) == memberId && _onDay(row['PlannedAt'], day))
            row,
      ]..sort(
        (a, b) =>
            (jsonInt(a['Order']) ?? 0).compareTo(jsonInt(b['Order']) ?? 0),
      );

  Map<String, dynamic>? logOf(int memberId, DateTime day) {
    for (final row in attendance.rows) {
      if (row['EmployeeId'] == memberId && _onDay(row['Date'], day)) return row;
    }
    return null;
  }

  Map<String, dynamic>? correctionOf(int memberId, DateTime day) {
    for (final row in corrections.rows) {
      if (row['EmployeeId'] == memberId && _onDay(row['Date'], day)) return row;
    }
    return null;
  }

  AttendanceStatus statusOf(int memberId, DateTime day, DateTime now) {
    final date = AppDateUtils.dateOnly(day);
    final today = AppDateUtils.dateOnly(now);
    if (!settings.isWorkDay(date)) return AttendanceStatus.off;
    if (date.isAfter(today)) return AttendanceStatus.upcoming;
    final row = logOf(memberId, date);
    if (row != null && row['Kind'] == 'Leave') return AttendanceStatus.leave;
    if (row != null) {
      return jsonBool(row['IsLate'])
          ? AttendanceStatus.late
          : AttendanceStatus.present;
    }
    if (correctionOf(memberId, date)?['Status'] == 'Approved') {
      return AttendanceStatus.present;
    }
    if (date == today) {
      final cutoff = clockOn(
        date,
        settings.dutyStart,
      ).add(const Duration(hours: 2));
      if (now.isBefore(cutoff)) return AttendanceStatus.upcoming;
    }
    return AttendanceStatus.absent;
  }

  /// Days of [month] up to today, with each one's status.
  List<Map<String, dynamic>> monthDays(
    int memberId,
    DateTime month,
    DateTime now,
  ) {
    final last = DateTime(month.year, month.month + 1, 0).day;
    return [
      for (var d = 1; d <= last; d++)
        {
          'Date': jsonUtc(DateTime(month.year, month.month, d)),
          'Status': statusOf(
            memberId,
            DateTime(month.year, month.month, d),
            now,
          ).wire,
          'Correction': correctionOf(
            memberId,
            DateTime(month.year, month.month, d),
          )?['Status'],
        }..removeWhere((_, value) => value == null),
    ];
  }

  Map<String, dynamic> summaryOf(
    int memberId,
    DateTime from,
    DateTime to,
    DateTime now,
  ) {
    var working = 0, present = 0, late = 0, leave = 0, absent = 0, worked = 0;
    for (
      var day = AppDateUtils.dateOnly(from);
      !day.isAfter(to);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final status = statusOf(memberId, day, now);
      if (status == AttendanceStatus.off ||
          status == AttendanceStatus.upcoming) {
        continue;
      }
      working++;
      switch (status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.late:
          present++;
          late++;
        case AttendanceStatus.leave:
          leave++;
        case AttendanceStatus.absent:
          absent++;
        case AttendanceStatus.off || AttendanceStatus.upcoming:
          break;
      }
      final log = logOf(memberId, day);
      if (log != null) {
        worked +=
            jsonInt(log['WorkedMinutes']) ??
            AttendanceLog.fromJson(log).workedUntil(now);
      }
    }
    return {
      'WorkingDays': working,
      'Present': present,
      'Late': late,
      'Leave': leave,
      'Absent': absent,
      'WorkedMinutes': worked,
    };
  }

  /// What happened on [memberId]'s [day], in time order.
  List<Map<String, dynamic>> events(int memberId, DateTime day, DateTime now) {
    final events = <Map<String, dynamic>>[];
    final log = logOf(memberId, day);
    if (log != null && log['Kind'] == 'Log') {
      final place = log['CheckInPlace'] as Map<String, dynamic>?;
      events.add({
        'Kind': 'CheckIn',
        'Time': log['CheckInAt'],
        'Title': place?['Location'],
        'Distance': log['CheckInDistance'],
      });
      for (final b in jsonList(log['Breaks'], (json) => json)) {
        final start = jsonDate(b['Start']);
        if (start == null) continue;
        final end = jsonDate(b['End']) ?? now;
        events.add({
          'Kind': 'Break',
          'Time': b['Start'],
          'Minutes': end.difference(start).inMinutes,
          'InProgress': b['End'] == null,
        });
      }
      if (log['CheckOutAt'] != null) {
        events.add({'Kind': 'CheckOut', 'Time': log['CheckOutAt']});
      }
    }
    for (final visit in visitsOf(memberId, day)) {
      final start = visit['Start'] as Map<String, dynamic>?;
      final startAt = jsonDate(start?['Time']);
      if (start == null || startAt == null) continue;
      final open = visit['Status'] == 'InProgress';
      events.add({
        'Kind': 'Visit',
        'Time': start['Time'],
        'Title': (visit['Company'] as Map<String, dynamic>?)?['Name'],
        'Area': visit['Area'],
        'Minutes': open
            ? now.difference(startAt).inMinutes
            : visit['DurationMinutes'],
        'VisitId': visit['Id'],
        'InProgress': open,
        'Distance': visit['CheckInDistance'],
        'Detail': visit['Purpose'],
      });
    }
    for (final pause in pauses.rows) {
      if (pause['EmployeeId'] != memberId || !_onDay(pause['Start'], day)) {
        continue;
      }
      final start = jsonDate(pause['Start']);
      if (start == null) continue;
      events.add({
        'Kind': 'Pause',
        'Time': pause['Start'],
        'Minutes': (jsonDate(pause['End']) ?? now).difference(start).inMinutes,
        'InProgress': pause['End'] == null,
      });
    }
    events.sort(
      (a, b) =>
          (jsonDate(a['Time']) ?? now).compareTo(jsonDate(b['Time']) ?? now),
    );
    return events;
  }

  /// The trail the member's phone recorded on [day]. The user's own uploaded
  /// pings win; everyone else's day is simulated from their visits.
  List<Map<String, dynamic>> trail(int memberId, DateTime day, DateTime now) {
    final uploaded = [
      for (final ping in pings.rows)
        if (ping['EmployeeId'] == memberId && _onDay(ping['LocationTime'], day))
          ping,
    ];
    if (uploaded.isNotEmpty) return uploaded;
    return _simulatedTrail(memberId, day, now);
  }

  List<Map<String, dynamic>> _simulatedTrail(
    int memberId,
    DateTime day,
    DateTime now,
  ) {
    final log = logOf(memberId, day);
    final checkIn = jsonDate(log?['CheckInAt']);
    if (log == null || checkIn == null) return const [];
    final random = graph.random('trail-$memberId-${day.month}-${day.day}');
    final place = log['CheckInPlace'] as Map<String, dynamic>?;
    final stops = <_Stop>[
      _Stop(
        jsonDouble(place?['Latitude']) ?? officeLat,
        jsonDouble(place?['Longitude']) ?? officeLng,
        checkIn,
      ),
      for (final visit in visitsOf(memberId, day))
        if (jsonDate((visit['Start'] as Map<String, dynamic>?)?['Time'])
            case final at?)
          _Stop(
            jsonDouble(visit['Latitude']) ?? officeLat,
            jsonDouble(visit['Longitude']) ?? officeLng,
            at,
          ),
    ];
    var until = jsonDate(log['CheckOutAt']) ?? now;
    if (memberId == notTrackingMemberId && AppDateUtils.isSameDay(day, now)) {
      until = clockOn(day, '11:42');
    }
    if (until.isAfter(now)) until = now;

    final points = <(double, double, DateTime)>[];
    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final next = i + 1 < stops.length ? stops[i + 1] : null;
      final leg = next == null
          ? null
          : RouteLeg.between(stop.lat, stop.lng, next.lat, next.lng);
      final legMinutes = max(4, leg?.minutes ?? 0);
      final departAt = next == null
          ? until
          : _later(
              stop.at.add(const Duration(minutes: 5)),
              next.at.subtract(Duration(minutes: legMinutes)),
            );
      for (
        var t = stop.at;
        t.isBefore(departAt);
        t = t.add(const Duration(minutes: 5))
      ) {
        final (lat, lng) = offsetBy(
          stop.lat,
          stop.lng,
          random.nextDouble() * 8,
          random.nextDouble() * 2 * pi,
        );
        points.add((lat, lng, t));
      }
      if (next == null) break;
      final travel = next.at.difference(departAt).inMinutes;
      for (var m = 0; m < travel; m += 2) {
        final f = travel == 0 ? 1.0 : m / travel;
        final wobble = sin(f * pi * 3) * 60;
        final (lat, lng) = offsetBy(
          stop.lat + (next.lat - stop.lat) * f,
          stop.lng + (next.lng - stop.lng) * f,
          wobble.abs(),
          wobble >= 0 ? pi / 2 : -pi / 2,
        );
        points.add((lat, lng, departAt.add(Duration(minutes: m))));
      }
    }

    final paused = <(DateTime, DateTime)>[
      for (final pause in pauses.rows)
        if (pause['EmployeeId'] == memberId)
          if (jsonDate(pause['Start']) case final start?
              when AppDateUtils.isSameDay(start, day))
            (start, jsonDate(pause['End']) ?? now),
    ];
    bool inPause(DateTime t) =>
        paused.any((p) => !t.isBefore(p.$1) && t.isBefore(p.$2));

    return [
      for (final (lat, lng, t) in points)
        if (!t.isAfter(until) && !inPause(t))
          {
            'Latitude': lat,
            'Longitude': lng,
            'LocationTime': jsonUtc(t),
            'Battery': max(
              8,
              97 - (t.difference(checkIn).inMinutes / 60 * 5.5).round(),
            ),
          },
    ];
  }

  DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  /// Where [member] is now, by the server's clock.
  Map<String, dynamic> live(SeedMember member, DateTime now) {
    final base = {
      'MemberId': member.id,
      'Name': member.name,
      'NameBn': member.nameBn,
    };
    final log = logOf(member.id, now);
    final checkedIn = log != null && log['CheckInAt'] != null;
    final points = trail(member.id, now, now);
    if (!checkedIn || points.isEmpty) {
      return {...base, 'Status': 'OffDuty', 'CheckedIn': checkedIn};
    }
    final last = points.last;
    final lat = jsonDouble(last['Latitude']) ?? officeLat;
    final lng = jsonDouble(last['Longitude']) ?? officeLng;
    final seenAt = jsonDate(last['LocationTime']) ?? now;
    final open = visitsOf(
      member.id,
      now,
    ).where((v) => v['Status'] == 'InProgress').firstOrNull;
    final previous = points.length > 1 ? points[points.length - 2] : last;
    final moved = distanceMetres(
      jsonDouble(previous['Latitude']) ?? lat,
      jsonDouble(previous['Longitude']) ?? lng,
      lat,
      lng,
    );
    final minutes = now.difference(seenAt).inMinutes;
    final status = log['CheckOutAt'] != null
        ? 'OffDuty'
        : minutes > 20
        ? 'NotTracking'
        : open != null
        ? 'OnVisit'
        : moved > 15
        ? 'Moving'
        : 'Idle';
    return {
      ...base,
      'Status': status,
      'CheckedIn': log['CheckOutAt'] == null,
      'Latitude': lat,
      'Longitude': lng,
      'Area': areaJson(nearestArea(lat, lng)),
      'VisitCompany': (open?['Company'] as Map<String, dynamic>?)?['Name'],
      'LastSeenAt': last['LocationTime'],
      'LastSeenMinutes': minutes,
      'Battery': last['Battery'],
    }..removeWhere((_, value) => value == null);
  }

  SeedArea nearestArea(double lat, double lng) => SeedGraph.areas.reduce(
    (best, area) =>
        distanceMetres(lat, lng, area.lat, area.lng) <
            distanceMetres(lat, lng, best.lat, best.lng)
        ? area
        : best,
  );
}

class _Stop {
  const _Stop(this.lat, this.lng, this.at);

  final double lat;
  final double lng;
  final DateTime at;
}
