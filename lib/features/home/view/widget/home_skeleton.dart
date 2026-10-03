import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The home's shape while the summary loads: a row of tiles, an action bar
/// and a list card.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        16,
      ),
      children: const [
        SrStatGrid(tiles: [_TileSkeleton(), _TileSkeleton(), _TileSkeleton()]),
        SizedBox(height: 14),
        SrSkeletonBox(height: SrMetrics.buttonHeight, radius: 12),
        SizedBox(height: 22),
        SrSkeletonBox(widthFactor: 0.3, height: 14),
        SrSkeletonList(
          count: 4,
          shrinkWrap: true,
          padding: EdgeInsets.only(top: 10),
        ),
      ],
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SrCard(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SrSkeletonBox(widthFactor: 0.7, height: 10),
          SizedBox(height: 10),
          SrSkeletonBox(widthFactor: 0.4, height: 20),
          SizedBox(height: 8),
          SrSkeletonBox(widthFactor: 0.6, height: 10),
        ],
      ),
    );
  }
}
