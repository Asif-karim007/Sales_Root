import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

/// Series colours in order: accent first, then gold, the lighter green, info
/// blue, danger red, warning amber and grey.
List<Color> srChartColors(SrColors c) => [
  c.accent,
  c.gold,
  c.accent2,
  c.info,
  c.danger,
  c.warning,
  c.ink3,
];

/// One slice of a donut, one bar or one legend row. [color] defaults to the
/// accent; [dim] fades a bar, like past weeks next to recent ones.
class SrSeries {
  const SrSeries({
    required this.label,
    required this.value,
    this.color,
    this.dim = false,
  });

  final String label;
  final double value;
  final Color? color;
  final bool dim;
}

/// The prototype's `.donut`: slices on a track ring with [center] inside.
class SrDonut extends StatelessWidget {
  const SrDonut({
    super.key,
    required this.series,
    this.size = 96,
    this.thickness = 15,
    this.center,
    this.gapDegrees = 0,
    this.total,
  });

  final List<SrSeries> series;
  final double size;
  final double thickness;
  final Widget? center;
  final double gapDegrees;

  /// The value of a full ring; defaults to the sum of [series].
  final double? total;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final center = this.center;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          values: [for (final s in series) s.value],
          colors: [for (final s in series) s.color ?? c.accent],
          thickness: thickness,
          track: c.track,
          total: total,
          gapDegrees: gapDegrees,
        ),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.thickness,
    required this.track,
    required this.total,
    required this.gapDegrees,
  });

  final List<double> values;
  final List<Color> colors;
  final double thickness;
  final Color track;
  final double? total;
  final double gapDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - thickness) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final sum = values.fold<double>(0, (a, v) => a + v);
    final denominator = total ?? (sum == 0 ? 1 : sum);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    canvas.drawCircle(rect.center, radius, paint..color = track);

    var start = -math.pi / 2;
    final gap = gapDegrees * math.pi / 180;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / denominator) * math.pi * 2;
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(sweep - gap, 0),
        false,
        paint..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      !_sameList(old.values, values) ||
      !_sameList(old.colors, colors) ||
      old.thickness != thickness ||
      old.track != track ||
      old.total != total ||
      old.gapDegrees != gapDegrees;
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class SrDonutCenter extends StatelessWidget {
  const SrDonutCenter({super.key, required this.value, this.label});

  final String value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final label = this.label;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppText.metric(c.ink, size: 16)),
        if (label != null)
          Text(label, style: AppText.meta(c.ink2, size: 10), maxLines: 1),
      ],
    );
  }
}

/// The prototype's `.legend`: swatch, label and value per series.
class SrLegend extends StatelessWidget {
  const SrLegend({super.key, required this.series, this.valueOf});

  final List<SrSeries> series;

  /// Formats each value; defaults to a localized whole number.
  final String Function(SrSeries)? valueOf;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < series.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: series[i].color ?? c.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  series[i].label,
                  style: AppText.meta(c.ink, size: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valueOf?.call(series[i]) ?? fmt.number(series[i].value),
                style: AppText.rowTitle(c.ink, size: 13),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The prototype's `.bar`: a label, a track filled to `value / max`, and the
/// value on the right.
class SrBarRow extends StatelessWidget {
  const SrBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    this.valueLabel,
    this.color,
    this.labelWidth = 88,
    this.valueWidth = 60,
  });

  final String label;
  final double value;
  final double max;

  /// Defaults to the localized whole number.
  final String? valueLabel;
  final Color? color;
  final double labelWidth;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: AppText.meta(c.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              color: c.track,
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: fraction,
                heightFactor: 1,
                child: ColoredBox(color: color ?? c.accent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: valueWidth,
          child: Text(
            valueLabel ?? context.fmt.number(value),
            textAlign: TextAlign.right,
            style: AppText.rowTitle(c.ink, size: 12.5),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

/// The prototype's `.hbar`: bars scaled to the largest value, with optional
/// values on top and labels below.
class SrColumnChart extends StatelessWidget {
  const SrColumnChart({
    super.key,
    required this.series,
    this.height = 80,
    this.gap = 6,
    this.showValues = false,
    this.showLabels = true,
  });

  final List<SrSeries> series;

  /// Height of the tallest bar.
  final double height;
  final double gap;
  final bool showValues;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final max = series.fold<double>(0, (a, s) => math.max(a, s.value));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < series.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showValues) ...[
                  Text(
                    fmt.number(series[i].value),
                    style: AppText.caption(c.ink, size: 11),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  height: max <= 0 ? 0 : height * (series[i].value / max),
                  decoration: BoxDecoration(
                    color: (series[i].color ?? c.accent).withValues(
                      alpha: series[i].dim ? 0.35 : 0.85,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                if (showLabels && series[i].label.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    series[i].label,
                    textAlign: TextAlign.center,
                    style: AppText.meta(c.ink3, size: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A trend line over [values] with a soft fill and a marker on the last
/// point; [labels] spread evenly under it.
class SrLineChart extends StatelessWidget {
  const SrLineChart({
    super.key,
    required this.values,
    this.labels = const [],
    this.height = 78,
    this.gridLines = 2,
    this.color,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final int gridLines;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _LinePainter(
              values: values,
              color: color ?? c.accent,
              grid: c.line,
              gridLines: gridLines,
              markerRing: c.surface,
            ),
          ),
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in labels)
                Text(label, style: AppText.meta(c.ink3, size: 11)),
            ],
          ),
        ],
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.color,
    required this.grid,
    required this.gridLines,
    required this.markerRing,
  });

  final List<double> values;
  final Color color;
  final Color grid;
  final int gridLines;
  final Color markerRing;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const inset = 4.0;
    const topPad = 8.0;
    const bottomPad = 8.0;

    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final span = (max - min) == 0 ? 1 : (max - min);
    final plotHeight = size.height - topPad - bottomPad;
    final step = (size.width - inset * 2) / (values.length - 1);

    Offset pointAt(int i) => Offset(
      inset + step * i,
      topPad + plotHeight - ((values[i] - min) / span) * plotHeight,
    );

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var g = 1; g <= gridLines; g++) {
      final y = size.height * (g / (gridLines + 1));
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + 3, y), gridPaint);
        x += 7;
      }
    }

    final first = pointAt(0);
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 1; i < values.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }
    final last = pointAt(values.length - 1);

    final area = Path.from(path)
      ..lineTo(last.dx, size.height)
      ..lineTo(first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawCircle(last, 5, Paint()..color = markerRing);
    canvas.drawCircle(last, 3.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      !_sameList(old.values, values) ||
      old.color != color ||
      old.grid != grid ||
      old.gridLines != gridLines ||
      old.markerRing != markerRing;
}
