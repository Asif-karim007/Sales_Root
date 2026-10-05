import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/home/models/app_notification.dart';
import 'package:salesroot/features/home/providers/notification_providers.dart';
import 'package:salesroot/features/home/view/widget/failure_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #19: notifications grouped by day; a tap marks one read and opens what it
/// is about.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(notificationsProvider);
    final isBangla = ref.watch(appLocaleProvider) == bangla;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.homeNotificationsTitle,
        actions: [
          SrLanguageToggle(
            isBangla: isBangla,
            onChanged: (bn) =>
                ref.read(appLocaleProvider.notifier).set(bn ? bangla : english),
          ),
          const _MarkAllRead(),
        ],
      ),
      body: SrAsyncView<Paged<AppNotification>>(
        value: list,
        onRetry: () => ref.invalidate(notificationsProvider),
        isEmpty: (page) => page.isEmpty,
        empty: (_) => _Refreshable(
          child: SrEmptyState(
            icon: Icons.notifications_none_rounded,
            title: l10n.homeNotificationsEmpty,
            message: l10n.homeNotificationsEmptyBody,
          ),
        ),
        data: (context, page) => _NotificationList(page: page),
      ),
    );
  }
}

class _MarkAllRead extends ConsumerWidget {
  const _MarkAllRead();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(
      notificationsProvider.select(
        (list) => list.value?.items.any((n) => !n.isRead) ?? false,
      ),
    );
    return SrButton(
      label: context.l10n.homeMarkAllRead,
      variant: SrButtonVariant.ghost,
      size: SrButtonSize.sm,
      onPressed: hasUnread ? () => _markAll(context, ref) : null,
    );
  }

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await ref.read(notificationsProvider.notifier).markAllRead();
      if (!context.mounted) return;
      showSrSuccess(context, l10n.homeMarkedAllRead);
    } on ApiFailure catch (failure) {
      if (!context.mounted) return;
      showSrError(context, failureText(context, failure));
    }
  }
}

class _Refreshable extends ConsumerWidget {
  const _Refreshable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    return RefreshIndicator(
      color: c.accent,
      backgroundColor: c.surface,
      onRefresh: () => _refresh(ref),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

Future<void> _refresh(WidgetRef ref) async {
  ref.invalidate(unreadNotificationCountProvider);
  try {
    ref.invalidate(notificationsProvider);
    await ref.read(notificationsProvider.future);
  } on ApiFailure {
    return;
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.page});

  final Paged<AppNotification> page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final days = _byDay(page.items);
    final failure = page.loadMoreError;
    return RefreshIndicator(
      color: c.accent,
      backgroundColor: c.surface,
      onRefresh: () => _refresh(ref),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) {
            ref.read(notificationsProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            8,
            SrMetrics.gutter,
            24,
          ),
          itemCount: days.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            if (i < days.length) return _DayGroup(items: days[i]);
            if (failure != null) {
              return SrErrorState(
                error: failure,
                compact: true,
                onRetry: () =>
                    ref.read(notificationsProvider.notifier).loadMore(),
              );
            }
            if (page.hasMore) {
              return const SrSkeletonList(
                count: 2,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  List<List<AppNotification>> _byDay(List<AppNotification> items) {
    final days = <List<AppNotification>>[];
    for (final item in items) {
      final last = days.isEmpty ? null : days.last.first.createdAt;
      if (last != null && AppDateUtils.isSameDay(last, item.createdAt)) {
        days.last.add(item);
      } else {
        days.add([item]);
      }
    }
    return days;
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.items});

  final List<AppNotification> items;

  @override
  Widget build(BuildContext context) {
    return SrRowGroup(
      title: _dayLabel(context, items.first.createdAt),
      dividerIndent: 66,
      rows: [for (final item in items) _NotificationRow(item: item)],
    );
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final l10n = context.l10n;
    final today = DateTime.now();
    if (AppDateUtils.isSameDay(day, today)) return l10n.commonToday;
    final yesterday = today.subtract(const Duration(days: 1));
    if (AppDateUtils.isSameDay(day, yesterday)) return l10n.commonYesterday;
    return context.fmt.weekdayDate(day);
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final route = item.route;
    final body = item.body?.of(fmt.isBangla);
    final (icon, tone) = _look(item.kind);
    return SrListRow(
      title: item.title.of(fmt.isBangla),
      subtitle: [fmt.time(item.createdAt), ?body].join(' · '),
      leading: SrAvatar(icon: icon, tone: tone),
      trailing: item.isRead
          ? null
          : item.kind == NotificationKind.newLead
          ? SrTag(l10n.homeTagNew, tone: SrTone.ok)
          : const SrBadge(tone: SrTone.accent),
      chevron: route != null,
      onTap: () {
        if (!item.isRead) {
          unawaited(ref.read(notificationsProvider.notifier).markRead(item.id));
        }
        if (route != null) context.push(route);
      },
    );
  }

  (IconData, SrAvatarTone) _look(NotificationKind kind) => switch (kind) {
    NotificationKind.reminder => (Icons.alarm_rounded, SrAvatarTone.accent),
    NotificationKind.taskDue => (
      Icons.event_note_outlined,
      SrAvatarTone.accent,
    ),
    NotificationKind.newLead => (
      Icons.person_add_alt_1_outlined,
      SrAvatarTone.gold,
    ),
    NotificationKind.mention => (
      Icons.alternate_email_rounded,
      SrAvatarTone.neutral,
    ),
    NotificationKind.assigned => (
      Icons.assignment_ind_outlined,
      SrAvatarTone.neutral,
    ),
    NotificationKind.approval => (Icons.verified_outlined, SrAvatarTone.accent),
    NotificationKind.notice => (Icons.campaign_outlined, SrAvatarTone.neutral),
    NotificationKind.billing => (
      Icons.workspace_premium_outlined,
      SrAvatarTone.gold,
    ),
  };
}
