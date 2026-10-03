// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracker_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live tracking for the signed-in member: the state machine, the
/// foreground service on Android, the in-app runner on iOS, and the flush of
/// buffered pings to the tracking repository.

@ProviderFor(TrackerNotifier)
final trackerProvider = TrackerNotifierProvider._();

/// Live tracking for the signed-in member: the state machine, the
/// foreground service on Android, the in-app runner on iOS, and the flush of
/// buffered pings to the tracking repository.
final class TrackerNotifierProvider
    extends $AsyncNotifierProvider<TrackerNotifier, TrackerStatus> {
  /// Live tracking for the signed-in member: the state machine, the
  /// foreground service on Android, the in-app runner on iOS, and the flush of
  /// buffered pings to the tracking repository.
  TrackerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackerNotifierHash();

  @$internal
  @override
  TrackerNotifier create() => TrackerNotifier();
}

String _$trackerNotifierHash() => r'69ed54550c9a7d23cc0b0f7a3a60381e83b5c130';

/// Live tracking for the signed-in member: the state machine, the
/// foreground service on Android, the in-app runner on iOS, and the flush of
/// buffered pings to the tracking repository.

abstract class _$TrackerNotifier extends $AsyncNotifier<TrackerStatus> {
  FutureOr<TrackerStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TrackerStatus>, TrackerStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TrackerStatus>, TrackerStatus>,
              AsyncValue<TrackerStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// This phone's maker and model, for the battery tips.

@ProviderFor(phoneInfo)
final phoneInfoProvider = PhoneInfoProvider._();

/// This phone's maker and model, for the battery tips.

final class PhoneInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PhoneInfo>,
          PhoneInfo,
          FutureOr<PhoneInfo>
        >
    with $FutureModifier<PhoneInfo>, $FutureProvider<PhoneInfo> {
  /// This phone's maker and model, for the battery tips.
  PhoneInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneInfoHash();

  @$internal
  @override
  $FutureProviderElement<PhoneInfo> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PhoneInfo> create(Ref ref) {
    return phoneInfo(ref);
  }
}

String _$phoneInfoHash() => r'194a34342b45e4caa888f0a0ab9a99c88b6ac8a8';
