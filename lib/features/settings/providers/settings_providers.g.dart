// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

/// The notification choices for the current workspace, kept on the phone.

@ProviderFor(NotificationPrefsNotifier)
final notificationPrefsProvider = NotificationPrefsNotifierProvider._();

/// The notification choices for the current workspace, kept on the phone.
final class NotificationPrefsNotifierProvider
    extends $NotifierProvider<NotificationPrefsNotifier, NotificationPrefs> {
  /// The notification choices for the current workspace, kept on the phone.
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationPrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationPrefs>(value),
    );
  }
}

String _$notificationPrefsNotifierHash() =>
    r'0abeb37dd54f347cd83b231f4d2fb531c93a0f33';

/// The notification choices for the current workspace, kept on the phone.

abstract class _$NotificationPrefsNotifier
    extends $Notifier<NotificationPrefs> {
  NotificationPrefs build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NotificationPrefs, NotificationPrefs>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotificationPrefs, NotificationPrefs>,
              NotificationPrefs,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(devices)
final devicesProvider = DevicesProvider._();

final class DevicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DeviceSession>>,
          List<DeviceSession>,
          FutureOr<List<DeviceSession>>
        >
    with
        $FutureModifier<List<DeviceSession>>,
        $FutureProvider<List<DeviceSession>> {
  DevicesProvider._()
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
  String debugGetCreateSourceHash() => _$devicesHash();

  @$internal
  @override
  $FutureProviderElement<List<DeviceSession>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DeviceSession>> create(Ref ref) {
    return devices(ref);
  }
}

String _$devicesHash() => r'987b4afdefea84d69ce8a3dd0c55803d95c62962';

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

String _$pipelinesNotifierHash() => r'617f2d290edfe88efc98d4cee127263c7c2c9396';

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

@ProviderFor(formFields)
final formFieldsProvider = FormFieldsFamily._();

final class FormFieldsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FormFieldConfig>>,
          List<FormFieldConfig>,
          FutureOr<List<FormFieldConfig>>
        >
    with
        $FutureModifier<List<FormFieldConfig>>,
        $FutureProvider<List<FormFieldConfig>> {
  FormFieldsProvider._({
    required FormFieldsFamily super.from,
    required FormKind super.argument,
  }) : super(
         retry: null,
         name: r'formFieldsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$formFieldsHash();

  @override
  String toString() {
    return r'formFieldsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FormFieldConfig>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FormFieldConfig>> create(Ref ref) {
    final argument = this.argument as FormKind;
    return formFields(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FormFieldsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$formFieldsHash() => r'3fb1dc650eff0d316d8a7b7018cd37cd81961fd3';

final class FormFieldsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FormFieldConfig>>, FormKind> {
  FormFieldsFamily._()
    : super(
        retry: null,
        name: r'formFieldsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FormFieldsProvider call(FormKind form) =>
      FormFieldsProvider._(argument: form, from: this);

  @override
  String toString() => r'formFieldsProvider';
}
