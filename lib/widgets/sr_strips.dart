import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/sr_border.dart';

class SrYearPill extends StatelessWidget {
  const SrYearPill({super.key, required this.year, this.onTap});

  final String year;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 11, right: 7),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(999),
          border: SrBorder.all(color: c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(year, style: AppText.chip(c.ink, size: 12.5)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: c.ink3),
          ],
        ),
      ),
    );
  }
}

/// Shows three months at a time, centred on the selected one; the rest
/// scroll.
class SrMonthStrip extends StatefulWidget {
  const SrMonthStrip({
    super.key,
    required this.months,
    required this.index,
    required this.onChanged,
    this.year,
    this.onYearTap,
    this.padding = const EdgeInsets.symmetric(horizontal: SrMetrics.gutter),
  });

  final List<String> months;
  final int index;
  final ValueChanged<int> onChanged;
  final String? year;
  final VoidCallback? onYearTap;
  final EdgeInsets padding;

  @override
  State<SrMonthStrip> createState() => _SrMonthStripState();
}

class _SrMonthStripState extends State<SrMonthStrip> {
  ScrollController? _scroll;
  double _width = 0;

  double get _extent => _width / 3;

  double _offsetFor(int index) {
    final max = (widget.months.length * _extent - _width).clamp(
      0.0,
      double.infinity,
    );
    return ((index - 1) * _extent).clamp(0.0, max);
  }

  @override
  void didUpdateWidget(SrMonthStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final scroll = _scroll;
    if (widget.index == oldWidget.index ||
        scroll == null ||
        !scroll.hasClients) {
      return;
    }
    scroll.animateTo(
      _offsetFor(widget.index),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.year;

    return Padding(
      padding: widget.padding,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            if (year != null) ...[
              SrYearPill(year: year, onTap: widget.onYearTap),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _width = constraints.maxWidth;
                  final scroll = _scroll ??= ScrollController(
                    initialScrollOffset: _offsetFor(widget.index),
                  );

                  return ListView.builder(
                    controller: scroll,
                    scrollDirection: Axis.horizontal,
                    itemExtent: _extent,
                    itemCount: widget.months.length,
                    itemBuilder: (context, i) => _MonthChip(
                      label: widget.months[i],
                      active: i == widget.index,
                      onTap: () => widget.onChanged(i),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? c.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppText.chip(active ? c.onAccent : c.ink2, size: 12.5),
          ),
        ),
      ),
    );
  }
}

/// One day in an [SrDayStrip]: the date number and a short weekday.
class SrDay {
  const SrDay({required this.number, required this.label, this.dot = false});

  final String number;
  final String label;

  /// Marks a day that has something on it.
  final bool dot;
}

class SrDayStrip extends StatelessWidget {
  const SrDayStrip({
    super.key,
    required this.days,
    required this.index,
    required this.onChanged,
  });

  final List<SrDay> days;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _DayCell(
              day: days[i],
              active: i == index,
              onTap: () => onChanged(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.active,
    required this.onTap,
  });

  final SrDay day;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final ink = active ? c.onAccent : c.ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? c.primaryGradient : null,
          color: active ? null : c.surface,
          borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
          border: active ? null : SrBorder.all(color: c.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.label,
              style: AppText.caption(active ? c.onAccent : c.ink3, size: 11),
            ),
            const SizedBox(height: 2),
            Text(day.number, style: AppText.rowTitle(ink, size: 15)),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: day.dot
                    ? (active ? c.onAccent : c.accent)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tab in an [SrStatusTabs]: a label, an optional count and an optional
/// amount line.
class SrStatusTab {
  const SrStatusTab({required this.label, this.count, this.amount});

  final String label;

  /// Already formatted, so Bangla digits come from the caller.
  final String? count;
  final String? amount;
}

/// Underlined tabs on a hairline, for status filters with counts.
class SrStatusTabs extends StatelessWidget {
  const SrStatusTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<SrStatusTab> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: _StatusTab(
                tab: tabs[i],
                active: i == index,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final SrStatusTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final count = tab.count;
    final amount = tab.amount;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(top: 6, bottom: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: active ? c.accent : Colors.transparent,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              count == null ? tab.label : '${tab.label} ($count)',
              textAlign: TextAlign.center,
              style: AppText.chip(active ? c.accent : c.ink2, size: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (amount != null) ...[
              const SizedBox(height: 3),
              Text(
                amount,
                style: AppText.meta(active ? c.ink : c.ink3, size: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
