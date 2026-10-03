import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Joins the parts of a meta line with the prototype's middle dot.
String leadMeta(Iterable<String?> parts) =>
    parts.whereType<String>().where((p) => p.trim().isNotEmpty).join(' · ');

/// "Today 11:00", "Tomorrow 10:00", "Yesterday 9:05" or "2 Oct 11:00".
String leadDayTime(BuildContext context, DateTime date) {
  final fmt = context.fmt;
  final l10n = context.l10n;
  final today = AppDateUtils.dateOnly(DateTime.now());
  final days = AppDateUtils.dateOnly(date).difference(today).inDays;
  final day = switch (days) {
    0 => l10n.commonToday,
    1 => l10n.commonTomorrow,
    -1 => l10n.commonYesterday,
    _ => fmt.dayMonth(date),
  };
  return '$day ${fmt.time(date)}';
}

extension LeadActivityKindView on LeadActivityKind {
  String label(AppLocalizations l10n) => switch (this) {
    LeadActivityKind.call => l10n.leadsKindCall,
    LeadActivityKind.meeting => l10n.leadsKindMeeting,
    LeadActivityKind.visit => l10n.leadsKindVisit,
    LeadActivityKind.note => l10n.leadsKindNote,
    LeadActivityKind.whatsapp => l10n.leadsKindWhatsapp,
    LeadActivityKind.sms => l10n.leadsKindSms,
    LeadActivityKind.email => l10n.leadsKindEmail,
    LeadActivityKind.quotation => l10n.leadsKindQuotation,
    LeadActivityKind.stageChange => l10n.leadsStage,
    LeadActivityKind.task => l10n.leadsKindTask,
    LeadActivityKind.created => l10n.leadsTimelineCreated,
  };

  IconData get icon => switch (this) {
    LeadActivityKind.call => Icons.call_outlined,
    LeadActivityKind.meeting => Icons.groups_outlined,
    LeadActivityKind.visit => Icons.place_outlined,
    LeadActivityKind.note => Icons.sticky_note_2_outlined,
    LeadActivityKind.whatsapp => Icons.chat_outlined,
    LeadActivityKind.sms => Icons.sms_outlined,
    LeadActivityKind.email => Icons.mail_outline_rounded,
    LeadActivityKind.quotation => Icons.request_quote_outlined,
    LeadActivityKind.stageChange => Icons.trending_flat_rounded,
    LeadActivityKind.task => Icons.task_alt_rounded,
    LeadActivityKind.created => Icons.add_circle_outline_rounded,
  };
}

extension CallOutcomeView on CallOutcome {
  String label(AppLocalizations l10n) => switch (this) {
    CallOutcome.answered => l10n.leadsOutcomeAnswered,
    CallOutcome.noAnswer => l10n.leadsOutcomeNoAnswer,
    CallOutcome.busy => l10n.leadsOutcomeBusy,
    CallOutcome.wrongNumber => l10n.leadsOutcomeWrongNumber,
  };

  IconData get icon => switch (this) {
    CallOutcome.answered => Icons.check_rounded,
    CallOutcome.noAnswer => Icons.phone_missed_outlined,
    CallOutcome.busy => Icons.schedule_rounded,
    CallOutcome.wrongNumber => Icons.close_rounded,
  };
}

extension LeadTemperatureView on LeadTemperature {
  String label(AppLocalizations l10n) => switch (this) {
    LeadTemperature.hot => l10n.leadsTempHot,
    LeadTemperature.warm => l10n.leadsTempWarm,
    LeadTemperature.cold => l10n.leadsTempCold,
  };

  SrTone get tone => switch (this) {
    LeadTemperature.hot => SrTone.warn,
    LeadTemperature.warm => SrTone.gold,
    LeadTemperature.cold => SrTone.info,
  };
}

extension LeadChipView on LeadChip {
  String label(AppLocalizations l10n) => switch (this) {
    LeadChip.all => l10n.commonAll,
    LeadChip.dueToday => l10n.leadsChipDueToday,
    LeadChip.overdue => l10n.leadsChipOverdue,
    LeadChip.stalled => l10n.leadsChipStalled,
    LeadChip.hot => l10n.leadsTempHot,
  };

  SrTone get tone => this == LeadChip.overdue ? SrTone.err : SrTone.neutral;
}

extension LeadCreatedWithinView on LeadCreatedWithin {
  String label(AppLocalizations l10n) => switch (this) {
    LeadCreatedWithin.today => l10n.commonToday,
    LeadCreatedWithin.week => l10n.leadsCreatedWeek,
    LeadCreatedWithin.month => l10n.leadsCreatedMonth,
    LeadCreatedWithin.quarter => l10n.leadsCreatedQuarter,
  };
}

extension LeadView on Lead {
  String stageName(bool bangla) => stage?.name.of(bangla) ?? '';

  SrTone get stageTone => isWon
      ? SrTone.ok
      : isLost
      ? SrTone.err
      : SrTone.accent;

  /// "Call · today 11:00", or null when nothing is planned.
  String? nextLine(BuildContext context) {
    final at = nextTaskAt;
    final kind = nextTaskType;
    if (at == null && kind == null) return null;
    return leadMeta([
      kind?.label(context.l10n),
      at == null ? null : leadDayTime(context, at),
    ]);
  }

  /// "Md. Karim · 01711-234567"
  String contactLine(BuildContext context) => leadMeta([
    primaryContact?.name,
    phone == null ? null : context.fmt.phone(phone ?? ''),
  ]);
}
