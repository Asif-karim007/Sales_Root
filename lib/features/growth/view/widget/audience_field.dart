import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/features/growth/models/campaign.dart';
import 'package:salesroot/features/growth/view/widget/growth_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// "To: overdue customers · 19 people", picked from the server's segments.
class AudienceField extends StatelessWidget {
  const AudienceField({
    super.key,
    required this.audiences,
    required this.segment,
    required this.reach,
    required this.onChanged,
  });

  final List<Audience> audiences;
  final AudienceSegment segment;
  final int reach;
  final ValueChanged<AudienceSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrDropdownField(
      label: l10n.growthCampaignTo,
      icon: Icons.group_outlined,
      value: l10n.growthCampaignPeople(fmt.number(reach), segment.label(l10n)),
      onTap: () async {
        final picked = await showSrSheet<Audience>(
          context: context,
          builder: (_) => SrOptionSheet<Audience>(
            title: l10n.growthCampaignTo,
            options: audiences,
            labelOf: (a) => a.segment.label(l10n),
            subtitleOf: (a) => l10n.growthCampaignCount(fmt.number(a.count)),
            isSelected: (a) => a.segment == segment,
          ),
        );
        if (picked != null) onChanged(picked.segment);
      },
    );
  }
}
