import 'package:flutter/material.dart';

import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/translations/translations.dart';

extension ExperienceLevelLabels on ExperienceLevel {
  String label(AppLocalizations l10n) => switch (this) {
    ExperienceLevel.easy => l10n.settingsLevelEasy,
    ExperienceLevel.standard => l10n.settingsLevelStandard,
    ExperienceLevel.advanced => l10n.settingsLevelAdvanced,
  };

  String description(AppLocalizations l10n) => switch (this) {
    ExperienceLevel.easy => l10n.settingsLevelEasyHint,
    ExperienceLevel.standard => l10n.settingsLevelStandardHint,
    ExperienceLevel.advanced => l10n.settingsLevelAdvancedHint,
  };

  IconData get icon => switch (this) {
    ExperienceLevel.easy => Icons.spa_outlined,
    ExperienceLevel.standard => Icons.insights_rounded,
    ExperienceLevel.advanced => Icons.construction_rounded,
  };
}
