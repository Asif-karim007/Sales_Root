import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/translations/translations.dart';

/// The prototype's `.steps` for referral milestones: reached ones filled,
/// with what each one pays underneath.
class MilestoneTrack extends StatelessWidget {
  const MilestoneTrack({
    super.key,
    required this.milestones,
    required this.paid,
  });

  final List<Milestone> milestones;
  final int paid;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < milestones.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: milestones[i].paid <= paid ? c.accent : c.line,
                  ),
                ),
              _Dot(
                milestone: milestones[i],
                reached: milestones[i].paid <= paid,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < milestones.length; i++)
              Expanded(
                child: Text(
                  _label(context, milestones[i]),
                  textAlign: i == 0
                      ? TextAlign.start
                      : i == milestones.length - 1
                      ? TextAlign.end
                      : TextAlign.center,
                  style: AppText.meta(c.ink2, size: 11.5),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _label(BuildContext context, Milestone milestone) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final count = fmt.number(milestone.paid);
    if (milestone.reward > 0) {
      return l10n.billingMilestoneReward(count, fmt.money(milestone.reward));
    }
    if (milestone.freeMonths > 0) {
      return l10n.billingMilestoneFree(count, fmt.number(milestone.freeMonths));
    }
    return l10n.billingMilestoneFirst;
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.milestone, required this.reached});

  final Milestone milestone;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: reached ? c.accent : c.track,
        shape: BoxShape.circle,
      ),
      child: milestone.paid == 1
          ? Icon(
              Icons.check_rounded,
              size: 16,
              color: reached ? c.onAccent : c.ink3,
            )
          : Text(
              context.fmt.number(milestone.paid),
              style: AppText.caption(reached ? c.onAccent : c.ink2),
            ),
    );
  }
}
