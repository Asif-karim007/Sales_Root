import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The prototype's `.pricecard`: a tappable option, outlined in accent when
/// [selected].
class PlanOptionCard extends StatelessWidget {
  const PlanOptionCard({
    super.key,
    required this.selected,
    required this.child,
    this.onTap,
  });

  final bool selected;
  final Widget child;

  /// Null shows the card dimmed and not tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final onTap = this.onTap;
    return Opacity(
      opacity: onTap == null && !selected ? 0.55 : 1,
      child: Material(
        color: selected ? c.tint : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
          side: BorderSide(
            color: selected ? c.accent : c.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Title, price and a muted line, stacked, for the small option cards.
class OptionCardBody extends StatelessWidget {
  const OptionCardBody({
    super.key,
    required this.title,
    required this.price,
    required this.note,
  });

  final String title;
  final Widget price;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.rowTitle(c.ink)),
        const SizedBox(height: 4),
        price,
        const SizedBox(height: 2),
        Text(note, style: AppText.meta(c.ink2, size: 12)),
      ],
    );
  }
}

/// − count + for seats.
class SeatStepper extends StatelessWidget {
  const SeatStepper({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    required this.min,
  });

  final int value;
  final String label;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Row(
      children: [
        SrIconButton(
          icon: Icons.remove_rounded,
          color: value > min ? null : c.ink3,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.metric(c.ink, size: 20),
          ),
        ),
        SrIconButton(
          icon: Icons.add_rounded,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}
