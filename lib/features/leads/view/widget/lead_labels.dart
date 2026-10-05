import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_date_utils.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_lookups.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/translations/translations.dart';
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
    LeadActivityKind.visit => l10n.leadsKindVisit,
    LeadActivityKind.note => l10n.leadsKindNote,
    LeadActivityKind.whatsapp => l10n.leadsKindWhatsapp,
    LeadActivityKind.sms => l10n.leadsKindSms,
    LeadActivityKind.email => l10n.leadsKindEmail,
    LeadActivityKind.task => l10n.leadsKindTask,
    LeadActivityKind.stageChange => l10n.leadsStage,
    LeadActivityKind.won => l10n.leadsWon,
    LeadActivityKind.lost => l10n.leadsLost,
    LeadActivityKind.system => l10n.leadsKindSystem,
  };

  IconData get icon => switch (this) {
    LeadActivityKind.call => Icons.call_outlined,
    LeadActivityKind.visit => Icons.place_outlined,
    LeadActivityKind.note => Icons.sticky_note_2_outlined,
    LeadActivityKind.whatsapp => Icons.chat_outlined,
    LeadActivityKind.sms => Icons.sms_outlined,
    LeadActivityKind.email => Icons.mail_outline_rounded,
    LeadActivityKind.task => Icons.task_alt_rounded,
    LeadActivityKind.stageChange => Icons.trending_flat_rounded,
    LeadActivityKind.won => Icons.emoji_events_outlined,
    LeadActivityKind.lost => Icons.thumb_down_alt_outlined,
    LeadActivityKind.system => Icons.info_outline_rounded,
  };
}

extension CallOutcomeView on CallOutcome {
  String label(AppLocalizations l10n) => switch (this) {
    CallOutcome.answered => l10n.leadsOutcomeAnswered,
    CallOutcome.noAnswer => l10n.leadsOutcomeNoAnswer,
    CallOutcome.busy => l10n.leadsOutcomeBusy,
    CallOutcome.switchedOff => l10n.leadsOutcomeSwitchedOff,
    CallOutcome.callback => l10n.leadsOutcomeCallback,
    CallOutcome.wrongNumber => l10n.leadsOutcomeWrongNumber,
  };

  IconData get icon => switch (this) {
    CallOutcome.answered => Icons.check_rounded,
    CallOutcome.noAnswer => Icons.phone_missed_outlined,
    CallOutcome.busy => Icons.schedule_rounded,
    CallOutcome.switchedOff => Icons.phone_disabled_outlined,
    CallOutcome.callback => Icons.phone_callback_outlined,
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
    LeadChip.stalled => l10n.leadsChipStalled,
    LeadChip.hot => l10n.leadsTempHot,
  };
}

extension LeadSourceView on LeadSource {
  String label(AppLocalizations l10n) => switch (this) {
    LeadSource.manual => l10n.leadsSourceManual,
    LeadSource.phone => l10n.leadsSourcePhone,
    LeadSource.walkIn => l10n.leadsSourceWalkIn,
    LeadSource.referral => l10n.leadsSourceReferral,
    LeadSource.facebook => l10n.leadsSourceFacebook,
    LeadSource.whatsapp => l10n.leadsKindWhatsapp,
    LeadSource.website => l10n.leadsSourceWebsite,
    LeadSource.card => l10n.leadsSourceCard,
  };
}

/// A source key as the user reads it; a key the app does not know shows as
/// the server sent it.
String? leadSourceLabel(AppLocalizations l10n, String? source) =>
    LeadSource.fromAny(source)?.label(l10n) ?? source;

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
    final kind = nextTask?.kind;
    if (at == null && kind == null) return null;
    return leadMeta([
      kind?.label(context.l10n),
      at == null ? null : leadDayTime(context, at),
    ]);
  }

  /// "Rahim Traders · 01711-234567"
  String contactLine(BuildContext context) {
    final phone = this.phone;
    final title = this.title;
    return leadMeta([
      company?.name ?? (title == leadName ? null : title),
      phone == null ? null : context.fmt.phone(phone),
    ]);
  }
}
