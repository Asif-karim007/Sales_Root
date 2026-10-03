import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

/// The `.hero.sm` headline and its `.lead` line that open each auth step.
class AuthIntro extends StatelessWidget {
  const AuthIntro({
    super.key,
    required this.title,
    this.lead,
    this.center = false,
  });

  final String title;
  final Widget? lead;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final lead = this.lead;
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: AppText.hero(c.ink, size: 22),
        ),
        if (lead != null) ...[
          const SizedBox(height: 6),
          DefaultTextStyle.merge(
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: AppText.lead(c.ink2),
            child: lead,
          ),
        ],
      ],
    );
  }
}
