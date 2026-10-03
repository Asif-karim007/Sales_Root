import 'package:flutter/material.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Calls [onLoadMore] when the scroll nears the end of [child], unless the
/// last attempt failed; the footer's retry takes over then.
class LoadMoreListener extends StatelessWidget {
  const LoadMoreListener({
    super.key,
    required this.paged,
    required this.onLoadMore,
    required this.child,
  });

  final Paged<Object?>? paged;
  final VoidCallback onLoadMore;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final list = paged;
        if (list != null &&
            list.hasMore &&
            list.loadMoreError == null &&
            notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 480) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

/// The end of a paged list: a skeleton row while the next page loads, or the
/// failure with a retry.
class PagedFooter extends StatelessWidget {
  const PagedFooter({super.key, required this.paged, required this.onRetry});

  final Paged<Object?> paged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = paged.loadMoreError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SrErrorState(error: error, onRetry: onRetry, compact: true),
      );
    }
    if (!paged.isLoadingMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: SrSkeletonList(
        count: 1,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
