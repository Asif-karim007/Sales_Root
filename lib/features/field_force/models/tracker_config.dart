import 'package:salesroot/core/utils/json_fields.dart';

/// The server's live-tracking schedule for this member: whether it is on,
/// the daily window and the heartbeat interval.
class TrackerConfig {
  const TrackerConfig({
    required this.isEnabled,
    this.startTime,
    this.endTime,
    this.durationInMinute = defaultDurationInMinute,
    this.workDays = const [],
  });

  static const double defaultDurationInMinute = 5;

  static const disabled = TrackerConfig(isEnabled: false);

  final bool isEnabled;

  /// Local wall-clock "HH:mm"; null means unbounded on that side.
  final String? startTime;
  final String? endTime;
  final double durationInMinute;

  /// `DateTime.weekday` values; empty means every day.
  final List<int> workDays;

  factory TrackerConfig.fromJson(Map<String, dynamic> json) {
    final duration = jsonDouble(json['DurationInMinute']);
    return TrackerConfig(
      isEnabled: jsonBool(json['IsEnabled']),
      startTime: _time(json['StartTime']),
      endTime: _time(json['EndTime']),
      durationInMinute: duration == null || duration <= 0
          ? defaultDurationInMinute
          : duration,
      workDays: jsonInts(json['WorkDays']),
    );
  }

  Map<String, dynamic> toJson() => {
    'IsEnabled': isEnabled,
    'StartTime': startTime,
    'EndTime': endTime,
    'DurationInMinute': durationInMinute,
    'WorkDays': workDays,
  }..removeWhere((_, value) => value == null);

  Duration get interval {
    final seconds = (durationInMinute * 60).round();
    return Duration(seconds: seconds < 60 ? 60 : seconds);
  }

  /// The device's wall clock against the window, with no timezone
  /// conversion: the server sends local times on purpose.
  bool isInsideWindow(DateTime localNow) {
    if (workDays.isNotEmpty && !workDays.contains(localNow.weekday)) {
      return false;
    }
    final start = _minutes(startTime);
    final end = _minutes(endTime);
    final now = localNow.hour * 60 + localNow.minute;
    if (start == null && end == null) return true;
    if (start == null) return now <= (end ?? now);
    if (end == null) return now >= start;
    if (start <= end) return now >= start && now <= end;
    return now >= start || now <= end;
  }

  bool sameSchedule(TrackerConfig other) =>
      isEnabled == other.isEnabled &&
      startTime == other.startTime &&
      endTime == other.endTime &&
      durationInMinute == other.durationInMinute &&
      workDays.join(',') == other.workDays.join(',');

  static String? _time(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return _minutes(text) == null ? null : text;
  }

  static int? _minutes(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    final hour = int.tryParse(parts.first);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (hour == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }
}
