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

  /// Owner only.
  Future<TrackingSettings> saveSettings(TrackingSettings settings);

  /// This member's tracking schedule.
  Future<TrackerConfig> trackerConfig();

  Future<PingUploadResult> uploadPings(List<TrackerPing> pings);

  /// Where each member the user may see is today.
  Future<List<LiveMember>> live();

  Future<MemberDay> memberDay(String memberId, DateTime date);
}
