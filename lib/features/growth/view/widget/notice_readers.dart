import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/growth/models/notice.dart';
import 'package:salesroot/features/growth/providers/notice_providers.dart';
import 'package:salesroot/features/growth/view/widget/growth_common.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Read and acknowledgement counts, and who still has to see the notice.
class NoticeReaders extends ConsumerStatefulWidget {
  const NoticeReaders({super.key, required this.notice});

  final Notice notice;

  @override
  ConsumerState<NoticeReaders> createState() => _NoticeReadersState();
}

class _NoticeReadersState extends ConsumerState<NoticeReaders> {
  RecipientFilter _filter = RecipientFilter.notRead;

  Notice get _notice => widget.notice;

  bool _matches(NoticeRecipient r) => switch (_filter) {
    RecipientFilter.notRead => !r.hasRead,
    RecipientFilter.read => r.hasRead,
    RecipientFilter.acknowledged => r.hasAcknowledged,
  };

  /// Who a reminder still helps: they haven't read it, or it needs an
  /// acknowledgement they haven't given.
  bool _remindable(NoticeRecipient r) =>
      !r.hasRead || (_notice.requiresAck && !r.hasAcknowledged);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filters = [
      RecipientFilter.notRead,
      RecipientFilter.read,
      if (_notice.requiresAck) RecipientFilter.acknowledged,
    ];
    final shown = _notice.recipients.where(_matches).toList();
    final pending = _notice.recipients.where(_remindable).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Stats(notice: _notice),
        const SizedBox(height: 12),
        SrChipRow(
          padding: EdgeInsets.zero,
          index: filters.indexOf(_filter).clamp(0, filters.length - 1),
          onChanged: (i) => setState(() => _filter = filters[i]),
          chips: [
            for (final f in filters)
              SrChipItem(
                switch (f) {
                  RecipientFilter.notRead => l10n.growthNoticeNotRead,
                  RecipientFilter.read => l10n.growthNoticeRead,
                  RecipientFilter.acknowledged => l10n.growthNoticeAcked,
                },
                count: switch (f) {
                  RecipientFilter.notRead => _notice.unreadCount,
                  RecipientFilter.read => _notice.readCount,
                  RecipientFilter.acknowledged => _notice.ackCount,
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          SrEmptyState(
            icon: Icons.done_all_rounded,
            title: _filter == RecipientFilter.notRead
                ? l10n.growthNoticeEveryoneRead
                : l10n.growthNoticeNobodyYet,
          )
        else
          SrRowGroup(
            seeAllLabel: pending.length > 1 ? l10n.growthNoticeRemindAll : null,
            onSeeAll: pending.length > 1
                ? () => _remind([for (final r in pending) r.memberId])
                : null,
            title: _filter == RecipientFilter.notRead
                ? l10n.growthNoticeWaitingOn(context.fmt.number(shown.length))
                : null,
            rows: [
              for (final recipient in shown)
                _RecipientRow(
                  recipient: recipient,
                  onRemind: _remindable(recipient)
                      ? () => _remind([recipient.memberId])
                      : null,
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _remind(List<int> ids) async {
    final count = await runGrowthAction(
      context,
      ref.read(noticeDetailProvider(_notice.id).notifier).remind(ids),
    );
    if (count == null || !mounted) return;
    showSrSuccess(
      context,
      context.l10n.growthNoticeReminded(context.fmt.number(count)),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final total = notice.audienceCount;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.growthNoticeReadOf(
                    fmt.number(notice.readCount),
                    fmt.number(total),
                  ),
                  style: AppText.rowTitle(c.ink),
                ),
              ),
              if (notice.requiresAck)
                Text(
                  l10n.growthNoticeAckCount(fmt.number(notice.ackCount)),
                  style: AppText.meta(c.ink2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SrProgressBar(value: total == 0 ? 0 : notice.readCount / total),
        ],
      ),
    );
  }
}

class _RecipientRow extends StatelessWidget {
  const _RecipientRow({required this.recipient, required this.onRemind});

  final NoticeRecipient recipient;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final onRemind = this.onRemind;
    final acknowledged = recipient.acknowledgedAt;
    final read = recipient.readAt;
    final reminded = recipient.remindedAt;
    final subtitle = acknowledged != null
        ? l10n.growthNoticeAckedAt(fmt.dayTime(acknowledged))
        : read != null
        ? l10n.growthNoticeReadAt(fmt.dayTime(read))
        : reminded != null
        ? l10n.growthNoticeRemindedAt(fmt.dayTime(reminded))
        : switch (recipient.presence) {
            Presence.onLeave => l10n.growthMemberOnLeave,
            Presence.offline => l10n.growthNoticeOffline(
              fmt.number(recipient.lastSeenDays),
            ),
            Presence.active when recipient.lastSeenDays == 0 =>
              l10n.growthNoticeActiveToday,
            Presence.active when recipient.lastSeenDays == 1 =>
              l10n.growthNoticeActiveYesterday,
            Presence.active => l10n.growthNoticeActiveDays(
              fmt.number(recipient.lastSeenDays),
            ),
          };
    return SrListRow(
      leading: SrAvatar(name: recipient.name),
      title: recipient.nameOf(fmt.isBangla),
      subtitle: subtitle,
      trailing: onRemind == null
          ? null
          : SrButton(
              label: l10n.growthNoticeRemind,
              size: SrButtonSize.sm,
              variant: SrButtonVariant.secondary,
              onPressed: onRemind,
            ),
    );
  }
}
