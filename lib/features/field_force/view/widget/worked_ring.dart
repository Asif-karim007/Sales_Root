import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/field_force/view/widget/ff_format.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Worked time against the shift, as a ring with "5:18 WORKED" inside.
class WorkedRing extends StatelessWidget {
  const WorkedRing({
    super.key,
    required this.minutes,
    required this.shiftMinutes,
    this.size = 64,
  });

  final int minutes;
  final int shiftMinutes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return SrRing(
      value: shiftMinutes <= 0 ? 0 : minutes / shiftMinutes,
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
