import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/translations/translations.dart';

/// The round AI button (`.aibtn`) floating above the tab bar.
class AiGuideButton extends StatelessWidget {
  const AiGuideButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Tooltip(
      message: context.l10n.homeAiGuide,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: c.floatShadow,
        ),
        child: Material(
          color: c.deep,
          shape: CircleBorder(side: BorderSide(color: c.surface, width: 2)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(Routes.aiGuide),
            child: SizedBox.square(
              dimension: 52,
              child: Icon(Icons.auto_awesome_rounded, color: c.gold, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// The AI hint card (`.aihint`): a tip from the guide; a tap opens it.
class AiHintCard extends StatelessWidget {
  const AiHintCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final shape = BorderRadius.circular(SrMetrics.radiusCard);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.tint, c.surface],
          ),
          borderRadius: shape,
          border: Border.all(color: c.line),
        ),
        child: InkWell(
          borderRadius: shape,
          onTap: () => context.push(Routes.aiGuide),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: c.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(message, style: AppText.lead(c.ink, size: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
