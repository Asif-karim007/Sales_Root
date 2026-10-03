// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationRepository)
final notificationRepositoryProvider = NotificationRepositoryProvider._();

final class NotificationRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationRepository,
          NotificationRepository,
          NotificationRepository
        >
    with $Provider<NotificationRepository> {
  NotificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationRepository create(Ref ref) {
    return notificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationRepository>(value),
    );
  }
}

String _$notificationRepositoryHash() =>
    r'ffed73d97e5838ff993e2f8867e9b671807999b9';

/// The bell badge.

@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = UnreadNotificationCountProvider._();

/// The bell badge.

final class UnreadNotificationCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// The bell badge.
  UnreadNotificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return unreadNotificationCount(ref);
  }
}

String _$unreadNotificationCountHash() =>
    r'df36117e624042597216095c645ea7a91972a5af';

@ProviderFor(NotificationFilterNotifier)
final notificationFilterProvider = NotificationFilterNotifierProvider._();

final class NotificationFilterNotifierProvider
    extends
        $NotifierProvider<NotificationFilterNotifier, NotificationCategory?> {
  NotificationFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationFilterNotifierHash();

  @$internal
  @override
  NotificationFilterNotifier create() => NotificationFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationCategory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationCategory?>(value),
    );
  }
}

String _$notificationFilterNotifierHash() =>
    r'6da02a45744f481c83d9c001c46b50c09e4b358f';

abstract class _$NotificationFilterNotifier
    extends $Notifier<NotificationCategory?> {
  NotificationCategory? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NotificationCategory?, NotificationCategory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotificationCategory?, NotificationCategory?>,
              NotificationCategory?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(NotificationsNotifier)
final notificationsProvider = NotificationsNotifierProvider._();

final class NotificationsNotifierProvider
    extends
        $AsyncNotifierProvider<NotificationsNotifier, Paged<AppNotification>> {
  NotificationsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsNotifierHash();

  @$internal
  @override
  NotificationsNotifier create() => NotificationsNotifier();
}

String _$notificationsNotifierHash() =>
    r'30d074843590abf31eac9c1fefa63c7d5c1a1773';

abstract class _$NotificationsNotifier
    extends $AsyncNotifier<Paged<AppNotification>> {
  FutureOr<Paged<AppNotification>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Paged<AppNotification>>, Paged<AppNotification>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Paged<AppNotification>>,
                Paged<AppNotification>
              >,
              AsyncValue<Paged<AppNotification>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
