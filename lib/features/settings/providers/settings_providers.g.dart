// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'35209041a6175cddd57b9b23135f9b97290a4e13';

@ProviderFor(configRepository)
final configRepositoryProvider = ConfigRepositoryProvider._();

final class ConfigRepositoryProvider
    extends
        $FunctionalProvider<
          ConfigRepository,
          ConfigRepository,
          ConfigRepository
        >
    with $Provider<ConfigRepository> {
  ConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configRepositoryHash();

  @$internal
  @override
  $ProviderElement<ConfigRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConfigRepository create(Ref ref) {
    return configRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfigRepository>(value),
    );
  }
}

String _$configRepositoryHash() => r'799d2c667048d8215a26eebd48407b70fd3e140d';

/// `2.0.0 (12)`.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// `2.0.0 (12)`.

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// `2.0.0 (12)`.
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'932ac63565bd3ca1e04c539e2b3a3a1a2a4b5de6';

@ProviderFor(DevicePrefsNotifier)
final devicePrefsProvider = DevicePrefsNotifierProvider._();

final class DevicePrefsNotifierProvider
    extends $NotifierProvider<DevicePrefsNotifier, DevicePrefs> {
  DevicePrefsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devicePrefsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devicePrefsNotifierHash();

  @$internal
  @override
  DevicePrefsNotifier create() => DevicePrefsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DevicePrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DevicePrefs>(value),
    );
  }
}

String _$devicePrefsNotifierHash() =>
    r'caa97bb6e9917d6bee686ef3a7409ac5854e7b2c';

abstract class _$DevicePrefsNotifier extends $Notifier<DevicePrefs> {
  DevicePrefs build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DevicePrefs, DevicePrefs>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DevicePrefs, DevicePrefs>,
              DevicePrefs,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(NotificationPrefsNotifier)
final notificationPrefsProvider = NotificationPrefsNotifierProvider._();

final class NotificationPrefsNotifierProvider
    extends
        $AsyncNotifierProvider<NotificationPrefsNotifier, NotificationPrefs> {
  NotificationPrefsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPrefsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPrefsNotifierHash();

  @$internal
  @override
  NotificationPrefsNotifier create() => NotificationPrefsNotifier();
}

String _$notificationPrefsNotifierHash() =>
    r'b9b157a3f71b9815a7975e1dcefe45393daf480c';

abstract class _$NotificationPrefsNotifier
    extends $AsyncNotifier<NotificationPrefs> {
  FutureOr<NotificationPrefs> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<NotificationPrefs>, NotificationPrefs>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NotificationPrefs>, NotificationPrefs>,
              AsyncValue<NotificationPrefs>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(DevicesNotifier)
final devicesProvider = DevicesNotifierProvider._();

final class DevicesNotifierProvider
    extends $AsyncNotifierProvider<DevicesNotifier, List<DeviceSession>> {
  DevicesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devicesNotifierHash();

  @$internal
  @override
  DevicesNotifier create() => DevicesNotifier();
}

String _$devicesNotifierHash() => r'220537f568c21dc9fe5b0511525ca2ea72efa776';

abstract class _$DevicesNotifier extends $AsyncNotifier<List<DeviceSession>> {
  FutureOr<List<DeviceSession>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<DeviceSession>>, List<DeviceSession>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<DeviceSession>>, List<DeviceSession>>,
              AsyncValue<List<DeviceSession>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LoginHistoryNotifier)
final loginHistoryProvider = LoginHistoryNotifierProvider._();

final class LoginHistoryNotifierProvider
    extends $AsyncNotifierProvider<LoginHistoryNotifier, Paged<LoginEvent>> {
  LoginHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginHistoryNotifierHash();

  @$internal
  @override
  LoginHistoryNotifier create() => LoginHistoryNotifier();
}

String _$loginHistoryNotifierHash() =>
    r'd38e1fbd528c00008dd1ec9c160123d981bbf8b8';

abstract class _$LoginHistoryNotifier
    extends $AsyncNotifier<Paged<LoginEvent>> {
  FutureOr<Paged<LoginEvent>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Paged<LoginEvent>>, Paged<LoginEvent>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<LoginEvent>>, Paged<LoginEvent>>,
              AsyncValue<Paged<LoginEvent>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(PipelinesNotifier)
final pipelinesProvider = PipelinesNotifierProvider._();

final class PipelinesNotifierProvider
    extends $AsyncNotifierProvider<PipelinesNotifier, List<Pipeline>> {
  PipelinesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pipelinesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pipelinesNotifierHash();

  @$internal
  @override
  PipelinesNotifier create() => PipelinesNotifier();
}

String _$pipelinesNotifierHash() => r'2f477e1a1ff2ca99f25b5004ac0b77e808812ca1';

abstract class _$PipelinesNotifier extends $AsyncNotifier<List<Pipeline>> {
  FutureOr<List<Pipeline>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Pipeline>>, List<Pipeline>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Pipeline>>, List<Pipeline>>,
              AsyncValue<List<Pipeline>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FormFieldsNotifier)
final formFieldsProvider = FormFieldsNotifierFamily._();

final class FormFieldsNotifierProvider
    extends $AsyncNotifierProvider<FormFieldsNotifier, List<FormFieldConfig>> {
  FormFieldsNotifierProvider._({
    required FormFieldsNotifierFamily super.from,
    required FormKind super.argument,
  }) : super(
         retry: null,
         name: r'formFieldsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$formFieldsNotifierHash();

  @override
  String toString() {
    return r'formFieldsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FormFieldsNotifier create() => FormFieldsNotifier();

  @override
  bool operator ==(Object other) {
    return other is FormFieldsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$formFieldsNotifierHash() =>
    r'ae2032b77882b1e7a87a2b63b968d1a0ca866e6e';

final class FormFieldsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          FormFieldsNotifier,
          AsyncValue<List<FormFieldConfig>>,
          List<FormFieldConfig>,
          FutureOr<List<FormFieldConfig>>,
          FormKind
        > {
  FormFieldsNotifierFamily._()
    : super(
        retry: null,
        name: r'formFieldsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FormFieldsNotifierProvider call(FormKind form) =>
      FormFieldsNotifierProvider._(argument: form, from: this);

  @override
  String toString() => r'formFieldsProvider';
}

abstract class _$FormFieldsNotifier
    extends $AsyncNotifier<List<FormFieldConfig>> {
  late final _$args = ref.$arg as FormKind;
  FormKind get form => _$args;

  FutureOr<List<FormFieldConfig>> build(FormKind form);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<FormFieldConfig>>, List<FormFieldConfig>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FormFieldConfig>>,
                List<FormFieldConfig>
              >,
              AsyncValue<List<FormFieldConfig>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
