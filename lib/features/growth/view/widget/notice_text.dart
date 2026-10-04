import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/growth/models/notice.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// "Admin · today · everyone", with the time when [withTime].
String noticeMeta(
  BuildContext context,
  Notice notice, {
  bool withTime = false,
}) {
  final l10n = context.l10n;
  final fmt = context.fmt;
  final author = notice.authorRole == AuthorRole.teamLead
      ? notice.authorOf(fmt.isBangla).split(' ').first
      : notice.authorRole.label(l10n);
  final posted = notice.postedAt;
  return [
    author,
    if (posted != null) withTime ? fmt.dayTime(posted) : _day(context, posted),
    notice.audience.label(l10n),
  ].join(' · ');
}

String _day(BuildContext context, DateTime date) {
  final l10n = context.l10n;
  final now = DateTime.now();
  if (AppDateUtils.isSameDay(date, now)) return l10n.commonToday;
  if (AppDateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
    return l10n.commonYesterday;
  }
  return context.fmt.dayMonth(date);
}

class NoticeStateTag extends StatelessWidget {
  const NoticeStateTag({super.key, required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (notice.needsMyAck) {
      return SrTag(l10n.growthNoticeAcknowledge, tone: SrTone.warn);
    }
    return switch (notice.myState) {
      NoticeState.unread => SrTag(l10n.growthInboxNewTag, tone: SrTone.accent),
      NoticeState.read => SrTag(l10n.growthNoticeReadTag, tone: SrTone.ok),
      NoticeState.acknowledged => SrTag(
        l10n.growthNoticeAcknowledgedTag,
        tone: SrTone.ok,
      ),
    };
  }
}
