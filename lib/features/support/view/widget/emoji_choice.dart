import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A round face button, ringed in the accent colour when [selected].
class EmojiChoice extends StatelessWidget {
  const EmojiChoice({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.size = 52,
  });

  final String emoji;

  /// Read out by screen readers.
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.tint : c.surface,
            shape: BoxShape.circle,
            border: SrBorder.all(
              color: selected ? c.accent : c.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: ExcludeSemantics(
            child: Text(
              emoji,
              style: AppText.style(size: size * 0.42, weight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
  }
}
