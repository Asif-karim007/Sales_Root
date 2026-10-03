import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/home/data/fake_notification_repository.dart';
import 'package:salesroot/features/home/data/notification_repository.dart';
import 'package:salesroot/features/home/models/app_notification.dart';

part 'notification_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    FakeNotificationRepository(ref.watch(fakeBackendProvider));

/// The bell badge.
@riverpod
Future<int> unreadNotificationCount(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ref.watch(notificationRepositoryProvider).unreadCount();
}

@riverpod
class NotificationFilterNotifier extends _$NotificationFilterNotifier {
  @override
  NotificationCategory? build() => null;

  void select(NotificationCategory? category) => state = category;
}

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  Future<Paged<AppNotification>> build() async {
    final category = ref.watch(notificationFilterProvider);
    ref.watch(currentWorkspaceProvider.select((w) => w?.id));
    final page = await ref
        .watch(notificationRepositoryProvider)
        .list(category: category);
    return Paged.first(page);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(notificationRepositoryProvider)
          .list(
            category: ref.read(notificationFilterProvider),
            page: current.page + 1,
          );
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  /// Marks one read straight away; a failed call quietly restores it.
  Future<void> markRead(int id) async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData(
      before.map((n) => n.id == id ? n.copyWith(isRead: true) : n),
    );
    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
      if (!ref.mounted) return;
      ref.invalidate(unreadNotificationCountProvider);
    } on ApiFailure {
      if (!ref.mounted) return;
      state = AsyncData(before);
    }
  }

  /// Marks everything read; restores the list and rethrows on failure.
  Future<void> markAllRead() async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData(before.map((n) => n.copyWith(isRead: true)));
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      if (!ref.mounted) return;
      ref.invalidate(unreadNotificationCountProvider);
    } on ApiFailure {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }
}
