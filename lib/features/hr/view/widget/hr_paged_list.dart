import 'package:flutter/material.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A pull-to-refresh list that asks for the next page near its end, with a
/// skeleton row while it loads and a retry banner when that fails.
class HrPagedList<T> extends StatelessWidget {
  const HrPagedList({
    super.key,
    required this.paged,
    required this.itemBuilder,
    this.onLoadMore,
    required this.onRefresh,
    this.header = const [],
    this.gap = 10,
  });

  final Paged<T> paged;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Null for a list the server sends whole.
  final VoidCallback? onLoadMore;
  final Future<void> Function() onRefresh;

  /// Widgets above the items, scrolling with them.
  final List<Widget> header;
  final double gap;

  static const double _loadAhead = 400;

  bool _onScroll(ScrollNotification notification) {
    final loadMore = onLoadMore;
    if (loadMore != null &&
        notification.metrics.extentAfter < _loadAhead &&
        paged.hasMore &&
        !paged.isLoadingMore &&
        paged.loadMoreError == null) {
      loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final items = paged.items;
    final footer = paged.isLoadingMore || paged.loadMoreError != null;
    final count = header.length + items.length + (footer ? 1 : 0);

    return RefreshIndicator(
      color: c.accent,
      backgroundColor: c.surface,
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            14,
            SrMetrics.gutter,
            24,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            if (index < header.length) return header[index];
            final i = index - header.length;
            if (i == items.length) return _footer();
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
              child: itemBuilder(context, items[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _footer() {
    final error = paged.loadMoreError;
    return Padding(
      padding: EdgeInsets.only(top: gap),
      child: error == null
          ? const SrSkeletonCard()
          : SrErrorState(error: error, compact: true, onRetry: onLoadMore),
    );
  }
}
