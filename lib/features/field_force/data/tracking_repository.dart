import 'package:salesroot/features/field_force/models/tracker_config.dart';
import 'package:salesroot/features/field_force/models/tracker_ping.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';

/// What the server said about one uploaded batch.
class PingUploadResult {
  const PingUploadResult({required this.accepted, required this.rejected});

  final int accepted;
  final int rejected;
}

abstract interface class TrackingRepository {
  Future<TrackingSettings> settings();

  Future<TrackingSettings> saveSettings(TrackingSettings settings);

  Future<TrackingConsent> consent();

  Future<TrackingConsent> setConsent({required bool given});

  /// This member's tracking schedule.
  Future<TrackerConfig> trackerConfig();

  /// Accepts a batch of buffered pings; bad coordinates are rejected but the
  /// batch still counts as delivered.
  Future<PingUploadResult> uploadPings(List<TrackerPing> pings);

  /// Logs a pause the member took while tracking.
  Future<void> logPause(DateTime start, DateTime end);

  Future<List<LiveMember>> live();

  Future<MemberDay> memberDay(int memberId, DateTime date);
}
