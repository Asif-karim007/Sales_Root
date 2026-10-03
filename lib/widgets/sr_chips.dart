import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/sr_border.dart';

enum SrTone { neutral, accent, ok, warn, err, gold, info, dark }

extension SrToneColors on SrTone {
  Color foreground(SrColors c) => switch (this) {
    SrTone.neutral => c.ink2,
    SrTone.accent => c.accent,
    SrTone.ok => c.success,
    SrTone.warn => c.warning,
    SrTone.err => c.danger,
    SrTone.gold => c.gold,
    SrTone.info => c.info,
    SrTone.dark => c.onDeep,
  };

  Color background(SrColors c) => switch (this) {
    SrTone.neutral => c.line,
    SrTone.accent => c.tint,
    SrTone.ok => c.successTint,
    SrTone.warn => c.warningTint,
    SrTone.err => c.dangerTint,
    SrTone.gold => c.goldTint,
    SrTone.info => c.infoTint,
    SrTone.dark => c.deep,
  };
}

/// The prototype's `.tag`: a small status label.
class SrTag extends StatelessWidget {
  const SrTag(
    this.label, {
    super.key,
    this.tone = SrTone.neutral,
    this.icon,
    this.dot = false,
  });

  final String label;
  final SrTone tone;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ink = tone.foreground(c);
    final icon = this.icon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background(c),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: ink),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: AppText.chip(ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tag that opens a chooser, like a lead's stage.
class SrStagePill extends StatelessWidget {
  const SrStagePill({
    super.key,
    required this.label,
    this.onTap,
    this.tone = SrTone.accent,
  });

  final String label;
  final VoidCallback? onTap;
  final SrTone tone;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ink = tone.foreground(c);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 7, 5),
        decoration: BoxDecoration(
          color: tone.background(c),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppText.chip(ink, size: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: ink),
          ],
        ),
      ),
    );
  }
}

/// A count bubble, or a plain dot when [count] is null.
class SrBadge extends StatelessWidget {
  const SrBadge({super.key, this.count, this.tone = SrTone.err});

  final int? count;
  final SrTone tone;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fill = tone == SrTone.neutral ? c.ink3 : tone.foreground(c);
    final count = this.count;

    if (count == null) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      );
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          context.fmt.digits(count > 99 ? '99+' : '$count'),
          style: AppText.caption(c.onAccent, size: 10.5),
        ),
      ),
    );
  }
}

/// The prototype's `.chip`: a pill that can be selected. [SrTone.err] gives
/// the red outline used for "Overdue".
class SrChip extends StatelessWidget {
  const SrChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.count,
    this.tone = SrTone.neutral,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;
  final SrTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = _chipText(context, label, count);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _Pill(
        text: text,
        icon: icon,
        tone: tone,
        selected: selected,
        size: _kChipTextSizes.first,
      ),
    );
  }
}

/// One entry in an [SrChipRow].
class SrChipItem {
  const SrChipItem(this.label, {this.count, this.tone = SrTone.neutral});

  final String label;
  final int? count;
  final SrTone tone;
}

const double _kChipGap = 6;
const double _kChipPadX = 11;
const double _kChipBorder = 1;
const double _kChipHeight = 30;
const double _kChipTapHeight = 40;
const List<double> _kChipTextSizes = [12, 11.5];
const Duration _kChipFade = Duration(milliseconds: 150);

String _chipText(BuildContext context, String label, int? count) =>
    count == null ? label : '$label ${context.fmt.number(count)}';

/// A single-choice filter row. The chips shrink a step to fit the width, and
/// when they still overflow the row scrolls and snaps each chip to the edge.
class SrChipRow extends StatelessWidget {
  const SrChipRow({
    super.key,
    required this.chips,
    required this.index,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
  });

  final List<SrChipItem> chips;
  final int index;
  final ValueChanged<int> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final texts = [
      for (final chip in chips) _chipText(context, chip.label, chip.count),
    ];

