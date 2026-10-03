// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dev_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DevSettingsNotifier)
final devSettingsProvider = DevSettingsNotifierProvider._();

final class DevSettingsNotifierProvider
    extends $NotifierProvider<DevSettingsNotifier, DevSettings> {
  DevSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devSettingsNotifierHash();

  @$internal
  @override
  DevSettingsNotifier create() => DevSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DevSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DevSettings>(value),
    );
  }
}

String _$devSettingsNotifierHash() =>
    r'7daf2443515ce1009cdf6336915e774ed5ebd79c';

abstract class _$DevSettingsNotifier extends $Notifier<DevSettings> {
  DevSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DevSettings, DevSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DevSettings, DevSettings>,
              DevSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
