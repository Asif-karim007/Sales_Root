import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/sr_border.dart';

enum SrCardTone { plain, tint, gold, dashed }

class SrCard extends StatelessWidget {
  const SrCard({
    super.key,
    required this.child,
    this.tone = SrCardTone.plain,
    this.padding = const EdgeInsets.all(14),
    this.radius = SrMetrics.radiusCard,
    this.onTap,
  });

  final Widget child;
  final SrCardTone tone;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final shape = BorderRadius.circular(radius);

    final decoration = switch (tone) {
      SrCardTone.plain => BoxDecoration(
        color: c.surface,
        borderRadius: shape,
        border: SrBorder.all(color: c.line),
        boxShadow: c.cardShadow,
      ),
      SrCardTone.tint => BoxDecoration(color: c.tint, borderRadius: shape),
      SrCardTone.gold => BoxDecoration(color: c.goldTint, borderRadius: shape),
      SrCardTone.dashed => BoxDecoration(borderRadius: shape),
    };

    Widget card = onTap == null
        ? Container(padding: padding, decoration: decoration, child: child)
        : Material(
            color: Colors.transparent,
            child: Ink(
              decoration: decoration,
              child: InkWell(
                onTap: onTap,
                borderRadius: shape,
                child: Padding(padding: padding, child: child),
              ),
            ),
          );

    if (tone == SrCardTone.dashed) {
      card = CustomPaint(
        foregroundPainter: _DashedOutline(color: c.line, radius: radius),
        child: card,
      );
    }
    return card;
  }
}

class _DashedOutline extends CustomPainter {
  const _DashedOutline({required this.color, required this.radius});

  static const double _dash = 5;
  static const double _gap = 4;

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          Radius.circular(radius),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) =>
      old.color != color || old.radius != radius;
}
