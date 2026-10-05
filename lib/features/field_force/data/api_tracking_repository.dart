import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/data/field_api.dart';
import 'package:salesroot/features/field_force/data/tracking_repository.dart';
import 'package:salesroot/features/field_force/models/attendance.dart';
import 'package:salesroot/features/field_force/models/tracker_config.dart';
import 'package:salesroot/features/field_force/models/tracker_ping.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';
import 'package:salesroot/features/field_force/models/visit.dart';

/// Live tracking over `/locations`, today's `/attendance` rows and
/// `/team/map`.
class ApiTrackingRepository implements TrackingRepository {
  ApiTrackingRepository(this._api);

  static const _dayVisits = 100;

  final FieldApi _api;

  @override
  Future<TrackingSettings> settings() async {
    final json = await apiRequest('Field settings', _api.today);
    return TrackingSettings.fromJson(jsonMap(jsonMap(json)['settings']));
  }

  @override
  Future<TrackingSettings> saveSettings(TrackingSettings settings) async {
    await apiRequest(
      'Field settings save',
      () => _api.saveSettings(settings.toJson()),
    );
    return this.settings();
  }

  @override
  Future<TrackerConfig> trackerConfig() async {
    final settings = await this.settings();
    return TrackerConfig(
      isEnabled: settings.liveTracking,
      durationInMinute: settings.liveTracking
          ? settings.heartbeatMinutes
          : TrackerConfig.defaultDurationInMinute,
    );
  }

  @override
  Future<PingUploadResult> uploadPings(List<TrackerPing> pings) async {
    final json = await apiRequest(
      'Locations ×${pings.length}',
      () => _api.locations({
        'points': [for (final ping in pings) ping.toApiJson()],
      }),
    );
    final stored = jsonInt(jsonMap(json)['stored']) ?? pings.length;
    return PingUploadResult(
      accepted: stored,
      rejected: (pings.length - stored).clamp(0, pings.length),
    );
  }

  @override
  Future<List<LiveMember>> live() async {
    final json = await apiRequest('Team today', () => _api.attendance({}));
    return json is List
        ? [
            for (final row in json)
              if (row is Map<String, dynamic>) LiveMember.fromJson(row),
          ]
        : const [];
  }

  @override
  Future<MemberDay> memberDay(String memberId, DateTime date) async {
    final day = AppDateUtils.toApiDateOnly(date);
    final attendance = apiRequest(
      'Member $memberId attendance',
      () => _api.attendance({'day': day, 'membershipId': memberId}),
    );
    final visits = apiRequest(
      'Member $memberId visits',
      () => _api.visits({
        'membershipId': memberId,
        'from': day,
        'to': day,
        'limit': _dayVisits,
      }),
    );
    final trail = apiRequest(
      'Member $memberId trail',
      () => _api.teamMap({'membershipId': memberId, 'day': day}),
    );
    await Future.wait([attendance, visits, trail]);
    final rows = await attendance;
    final row = rows is List
        ? rows.whereType<Map<String, dynamic>>().firstOrNull
        : null;
    final dayVisits = jsonList(jsonMap(await visits)['items'], Visit.fromJson);
    return MemberDay(
      memberId: memberId,
      name: row?['name'] as String? ?? dayVisits.firstOrNull?.memberName ?? '',
      date: AppDateUtils.dateOnly(date),
      points: TrailPoint.listOf(await trail),
      events: dayEvents(
        row == null ? null : AttendanceLog.fromJson(row),
        dayVisits,
      ),
    );
  }
}
