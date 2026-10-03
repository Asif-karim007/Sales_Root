import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/home/providers/home_providers.dart';
import 'package:salesroot/features/home/providers/notification_providers.dart';

/// The scrolling body of every home: [children] with even gaps, pulled down
/// to refresh the summary and the bell.
class HomeScrollView extends ConsumerWidget {
  const HomeScrollView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    return RefreshIndicator(
      color: c.accent,
      backgroundColor: c.surface,
      onRefresh: () async {
        ref.invalidate(unreadNotificationCountProvider);
        try {
          ref.invalidate(homeSummaryProvider);
          await ref.read(homeSummaryProvider.future);
        } on ApiFailure {
          return;
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          SrMetrics.gutter,
          16,
          SrMetrics.gutter,
          96,
        ),
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}
