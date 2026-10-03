import 'package:flutter/material.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/sr_border.dart';

/// One option in an [SrSegmented].
class SrSegment {
  const SrSegment(this.label, {this.count});

  final String label;
  final int? count;
}

/// The prototype's `.segc`: equal segments in a sunken track, the selected
/// one filled with the primary gradient.
class SrSegmented extends StatelessWidget {
  const SrSegmented({
    super.key,
    required this.segments,
    required this.index,
    required this.onChanged,
    this.compact = false,
  });

  final List<SrSegment> segments;
  final int index;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: BorderRadius.circular(SrMetrics.radiusButton),
        border: SrBorder.all(color: c.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: _Segment(
                segment: segments[i],
                active: i == index,
                compact: compact,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  final SrSegment segment;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ink = active ? c.onAccent : c.ink2;
    final count = segment.count;
    final label = count == null
        ? segment.label
        : '${segment.label} ${context.fmt.number(count)}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8, horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active ? c.primaryGradient : null,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: AppText.chip(ink, size: compact ? 12.5 : 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
