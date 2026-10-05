import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/storage/prefs_provider.dart';
import 'package:salesroot/features/support/models/support_forms.dart';
import 'package:salesroot/features/support/data/support_repositories.dart';

part 'support_form_providers.g.dart';

/// True once the feedback is sent.
@riverpod
class FeedbackSubmitNotifier extends _$FeedbackSubmitNotifier {
  @override
  FutureOr<bool> build() => false;

  Future<void> submit(FeedbackInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(supportRepositoryProvider).sendFeedback(input);
      return true;
    });
    if (!ref.mounted) return;
    state = result;
  }
}

/// True once the enquiry is sent.
@riverpod
class EnquirySubmitNotifier extends _$EnquirySubmitNotifier {
  @override
  FutureOr<bool> build() => false;

  Future<void> submit(EnquiryInput input) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(supportRepositoryProvider).sendEnquiry(input);
      return true;
    });
    if (!ref.mounted) return;
    state = result;
  }
}

/// When the moment survey was last shown. It is shown at most once every
/// [interval], whatever the moment.
@Riverpod(keepAlive: true)
class SurveyGateNotifier extends _$SurveyGateNotifier {
  static const _key = 'support/survey_last_asked';
  static const interval = Duration(days: 14);

  @override
  DateTime? build() {
    final millis = ref.watch(sharedPreferencesProvider).getInt(_key);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  bool canAsk(DateTime now) {
    final last = state;
    return last == null || now.difference(last) >= interval;
  }

  /// Records the survey as shown and returns true, or false when it was
  /// shown too recently.
  bool tryAsk({DateTime? now}) {
    final at = now ?? DateTime.now();
    if (!canAsk(at)) return false;
    ref.read(sharedPreferencesProvider).setInt(_key, at.millisecondsSinceEpoch);
    state = at;
    return true;
  }
}

/// The face the user tapped for [moment]; null until they answer.
@riverpod
class MomentSurveyNotifier extends _$MomentSurveyNotifier {
  @override
  FutureOr<SurveyScore?> build(String moment) => null;

  Future<void> answer(SurveyScore score) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(supportRepositoryProvider).sendSurvey(moment, score);
      return score;
    });
    if (!ref.mounted) return;
    state = result;
  }
}

class SupportDiagnostics {
  const SupportDiagnostics({
    required this.appVersion,
    required this.device,
    required this.system,
  });

  final String appVersion;
  final String device;
  final String system;
}

@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();

@riverpod
Future<SupportDiagnostics> supportDiagnostics(Ref ref) async {
  final package = await ref.watch(packageInfoProvider.future);
  final plugin = DeviceInfoPlugin();
  final version = package.version;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      final android = await plugin.androidInfo;
      return SupportDiagnostics(
        appVersion: version,
        device: '${android.manufacturer} ${android.model}',
        system: 'Android ${android.version.release}',
      );
    case TargetPlatform.iOS:
      final ios = await plugin.iosInfo;
      return SupportDiagnostics(
        appVersion: version,
        device: ios.modelName,
        system: '${ios.systemName} ${ios.systemVersion}',
      );
    default:
      return SupportDiagnostics(
        appVersion: version,
        device: defaultTargetPlatform.name,
        system: defaultTargetPlatform.name,
      );
  }
}
