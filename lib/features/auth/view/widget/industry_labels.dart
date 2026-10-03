import 'package:flutter/material.dart';

import 'package:salesroot/features/auth/models/sign_up_profile.dart';
import 'package:salesroot/l10n/l10n.dart';

extension IndustryTemplateLabels on IndustryTemplate {
  String label(AppLocalizations l10n) => switch (this) {
    IndustryTemplate.trading => l10n.authIndustryTrading,
    IndustryTemplate.realEstate => l10n.authIndustryRealEstate,
    IndustryTemplate.education => l10n.authIndustryEducation,
    IndustryTemplate.itServices => l10n.authIndustryIt,
    IndustryTemplate.manufacturing => l10n.authIndustryManufacturing,
    IndustryTemplate.general => l10n.authIndustryGeneral,
  };

  IconData get icon => switch (this) {
    IndustryTemplate.trading => Icons.shopping_cart_outlined,
    IndustryTemplate.realEstate => Icons.home_work_outlined,
    IndustryTemplate.education => Icons.school_outlined,
    IndustryTemplate.itServices => Icons.cloud_outlined,
    IndustryTemplate.manufacturing => Icons.precision_manufacturing_outlined,
    IndustryTemplate.general => Icons.star_outline_rounded,
  };
}
