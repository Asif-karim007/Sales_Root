import 'package:flutter/widgets.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/translations/translations.dart';

/// Field-force units: distances, durations and wall-clock times.
extension FieldForceFormat on BuildContext {
  /// "25 m" below a kilometre, "1.2 km" above.
  String ffDistance(num metres) {
    if (metres < 1000) return l10n.ffMetres(fmt.number(metres.round()));
    return l10n.ffKm(fmt.number(metres / 1000, decimals: 1));
  }

  String ffKm(double km) =>
      l10n.ffKm(fmt.number(km, decimals: km < 10 ? 1 : 0));

  /// "48 min", or "1 h 20 min" from an hour up.
  String ffDuration(int minutes) {
    if (minutes < 60) return l10n.ffMinutes(fmt.number(minutes));
    return l10n.ffHoursMinutes(
      fmt.number(minutes ~/ 60),
      fmt.number(minutes % 60),
    );
  }

  /// "5:18", for the worked-time ring and the visit timer.
  String ffClockDuration(int minutes) => fmt.digits(
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}',
  );

  /// A "09:00" wall-clock string in the user's time format.
  String ffWallClock(String clock) => fmt.time(clockOn(DateTime.now(), clock));

  /// "9:00–18:00".
  String ffWindow(String start, String end) =>
      '${ffWallClock(start)}–${ffWallClock(end)}';
}
