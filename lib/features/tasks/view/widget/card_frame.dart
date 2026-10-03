import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/sr_colors.dart';

/// The prototype's `.cardimg`: a dark viewfinder with gold corner marks
/// around [child].
class CardFrame extends StatelessWidget {
  const CardFrame({super.key, required this.child, this.height = 210});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
      child: Container(
        height: height,
        color: c.deep,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(padding: const EdgeInsets.all(26), child: child),
            for (final corner in _Corner.values)
              Positioned(
                top: corner.top ? 14 : null,
                bottom: corner.top ? null : 14,
                left: corner.left ? 14 : null,
                right: corner.left ? null : 14,
                child: _CornerMark(corner: corner, color: c.gold),
              ),
          ],
        ),
      ),
    );
  }
}

enum _Corner {
  topLeft(top: true, left: true),
  topRight(top: true, left: false),
  bottomLeft(top: false, left: true),
  bottomRight(top: false, left: false);

  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;
}

class _CornerMark extends StatelessWidget {
  const _CornerMark({required this.corner, required this.color});

  final _Corner corner;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: color, width: 3);
    return SizedBox(
      width: 22,
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: corner.top ? side : BorderSide.none,
            bottom: corner.top ? BorderSide.none : side,
            left: corner.left ? side : BorderSide.none,
            right: corner.left ? BorderSide.none : side,
          ),
        ),
      ),
    );
  }
}
