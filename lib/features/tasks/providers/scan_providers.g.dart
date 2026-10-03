// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Gemini when the build carries a key, the fake reader otherwise.

@ProviderFor(cardScanRepository)
final cardScanRepositoryProvider = CardScanRepositoryProvider._();

/// Gemini when the build carries a key, the fake reader otherwise.

final class CardScanRepositoryProvider
    extends
        $FunctionalProvider<
          CardScanRepository,
          CardScanRepository,
          CardScanRepository
        >
    with $Provider<CardScanRepository> {
  /// Gemini when the build carries a key, the fake reader otherwise.
  CardScanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardScanRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardScanRepositoryHash();

  @$internal
  @override
  $ProviderElement<CardScanRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CardScanRepository create(Ref ref) {
    return cardScanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CardScanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CardScanRepository>(value),
    );
  }
}

String _$cardScanRepositoryHash() =>
    r'f01a5ba8abc8b72741016145887259909eb99553';

/// The scan in progress, shared by the capture, review, lead and QR screens.

@ProviderFor(ScanSessionNotifier)
final scanSessionProvider = ScanSessionNotifierProvider._();

/// The scan in progress, shared by the capture, review, lead and QR screens.
final class ScanSessionNotifierProvider
    extends $AsyncNotifierProvider<ScanSessionNotifier, ScanCapture?> {
  /// The scan in progress, shared by the capture, review, lead and QR screens.
  ScanSessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanSessionNotifierHash();

  @$internal
  @override
  ScanSessionNotifier create() => ScanSessionNotifier();
}

String _$scanSessionNotifierHash() =>
    r'8456533adbdacb131194fdf78d0a06fe1cfc0dc1';

/// The scan in progress, shared by the capture, review, lead and QR screens.

abstract class _$ScanSessionNotifier extends $AsyncNotifier<ScanCapture?> {
  FutureOr<ScanCapture?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ScanCapture?>, ScanCapture?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ScanCapture?>, ScanCapture?>,
              AsyncValue<ScanCapture?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The CRM company matching the scanned [name], if there is one.

@ProviderFor(scannedCompanyMatch)
final scannedCompanyMatchProvider = ScannedCompanyMatchFamily._();

/// The CRM company matching the scanned [name], if there is one.

final class ScannedCompanyMatchProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// The CRM company matching the scanned [name], if there is one.
  ScannedCompanyMatchProvider._({
    required ScannedCompanyMatchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'scannedCompanyMatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scannedCompanyMatchHash();

  @override
  String toString() {
    return r'scannedCompanyMatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as String;
    return scannedCompanyMatch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ScannedCompanyMatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scannedCompanyMatchHash() =>
    r'752fe930d7b0512adda4818d27626c2533e43a96';

/// The CRM company matching the scanned [name], if there is one.

final class ScannedCompanyMatchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, String> {
  ScannedCompanyMatchFamily._()
    : super(
        retry: null,
        name: r'scannedCompanyMatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The CRM company matching the scanned [name], if there is one.

  ScannedCompanyMatchProvider call(String name) =>
      ScannedCompanyMatchProvider._(argument: name, from: this);

  @override
  String toString() => r'scannedCompanyMatchProvider';
}
