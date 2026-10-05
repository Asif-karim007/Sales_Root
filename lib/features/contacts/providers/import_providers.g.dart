// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceContactsSource)
final deviceContactsSourceProvider = DeviceContactsSourceProvider._();

final class DeviceContactsSourceProvider
    extends
        $FunctionalProvider<
          DeviceContactsSource,
          DeviceContactsSource,
          DeviceContactsSource
        >
    with $Provider<DeviceContactsSource> {
  DeviceContactsSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceContactsSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceContactsSourceHash();

  @$internal
  @override
  $ProviderElement<DeviceContactsSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceContactsSource create(Ref ref) {
    return deviceContactsSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceContactsSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceContactsSource>(value),
    );
  }
}

String _$deviceContactsSourceHash() =>
    r'b6bfb885538ad925e2bc5ac29472275d1d367643';

/// The phone book with saved numbers marked, the user's picks and the import.

@ProviderFor(ContactImportNotifier)
final contactImportProvider = ContactImportNotifierProvider._();

/// The phone book with saved numbers marked, the user's picks and the import.
final class ContactImportNotifierProvider
    extends $AsyncNotifierProvider<ContactImportNotifier, ContactImportState> {
  /// The phone book with saved numbers marked, the user's picks and the import.
  ContactImportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactImportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactImportNotifierHash();

  @$internal
  @override
  ContactImportNotifier create() => ContactImportNotifier();
}

String _$contactImportNotifierHash() =>
    r'ab9b7d9b39d84bbf065f4c10102a06e9a6bbba3c';

/// The phone book with saved numbers marked, the user's picks and the import.

abstract class _$ContactImportNotifier
    extends $AsyncNotifier<ContactImportState> {
  FutureOr<ContactImportState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ContactImportState>, ContactImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ContactImportState>, ContactImportState>,
              AsyncValue<ContactImportState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
