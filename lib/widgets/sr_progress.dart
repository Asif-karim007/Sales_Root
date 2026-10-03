import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

/// The prototype's `.prog`: a 6px track filled to [value] (0–1).
class SrProgressBar extends StatelessWidget {
  const SrProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        width: double.infinity,
        height: height,
        color: c.track,
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: ColoredBox(color: color ?? c.accent),
        ),
      ),
    );
  }
}

/// The prototype's `.segs`: [segments] equal bars with the first [filled]
/// coloured, and optional [labels] under them with [current] in bold.
class SrSegmentBar extends StatelessWidget {
  const SrSegmentBar({
    super.key,
    required this.segments,
    required this.filled,
    this.labels = const [],
    this.current,
    this.color,
  });

  final int segments;
  final int filled;
  final List<String> labels;
  final int? current;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < segments; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < filled ? color ?? c.accent : c.track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: i == current
                        ? AppText.caption(c.ink, size: 11)
                        : AppText.meta(c.ink3, size: 11),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// The prototype's `.ring`: a circular gauge filled to [value] (0–1) with
/// [label] (or the percentage) in the middle.
class SrRing extends StatelessWidget {
  const SrRing({
    super.key,
    required this.value,
    this.size = 46,
    this.thickness = 8,
    this.color,
    this.label,
    this.child,
  });

  final double value;
  final double size;
  final double thickness;
  final Color? color;
  final String? label;

  /// Replaces the centre text.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final center =
        child ??
        Text(
          label ?? context.fmt.percent(value.clamp(0.0, 1.0) * 100),
          style: AppText.caption(c.ink, size: size * 0.24),
          maxLines: 1,
        );

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0.0, 1.0),
          thickness: thickness,
          color: color ?? c.accent,
          track: c.track,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.thickness,
    required this.color,
    required this.track,
  });

  final double value;
  final double thickness;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - thickness) / 2;
    final centre = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawCircle(centre, radius, paint..color = track);
    if (value <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.thickness != thickness ||
      old.color != color ||
      old.track != track;
}

/// The prototype's `.steps`: numbered discs joined by lines; steps up to
/// [current] (0-based) are filled.
class SrSteps extends StatelessWidget {
  const SrSteps({super.key, required this.steps, required this.current});

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i <= current ? c.accent : c.line,
              ),
            ),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: i <= current ? c.accent : c.line,
              shape: BoxShape.circle,
            ),
            child: Text(
              fmt.number(i + 1),
              style: AppText.caption(
                i <= current ? c.onAccent : c.ink2,
                size: 11,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            flex: 4,
            child: Text(
              steps[i],
              style: i == current
                  ? AppText.caption(c.ink, size: 12)
                  : AppText.meta(c.ink3, size: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
