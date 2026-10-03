import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';

/// The sprout logo and the app name, as on the splash and the PIN screen.
class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, this.onDark = false, this.size = 22});

  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SproutMark(size: size * 1.25, color: onDark ? c.gold : c.accent),
        SizedBox(width: size * 0.35),
        Text(
          context.l10n.appName,
          style: AppText.style(
            size: size,
            weight: FontWeight.w700,
            color: onDark ? c.onDeep : c.ink,
          ),
        ),
      ],
    );
  }
}

class SproutMark extends StatelessWidget {
  const SproutMark({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _SproutPainter(color));
}

class _SproutPainter extends CustomPainter {
  const _SproutPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawLine(const Offset(12, 21), const Offset(12, 13), paint)
      ..drawPath(
        Path()
          ..moveTo(12, 13)
          ..cubicTo(12, 9, 15, 7, 19, 7)
          ..cubicTo(19, 11, 16, 13, 12, 13)
          ..close(),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(12, 13)
          ..cubicTo(12, 10, 10, 8, 7, 8)
          ..cubicTo(7, 11, 9, 13, 12, 13)
          ..close(),
        paint,
      );
  }

  @override
  bool shouldRepaint(_SproutPainter old) => old.color != color;
}

/// The prototype's `.roots` drawing behind the deep-green screens.
class RootsBackdrop extends StatelessWidget {
  const RootsBackdrop({super.key, this.height = 300});

  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return IgnorePointer(
      child: Opacity(
        opacity: 0.6,
        child: CustomPaint(
          size: Size.fromHeight(height),
          painter: _RootsPainter(line: c.onDeepMuted, leaf: c.gold),
        ),
      ),
    );
  }
}

class _RootsPainter extends CustomPainter {
  const _RootsPainter({required this.line, required this.leaf});

  final Color line;
  final Color leaf;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 390, size.height / 300);
    final stroke = Paint()
      ..color = line.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final roots = Path()
      ..moveTo(195, 0)
      ..lineTo(195, 180)
      ..moveTo(195, 60)
      ..relativeCubicTo(-40, 30, -80, 40, -150, 60)
      ..moveTo(195, 60)
      ..relativeCubicTo(40, 30, 90, 40, 160, 70)
      ..moveTo(195, 120)
      ..relativeCubicTo(-30, 30, -60, 60, -120, 80)
      ..moveTo(195, 120)
      ..relativeCubicTo(30, 30, 70, 60, 130, 90)
      ..moveTo(120, 110)
      ..relativeCubicTo(-20, 20, -50, 30, -90, 40)
      ..moveTo(270, 130)
      ..relativeCubicTo(20, 20, 60, 30, 100, 40);
    canvas
      ..drawPath(roots, stroke)
      ..drawPath(
        Path()
          ..moveTo(195, 60)
          ..relativeCubicTo(0, -18, 12, -30, 32, -30)
          ..relativeCubicTo(0, 18, -12, 30, -32, 30)
          ..close(),
        Paint()..color = leaf,
      )
      ..drawPath(
        Path()
          ..moveTo(195, 60)
          ..relativeCubicTo(0, -14, -10, -24, -26, -24)
          ..relativeCubicTo(0, 14, 10, 24, 26, 24)
          ..close(),
        Paint()..color = line,
      );
  }

  @override
  bool shouldRepaint(_RootsPainter old) => old.line != line || old.leaf != leaf;
}
