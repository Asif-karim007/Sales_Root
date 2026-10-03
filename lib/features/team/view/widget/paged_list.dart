import 'package:flutter/material.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A pull-to-refresh list of [header] widgets followed by the [paged] items
/// in one card, asking for the next page near the end.
class PagedCardList<T> extends StatelessWidget {
  const PagedCardList({
    super.key,
    required this.paged,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    this.header = const [],
    this.empty,
  });

  final Paged<T> paged;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final List<Widget> header;

  /// Shown under [header] when there are no items.
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final error = paged.loadMoreError;
    final empty = this.empty;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400 &&
            paged.hasMore &&
            error == null) {
          onLoadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        color: c.accent,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 32),
          children: [
            for (final widget in header) ...[
              widget,
              const SizedBox(height: 12),
            ],
            if (paged.isEmpty && empty != null)
              empty
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SrMetrics.gutter,
                ),
                child: SrRowGroup(
                  rows: [
                    for (final item in paged.items) itemBuilder(context, item),
                    if (paged.isLoadingMore) const SrSkeletonRow(),
                  ],
                  dividerIndent: 66,
                ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SrMetrics.gutter,
                  12,
                  SrMetrics.gutter,
                  0,
                ),
                child: SrErrorState(
                  error: error,
                  compact: true,
                  onRetry: onLoadMore,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
