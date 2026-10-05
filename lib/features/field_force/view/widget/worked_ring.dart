import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Worked time against an eight-hour day, as a ring with "5:18 WORKED"
/// inside.
class WorkedRing extends StatelessWidget {
  const WorkedRing({super.key, required this.minutes, this.size = 64});

  static const dayMinutes = 8 * 60;

  final int minutes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrRing(
      value: (minutes / dayMinutes).clamp(0, 1).toDouble(),
      size: size,
      thickness: size * 0.12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.ffClockDuration(minutes),
            style: AppText.rowTitle(c.ink, size: 15),
          ),
          Text(
            context.l10n.ffWorked,
            style: AppText.caption(c.ink2, size: 8.5),
          ),
        ],
      ),
    );
  }
}
