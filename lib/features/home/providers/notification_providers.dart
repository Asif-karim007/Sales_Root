import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/home/data/api_notification_repository.dart';
import 'package:salesroot/features/home/data/notification_repository.dart';
import 'package:salesroot/features/home/models/app_notification.dart';
import 'package:salesroot/features/home/providers/home_providers.dart';

part 'notification_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  ref.watch(currentWorkspaceProvider.select((w) => w?.id));
  return ApiNotificationRepository(ref.watch(homeApiProvider));
}

/// The bell badge.
@riverpod
Future<int> unreadNotificationCount(Ref ref) =>
    ref.watch(notificationRepositoryProvider).unreadCount();

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  Future<Paged<AppNotification>> build() async {
    final page = await ref.watch(notificationRepositoryProvider).list();
    return Paged.first(page);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.loadingMore());
    try {
      final next = await ref
          .read(notificationRepositoryProvider)
          .list(page: current.page + 1);
      if (!ref.mounted) return;
      state = AsyncData(current.append(next));
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(current.failedMore(failure));
    }
  }

  /// Marks one read straight away; a failed call quietly restores it.
  Future<void> markRead(String id) async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData(
      before.map((n) => n.id == id ? n.copyWith(isRead: true) : n),
    );
    try {
      await ref.read(notificationRepositoryProvider).markRead([id]);
      if (!ref.mounted) return;
      ref.invalidate(unreadNotificationCountProvider);
    } on ApiFailure {
      if (!ref.mounted) return;
      state = AsyncData(before);
    }
  }

  /// Marks every loaded one read; restores the list and rethrows on failure.
  Future<void> markAllRead() async {
    final before = state.value;
    if (before == null) return;
    final ids = [
      for (final n in before.items)
        if (!n.isRead) n.id,
    ];
    if (ids.isEmpty) return;
    state = AsyncData(before.map((n) => n.copyWith(isRead: true)));
    try {
      await ref.read(notificationRepositoryProvider).markRead(ids);
      if (!ref.mounted) return;
      ref.invalidate(unreadNotificationCountProvider);
    } on ApiFailure {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }
}
