import 'package:flutter/widgets.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/team/models/member.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

extension TeamLabels on BuildContext {
  bool get isBangla => fmt.isBangla;

  String name(LocalizedName name) => name.of(isBangla);

  /// What an avatar shows initials of: a Bangla name gives its first letter
  /// only, as `SrAvatar.initialsOf` would join two letters into a word.
  String avatarName(String name) => name.contains(RegExp('[\u0980-\u09FF]'))
      ? name.trim().split(RegExp(r'\s+')).first
      : name;

  /// `+880 1714 938 268`, in the locale's digits.
  String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 13 || !digits.startsWith('880')) return fmt.phone(raw);
    return fmt.phone(
      '+880 ${digits.substring(3, 7)} ${digits.substring(7, 10)} '
      '${digits.substring(10)}',
    );
  }

  /// `3.2`, or `10` for a whole number.
  String gigabytes(double value) => value == value.roundToDouble()
      ? fmt.number(value)
      : fmt.number(value, decimals: 1);

  String roleLabel(MemberRole role) => switch (role) {
    MemberRole.owner => l10n.teamRoleOwner,
    MemberRole.teamLead => l10n.teamRoleTeamLead,
    MemberRole.executive => l10n.teamRoleMember,
    MemberRole.finance => l10n.teamRoleFinance,
  };

  String roleDescription(MemberRole role) => switch (role) {
    MemberRole.owner => l10n.teamRoleOwnerAbout,
    MemberRole.teamLead => l10n.teamRoleTeamLeadAbout,
    MemberRole.executive => l10n.teamRoleMemberAbout,
    MemberRole.finance => l10n.teamRoleFinanceAbout,
  };

  String levelLabel(ExperienceLevel level) => switch (level) {
    ExperienceLevel.easy => l10n.teamLevelEasy,
    ExperienceLevel.standard => l10n.teamLevelStandard,
    ExperienceLevel.advanced => l10n.teamLevelAdvanced,
  };

  /// "Team lead · 6 reports", "Member · Easy".
  String memberSubtitle(Member member) {
    final parts = [
      roleLabel(member.role),
      if (member.isTeamLead && member.reportCount > 0)
        l10n.teamReports(member.reportCount, fmt.number(member.reportCount))
      else if (!member.isOwner)
        levelLabel(member.level),
    ];
    return parts.join(' · ');
  }

  /// The status tag a member row shows, or null when nothing stands out.
  SrTag? memberStatusTag(
    Member member, {
    bool always = false,
  }) => switch (member.status) {
    MemberStatus.active =>
      always || member.isOwner
          ? SrTag(l10n.teamStatusActive, tone: SrTone.ok)
          : null,
    MemberStatus.notStarted => always ? SrTag(l10n.teamStatusNotStarted) : null,
    MemberStatus.onLeave => SrTag(l10n.teamStatusOnLeave, tone: SrTone.info),
    MemberStatus.deactivated => SrTag(
      l10n.teamStatusDeactivated,
      tone: SrTone.err,
    ),
  };

  /// "1.2 MB", "320 KB", "1.1 GB".
  String fileSize(int bytes) {
    const kb = 1000;
    if (bytes >= kb * kb * kb) {
      return '${fmt.number(bytes / (kb * kb * kb), decimals: 1)} GB';
    }
    if (bytes >= kb * kb) {
      return '${fmt.number(bytes / (kb * kb), decimals: 1)} MB';
    }
    return '${fmt.number((bytes / kb).ceil())} KB';
  }
}
