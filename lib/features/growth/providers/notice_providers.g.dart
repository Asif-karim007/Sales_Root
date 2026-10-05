// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(noticeRepository)
final noticeRepositoryProvider = NoticeRepositoryProvider._();

final class NoticeRepositoryProvider
    extends
        $FunctionalProvider<
          NoticeRepository,
          NoticeRepository,
          NoticeRepository
        >
    with $Provider<NoticeRepository> {
  NoticeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticeRepositoryHash();

  @$internal
  @override
  $ProviderElement<NoticeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NoticeRepository create(Ref ref) {
    return noticeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoticeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoticeRepository>(value),
    );
  }
}

String _$noticeRepositoryHash() => r'ccd3ca6360c21305ae6aa8eca8ec145544634ece';

/// The notice board (#148).

@ProviderFor(NoticeListNotifier)
final noticeListProvider = NoticeListNotifierProvider._();

/// The notice board (#148).
final class NoticeListNotifierProvider
    extends $AsyncNotifierProvider<NoticeListNotifier, Paged<Notice>> {
  /// The notice board (#148).
  NoticeListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticeListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticeListNotifierHash();

  @$internal
  @override
  NoticeListNotifier create() => NoticeListNotifier();
}

String _$noticeListNotifierHash() =>
    r'11ffc2b9a14a011a6686c70d42698e7c4df35a3c';

/// The notice board (#148).

abstract class _$NoticeListNotifier extends $AsyncNotifier<Paged<Notice>> {
  FutureOr<Paged<Notice>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Paged<Notice>>, Paged<Notice>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Paged<Notice>>, Paged<Notice>>,
              AsyncValue<Paged<Notice>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// One notice (#150). Opening it marks it read.

@ProviderFor(NoticeDetail)
final noticeDetailProvider = NoticeDetailFamily._();

/// One notice (#150). Opening it marks it read.
final class NoticeDetailProvider
    extends $AsyncNotifierProvider<NoticeDetail, Notice> {
  /// One notice (#150). Opening it marks it read.
  NoticeDetailProvider._({
    required NoticeDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'noticeDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noticeDetailHash();

  @override
  String toString() {
    return r'noticeDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NoticeDetail create() => NoticeDetail();

  @override
  bool operator ==(Object other) {
    return other is NoticeDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noticeDetailHash() => r'a1d7531bd0cdb2a83acfce8c61e1e06e9688c3ba';

/// One notice (#150). Opening it marks it read.

final class NoticeDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          NoticeDetail,
          AsyncValue<Notice>,
          Notice,
          FutureOr<Notice>,
          String
        > {
  NoticeDetailFamily._()
    : super(
        retry: null,
        name: r'noticeDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One notice (#150). Opening it marks it read.

  NoticeDetailProvider call(String id) =>
      NoticeDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'noticeDetailProvider';
}

/// One notice (#150). Opening it marks it read.

abstract class _$NoticeDetail extends $AsyncNotifier<Notice> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<Notice> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Notice>, Notice>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Notice>, Notice>,
              AsyncValue<Notice>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(noticeAudienceCounts)
final noticeAudienceCountsProvider = NoticeAudienceCountsProvider._();

final class NoticeAudienceCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<NoticeAudience, int>>,
          Map<NoticeAudience, int>,
          FutureOr<Map<NoticeAudience, int>>
        >
    with
        $FutureModifier<Map<NoticeAudience, int>>,
        $FutureProvider<Map<NoticeAudience, int>> {
  NoticeAudienceCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticeAudienceCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticeAudienceCountsHash();

  @$internal
  @override
  $FutureProviderElement<Map<NoticeAudience, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<NoticeAudience, int>> create(Ref ref) {
    return noticeAudienceCounts(ref);
  }
}

String _$noticeAudienceCountsHash() =>
    r'0c6fe709b7b74f309ae7dd7976d0ade867780e0f';

/// Publishing a notice (#149).

@ProviderFor(NoticeSubmit)
final noticeSubmitProvider = NoticeSubmitProvider._();

/// Publishing a notice (#149).
final class NoticeSubmitProvider
    extends $NotifierProvider<NoticeSubmit, AsyncValue<Notice?>> {
  /// Publishing a notice (#149).
  NoticeSubmitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticeSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticeSubmitHash();

  @$internal
  @override
  NoticeSubmit create() => NoticeSubmit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Notice?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Notice?>>(value),
    );
  }
}

String _$noticeSubmitHash() => r'778b6ceb1d63ce34b839f0dafc16e5493e182ecd';

/// Publishing a notice (#149).

abstract class _$NoticeSubmit extends $Notifier<AsyncValue<Notice?>> {
  AsyncValue<Notice?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Notice?>, AsyncValue<Notice?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Notice?>, AsyncValue<Notice?>>,
              AsyncValue<Notice?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
