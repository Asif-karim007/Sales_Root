// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed API client every feature's Retrofit interface is built on.

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// The signed API client every feature's Retrofit interface is built on.

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// The signed API client every feature's Retrofit interface is built on.
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'88c79ff407fff735d60cd592c6c3dc802e5b0eae';

/// For the calls made without a session: sign-in codes and token refresh.

@ProviderFor(bareDio)
final bareDioProvider = BareDioProvider._();

/// For the calls made without a session: sign-in codes and token refresh.

final class BareDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// For the calls made without a session: sign-in codes and token refresh.
  BareDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bareDioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bareDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return bareDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$bareDioHash() => r'659346f42e603860aee4f187a59f29b3a0a5b486';

@ProviderFor(sessionApi)
final sessionApiProvider = SessionApiProvider._();

final class SessionApiProvider
    extends $FunctionalProvider<SessionApi, SessionApi, SessionApi>
    with $Provider<SessionApi> {
  SessionApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionApiHash();

  @$internal
  @override
  $ProviderElement<SessionApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionApi create(Ref ref) {
    return sessionApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionApi>(value),
    );
  }
}

String _$sessionApiHash() => r'e2f0aa4d53ade19551511f098961d1532eab9915';

@ProviderFor(bareSessionApi)
final bareSessionApiProvider = BareSessionApiProvider._();

final class BareSessionApiProvider
    extends $FunctionalProvider<SessionApi, SessionApi, SessionApi>
    with $Provider<SessionApi> {
  BareSessionApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bareSessionApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bareSessionApiHash();

  @$internal
  @override
  $ProviderElement<SessionApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionApi create(Ref ref) {
    return bareSessionApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionApi>(value),
    );
  }
}

String _$bareSessionApiHash() => r'f2bfce6bfe4fe12d9f4c6b8a5d531b60f617ba40';
