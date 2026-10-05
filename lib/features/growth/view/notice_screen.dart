import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/notice.dart';
import 'package:salesroot/features/growth/providers/notice_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/features/growth/view/widget/notice_readers.dart';
import 'package:salesroot/features/growth/view/widget/notice_text.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #150 A notice, who has read and acknowledged it, and reminders for the
/// rest.
class NoticeScreen extends ConsumerWidget {
  const NoticeScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(noticeDetailProvider(id));
    ref.listen(noticeDetailProvider(id), (_, next) {
      final notice = next.value;
      if (notice != null) ref.read(noticeListProvider.notifier).patch(notice);
    });
    final notice = value.value;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.growthNoticeTitle,
        actions: [
          const GrowthLanguageAction(),
          if (notice != null)
            SrIconButton(
              icon: Icons.share_outlined,
              tooltip: l10n.commonShare,
              onTap: () => SharePlus.instance.share(
                ShareParams(text: '${notice.title}\n\n${notice.body}'),
              ),
            ),
          if (notice != null && notice.canDelete)
            SrIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: l10n.commonDelete,
              onTap: () => _delete(context, ref),
            ),
        ],
      ),
      body: SrAsyncView(
        value: value,
        onRetry: () => ref.invalidate(noticeDetailProvider(id)),
        onUpgrade: () => context.push(Routes.planUsage),
        loading: (_) => const SrSkeletonList(count: 4, cards: true),
        data: (context, notice) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            _NoticeCard(notice: notice),
            if (notice.canEdit) ...[
              const SizedBox(height: 12),
              NoticeReaders(notice: notice),
            ],
          ],
        ),
      ),
      footer: notice != null && notice.needsMyAck
          ? SrButton(
              label: l10n.growthNoticeAcknowledgeAction,
              icon: Icons.check_rounded,
              expand: true,
              onPressed: () => _acknowledge(context, ref),
            )
          : null,
    );
  }

  Future<void> _acknowledge(BuildContext context, WidgetRef ref) async {
    final notice = await runGrowthAction(
      context,
      ref.read(noticeDetailProvider(id).notifier).acknowledge(),
    );
    if (notice == null || !context.mounted) return;
    showSrSuccess(context, context.l10n.growthNoticeAcknowledged);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSrConfirm(
      context,
      title: l10n.growthNoticeDeleteTitle,
      message: l10n.growthNoticeDeleteBody,
      confirmLabel: l10n.commonDelete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final done = await runGrowthTask(
      context,
      ref.read(noticeDetailProvider(id).notifier).delete(),
    );
    if (!done || !context.mounted) return;
    showSrInfo(context, l10n.growthNoticeDeleted);
    context.pop();
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final pinUntil = notice.pinUntil;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notice.title, style: AppText.sectionTitle(c.ink, size: 17)),
          const SizedBox(height: 2),
          Text(
            noticeMeta(context, notice, withTime: true),
            style: AppText.meta(c.ink2),
          ),
          const SizedBox(height: 10),
          Text(notice.body, style: AppText.body(c.ink, size: 14)),
          if (notice.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final file in notice.attachments)
                  SrTag(
                    file.name,
                    icon: file.photo
                        ? Icons.image_outlined
                        : Icons.attach_file_rounded,
                  ),
              ],
            ),
          ],
          if (notice.pinned && pinUntil != null) ...[
            const SizedBox(height: 10),
            SrTag(
              l10n.growthNoticePinnedUntil(fmt.dayMonth(pinUntil)),
              icon: Icons.push_pin_outlined,
              tone: SrTone.gold,
            ),
          ],
        ],
      ),
    );
  }
}