    return SizedBox(
      height: _kChipTapHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fit = _ChipFit.resolve(
            texts: texts,
            available: constraints.maxWidth - padding.horizontal,
            scaler: MediaQuery.textScalerOf(context),
            inherited: DefaultTextStyle.of(context).style,
          );

          Widget chipAt(int i) => _RowChip(
            text: texts[i],
            tone: chips[i].tone,
            size: fit.size,
            active: i == index,
            onTap: () => onChanged(i),
          );

          if (fit.fits) {
            return Padding(
              padding: padding,
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: _kChipGap),
                    chipAt(i),
                  ],
                ],
              ),
            );
          }

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: _SnapPhysics(offsets: fit.offsets),
              padding: padding,
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: _kChipGap),
              itemBuilder: (context, i) => chipAt(i),
            ),
          );
        },
      ),
    );
  }
}

class _ChipFit {
  const _ChipFit({
    required this.fits,
    required this.size,
    this.offsets = const [],
  });

  final bool fits;
  final double size;
  final List<double> offsets;

  static _ChipFit resolve({
    required List<String> texts,
    required double available,
    required TextScaler scaler,
    required TextStyle inherited,
  }) {
    final gaps = texts.isEmpty ? 0.0 : (texts.length - 1) * _kChipGap;
    var widths = const <double>[];

    for (final size in _kChipTextSizes) {
      widths = [
        for (final text in texts) _pillWidth(text, size, scaler, inherited),
      ];
      final total = widths.fold<double>(0, (sum, width) => sum + width) + gaps;
      if (total <= available) return _ChipFit(fits: true, size: size);
    }

    final offsets = <double>[];
    var offset = 0.0;
    for (final width in widths) {
      offsets.add(offset);
      offset += width + _kChipGap;
    }
    return _ChipFit(fits: false, size: _kChipTextSizes.last, offsets: offsets);
  }

  static double _pillWidth(
    String text,
    double size,
    TextScaler scaler,
    TextStyle inherited,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: inherited.merge(
          AppText.style(size: size, weight: FontWeight.w600, height: 1.2),
        ),
      ),
      maxLines: 1,
      textScaler: scaler,
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width + _kChipPadX * 2 + _kChipBorder * 2;
  }
}

class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics({required this.offsets, super.parent});

  final List<double> offsets;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(offsets: offsets, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (offsets.isEmpty ||
        (velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final estimate = position.pixels + velocity * 0.15;
    var target = offsets.first;
    for (final offset in offsets) {
      if ((offset - estimate).abs() < (target - estimate).abs()) {
        target = offset;
      }
    }
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);

    final tolerance = toleranceFor(position);
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}

class _RowChip extends StatelessWidget {
  const _RowChip({
    required this.text,
    required this.tone,
    required this.size,
    required this.active,
    required this.onTap,
  });

  final String text;
  final SrTone tone;
  final double size;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _kChipTapHeight,
        child: Center(
          child: _Pill(text: text, tone: tone, selected: active, size: size),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.tone,
    required this.selected,
    required this.size,
    this.icon,
  });

  final String text;
  final SrTone tone;
  final bool selected;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final alert = tone != SrTone.neutral && !selected;
    final ink = selected
        ? c.onAccent
        : alert
        ? tone.foreground(c)
        : c.ink2;
    final rim = selected
        ? c.accent
        : alert
        ? tone.foreground(c)
        : c.line;
    final icon = this.icon;

    return AnimatedContainer(
      duration: _kChipFade,
      height: _kChipHeight,
      padding: const EdgeInsets.symmetric(horizontal: _kChipPadX),
      decoration: BoxDecoration(
        color: selected ? c.accent : c.surface,
        borderRadius: BorderRadius.circular(999),
        border: SrBorder.all(color: rim, width: _kChipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size + 3, color: ink),
            const SizedBox(width: 5),
          ],
          Text(text, style: AppText.chip(ink, size: size), softWrap: false),
        ],
      ),
    );
  }
}
