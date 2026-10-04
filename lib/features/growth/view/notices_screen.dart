import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/growth/models/notice.dart';
import 'package:salesroot/features/growth/providers/notice_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/notice_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #148 The notice board.
class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAdd = ref.watch(moduleAccessProvider(AppModule.notice)).canAdd;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthNoticesTitle,
        actions: [
          const GrowthLanguageAction(),
          if (canAdd)
            SrIconButton(
              icon: Icons.add_rounded,
              tooltip: l10n.growthNoticeNew,
              onTap: () => context.push(Routes.noticeNew),
            ),
        ],
      ),
      body: SrAsyncView(
        value: ref.watch(noticeListProvider),
        onRetry: () => ref.invalidate(noticeListProvider),
        onUpgrade: () => context.push(Routes.planUsage),
        data: (context, paged) => GrowthPagedList<Notice>(
          paged: paged,
          onLoadMore: () => ref.read(noticeListProvider.notifier).loadMore(),
          onRefresh: () => ref.read(noticeListProvider.notifier).refresh(),
          empty: SrEmptyState(
            icon: Icons.campaign_outlined,
            title: l10n.growthNoticesEmpty,
            message: l10n.growthNoticesEmptyBody,
            actionLabel: canAdd ? l10n.growthNoticeNew : null,
            onAction: canAdd ? () => context.push(Routes.noticeNew) : null,
          ),
          row: (notice) => _NoticeRow(notice: notice),
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SrListRow(
      leading: SrAvatar(
        icon: notice.pinned ? Icons.push_pin_outlined : Icons.campaign_outlined,
        tone: notice.needsMyAck
            ? SrAvatarTone.gold
            : notice.myState == NoticeState.unread
            ? SrAvatarTone.accent
            : SrAvatarTone.neutral,
      ),
      title: notice.title,
      subtitle: [
        noticeMeta(context, notice),
        if (notice.requiresAck) l10n.growthNoticeAckShort,
      ].join(' · '),
      trailing: NoticeStateTag(notice: notice),
      onTap: () => context.push(Routes.noticeFor(notice.id)),
    );
  }
}
