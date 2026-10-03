import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/widgets/widgets.dart';

/// A paged list under [header]: the items sit in one card that grows as more
/// pages load on scroll, with every loading, empty and error state.
class PagedScrollView<T> extends StatelessWidget {
  const PagedScrollView({
    super.key,
    required this.value,
    required this.header,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onRetry,
    required this.empty,
    this.onUpgrade,
  });

  final AsyncValue<Paged<T>> value;
  final List<Widget> header;

  /// Builds a row; [last] rows draw no divider.
  final Widget Function(BuildContext context, T item, bool last) itemBuilder;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback? onUpgrade;
  final Widget empty;

  static const _gutter = EdgeInsets.symmetric(horizontal: SrMetrics.gutter);

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 400) {
      onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return RefreshIndicator(
      color: c.accent,
      backgroundColor: c.surface,
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: SrScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SrMetrics.gutter,
                16,
                SrMetrics.gutter,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  for (final widget in header) ...[
                    widget,
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            ..._content(context),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context) => value.when(
    skipLoadingOnReload: false,
    loading: () => const [
      SliverToBoxAdapter(
        child: SrSkeletonList(count: 8, shrinkWrap: true, padding: _gutter),
      ),
    ],
    error: (error, _) => [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: SrErrorState(
            error: error,
            onRetry: onRetry,
            onUpgrade: onUpgrade,
          ),
        ),
      ),
    ],
    data: (paged) {
      if (paged.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: empty),
          ),
        ];
      }
      final failure = paged.loadMoreError;
      return [
        SliverPadding(
          padding: _gutter,
          sliver: SliverList.builder(
            itemCount: paged.items.length,
            itemBuilder: (context, index) {
              final last = index == paged.items.length - 1;
              return CardSegment(
                first: index == 0,
                last: last,
                child: itemBuilder(context, paged.items[index], last),
              );
            },
          ),
        ),
        if (paged.isLoadingMore)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              8,
              SrMetrics.gutter,
              0,
            ),
            sliver: SliverToBoxAdapter(child: SrSkeletonRow()),
          ),
        if (failure != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              12,
              SrMetrics.gutter,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: SrErrorState(
                error: failure,
                compact: true,
                onRetry: onLoadMore,
              ),
            ),
          ),
      ];
    },
  );
}

/// One row's slice of a card, so a lazily built list still reads as a
/// single rounded card.
class CardSegment extends StatelessWidget {
  const CardSegment({
    super.key,
    required this.first,
    required this.last,
    required this.child,
  });

  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    const radius = Radius.circular(SrMetrics.radiusCard);
    final shape = BorderRadius.vertical(
      top: first ? radius : Radius.zero,
      bottom: last ? radius : Radius.zero,
    );
    final side = BorderSide(color: c.line);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: shape,
        border: Border(
          left: side,
          right: side,
          top: first ? side : BorderSide.none,
          bottom: last ? side : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: first ? 2 : 0, bottom: last ? 2 : 0),
        child: child,
      ),
    );
  }
}
