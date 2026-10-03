import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';

/// A gold line sweeping over the frame while the card is being read.
class ScanBeam extends StatefulWidget {
  const ScanBeam({super.key, required this.label});

  final String label;

  @override
  State<ScanBeam> createState() => _ScanBeamState();
}

class _ScanBeamState extends State<ScanBeam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Semantics(
      liveRegion: true,
      label: widget.label,
      child: ColoredBox(
        color: c.scrim,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) => Align(
                alignment: Alignment(0, _sweep.value * 2 - 1),
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: c.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Center(
              child: Text(widget.label, style: AppText.rowTitle(c.onDeep)),
            ),
          ],
        ),
      ),
    );
  }
}
