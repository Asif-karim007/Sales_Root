import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/field_force/data/fake_field_data.dart';
import 'package:salesroot/features/field_force/data/tracking_repository.dart';
import 'package:salesroot/features/field_force/data/visit_fixtures.dart';
import 'package:salesroot/features/field_force/models/tracker_config.dart';
import 'package:salesroot/features/field_force/models/tracker_ping.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';

class FakeTrackingRepository implements TrackingRepository {
  FakeTrackingRepository(this._backend, {this.workspaceName})
    : _data = FakeFieldData(_backend);

  final FakeBackend _backend;
  final FakeFieldData _data;
  final String? workspaceName;

  @override
  Future<TrackingSettings> settings() =>
      _backend.run('Tracking settings', () => _data.settings);

  @override
  Future<TrackingSettings> saveSettings(TrackingSettings settings) =>
      _backend.run(
        'Tracking settings save',
        () {
          if (settings.workDays.isEmpty) {
            throw const ApiFailure(
              400,
              'Pick at least one duty day.',
              fieldErrors: {'WorkDays': 'Pick at least one duty day.'},
            );
          }
          return TrackingSettings.fromJson(
            _data.settingsTable.update(1, settings.toJson()),
          );
        },
        module: AppModule.liveTracking,
        right: ModuleRight.edit,
      );

  @override
  Future<TrackingConsent> consent() =>
      _backend.run('Tracking consent', () => _consentOf(_backend.meId));

  @override
  Future<TrackingConsent> setConsent({required bool given}) =>
      _backend.run('Tracking consent save', () {
        final row = {
          'Id': _backend.meId,
          'Given': given,
          'At': jsonUtc(DateTime.now()),
        };
        if (_data.consents.byIdOrNull(_backend.meId) == null) {
          _data.consents.insert(row);
        } else {
          _data.consents.update(_backend.meId, row);
        }
        return _consentOf(_backend.meId);
      });

  @override
  Future<TrackerConfig> trackerConfig() => _backend.run('Tracker config', () {
    final settings = _data.settings;
    return TrackerConfig.fromJson({
      'IsEnabled': settings.liveTracking,
      'StartTime': settings.offOutsideDuty ? settings.dutyStart : null,
      'EndTime': settings.offOutsideDuty ? settings.dutyEnd : null,
      'DurationInMinute': settings.heartbeatMinutes,
      'WorkDays': settings.offOutsideDuty ? settings.workDays : const <int>[],
    });
  });

  @override
  Future<PingUploadResult> uploadPings(List<TrackerPing> pings) =>
      _backend.run('Tracker pings ×${pings.length}', () {
        var rejected = 0;
        for (final ping in pings) {
          if (!TrackerPing.isValidCoordinate(ping.latitude, ping.longitude)) {
            rejected++;
            continue;
          }
          _data.pings.insert({
            'EmployeeId': _backend.meId,
            ...ping.toApiJson(),
          }, first: false);
        }
        return PingUploadResult(
          accepted: pings.length - rejected,
          rejected: rejected,
        );
      });

  @override
  Future<void> logPause(DateTime start, DateTime end) =>
      _backend.run('Tracking pause', () {
        if (!_data.settings.allowPauses) {
          throw const ApiFailure(403, 'Pauses are turned off for your team.');
        }
        _data.pauses.insert({
          'EmployeeId': _backend.meId,
          'Start': jsonUtc(start),
          'End': jsonUtc(end),
        });
      });

  @override
  Future<List<LiveMember>> live() => _backend.run('Tracking live', () {
    final now = DateTime.now();
    return [
      for (final member in fieldMembers(_backend.graph))
        if (member.id != _backend.meId)
          LiveMember.fromJson(_data.live(member, now)),
    ];
  }, module: AppModule.liveTracking);

  @override
  Future<MemberDay> memberDay(int memberId, DateTime date) => _backend.run(
    'Tracking member $memberId day',
    () {
      final member = _backend.graph.members
          .where((m) => m.id == memberId)
          .firstOrNull;
      if (member == null) throw const ApiFailure(404, 'Member not found');
      final now = DateTime.now();
      final day = AppDateUtils.dateOnly(date);
      return MemberDay.fromJson({
        ...memberJson(member),
        'MemberId': member.id,
        'Date': jsonUtc(day),
        'Points': _data.trail(member.id, day, now),
        'Events': _data.events(member.id, day, now),
        'HeartbeatMinutes': _data.settings.heartbeatMinutes,
      });
    },
    module: memberId == SeedGraph.meId ? null : AppModule.liveTracking,
  );

  TrackingConsent _consentOf(int memberId) {
    final row = _data.consents.byIdOrNull(memberId);
    return TrackingConsent.fromJson({
      'Given': row?['Given'] ?? false,
      'At': row?['At'],
      'WorkspaceName': workspaceName,
    });
  }
}
