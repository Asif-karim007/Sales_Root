import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/field_force/data/fake_tracking_repository.dart';
import 'package:salesroot/features/field_force/data/tracking_repository.dart';
import 'package:salesroot/features/field_force/models/tracking.dart';

part 'tracking_providers.g.dart';

@Riverpod(keepAlive: true)
TrackingRepository trackingRepository(Ref ref) => FakeTrackingRepository(
  ref.watch(fakeBackendProvider),
  workspaceName: ref.watch(currentWorkspaceProvider.select((w) => w?.name)),
);

@riverpod
class TrackingSettingsNotifier extends _$TrackingSettingsNotifier {
  @override
  Future<TrackingSettings> build() =>
      ref.watch(trackingRepositoryProvider).settings();

  Future<void> save(TrackingSettings settings) async {
    final saved = await ref
        .read(trackingRepositoryProvider)
        .saveSettings(settings);
    if (!ref.mounted) return;
    state = AsyncData(saved);
  }
}

enum LiveFilter { all, checkedIn, onVisit, notTracking }

extension LiveFilterMatch on LiveFilter {
  bool matches(LiveMember member) => switch (this) {
    LiveFilter.all => true,
    LiveFilter.checkedIn => member.checkedIn,
    LiveFilter.onVisit => member.status == LiveStatus.onVisit,
    LiveFilter.notTracking => member.status == LiveStatus.notTracking,
  };
}

@riverpod
class LiveFilterNotifier extends _$LiveFilterNotifier {
  @override
  LiveFilter build() => LiveFilter.all;

  void set(LiveFilter filter) => state = filter;
}

/// Where the team is now, refreshed every minute while the map is open.
@riverpod
class LiveTeamNotifier extends _$LiveTeamNotifier {
  static const refreshEvery = Duration(minutes: 1);

  @override
  Future<List<LiveMember>> build() async {
    final timer = Timer(refreshEvery, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
    return ref.watch(trackingRepositoryProvider).live();
  }
}

@riverpod
class MemberDayDate extends _$MemberDayDate {
  @override
  DateTime build(int memberId) => AppDateUtils.dateOnly(DateTime.now());

  void set(DateTime day) => state = AppDateUtils.dateOnly(day);
}

@riverpod
Future<MemberDay> memberDay(Ref ref, int memberId) => ref
    .watch(trackingRepositoryProvider)
    .memberDay(memberId, ref.watch(memberDayDateProvider(memberId)));

@riverpod
Future<TrackingConsent> trackingConsent(Ref ref) =>
    ref.watch(trackingRepositoryProvider).consent();
