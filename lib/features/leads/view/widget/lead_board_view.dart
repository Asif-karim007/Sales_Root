import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_stage.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/lead_events.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/features/leads/view/widget/move_stage_sheet.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #22: a column per stage. Long-press a card and drop it on another column
/// to move it; the snackbar offers undo for ten seconds.
class LeadBoardView extends ConsumerStatefulWidget {
  const LeadBoardView({super.key});

  @override
  ConsumerState<LeadBoardView> createState() => _LeadBoardViewState();
}

class _LeadBoardViewState extends ConsumerState<LeadBoardView> {
  static const double _edge = 56;
  static const double _step = 14;

  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  Timer? _autoScroll;
  double _direction = 0;

  @override
  void dispose() {
    _autoScroll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onDrag(Offset global) {
    final box = _viewport.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final x = box.globalToLocal(global).dx;
    _direction = x < _edge
        ? -1
        : x > box.size.width - _edge
        ? 1
        : 0;
    if (_direction == 0) return _stopScroll();
    _autoScroll ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      _scroll.jumpTo(
        (position.pixels + _direction * _step).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  void _stopScroll() {
    _autoScroll?.cancel();
    _autoScroll = null;
  }

  @override
  Widget build(BuildContext context) {
    listenLeadEvents(context, ref, LeadSurface.board);
    final l10n = context.l10n;
    return SrAsyncView(
      value: ref.watch(leadBoardProvider),
      loading: (_) => const SrSkeletonList(cards: true, count: 4),
      onRetry: () => ref.invalidate(leadBoardProvider),
      data: (context, board) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: _viewport,
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                SrMetrics.gutter,
                14,
                SrMetrics.gutter,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, stage) in board.stages.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _Column(
                      stage: stage,
                      column: board.column(stage.id),
                      onDrag: _onDrag,
                      onDragEnd: _stopScroll,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SrMetrics.gutter,
              10,
              SrMetrics.gutter,
              14,
            ),
            child: SrNote(
              message: l10n.leadsBoardHint,
              icon: Icons.info_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _Column extends ConsumerWidget {
  const _Column({
    required this.stage,
    required this.column,
    required this.onDrag,
    required this.onDragEnd,
  });

  static const double width = 210;

  final LeadStage stage;
  final Paged<Lead> column;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    return SizedBox(
      width: width,
      child: DragTarget<Lead>(
        onWillAcceptWithDetails: (details) =>
            details.data.stage?.id != stage.id,
        onAcceptWithDetails: (details) => moveLeadStage(
          context,
          ref,
          details.data,
          LeadSurface.board,
          to: stage,
        ),
        builder: (context, candidates, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: candidates.isEmpty ? null : c.tint,
            borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ColumnHeader(stage: stage, count: column.totalCount),
              const SizedBox(height: 8),
              Expanded(
                child: _ColumnCards(
                  stage: stage,
                  column: column,
                  onDrag: onDrag,
                  onDragEnd: onDragEnd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.stage, required this.count});

  final LeadStage stage;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            stage.name.of(context.fmt.isBangla),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.style(
              size: 13,
              weight: FontWeight.w700,
              color: stage.isLost ? c.danger : c.ink,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: c.line,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            context.fmt.number(count),
            style: AppText.caption(c.ink2),
          ),
        ),
      ],
    );
  }
}

class _ColumnCards extends ConsumerWidget {
  const _ColumnCards({
    required this.stage,
    required this.column,
    required this.onDrag,
    required this.onDragEnd,
  });

  final LeadStage stage;
  final Paged<Lead> column;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    if (column.isEmpty) {
      return Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: SrBorder.all(color: c.line),
          borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        ),
        child: Text(
          context.l10n.leadsBoardEmptyColumn,
          style: AppText.meta(c.ink3),
        ),
      );
    }
    final failure = column.loadMoreError;
    final footer = column.isLoadingMore || failure != null || column.hasMore;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 300) {
          ref.read(leadBoardProvider.notifier).loadMore(stage.id);
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: column.items.length + (footer ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i < column.items.length) {
            return _DraggableCard(
              lead: column.items[i],
              onDrag: onDrag,
              onDragEnd: onDragEnd,
            );
          }
          if (failure != null) {
            return SrErrorState(
              error: failure,
              compact: true,
              onRetry: () =>
                  ref.read(leadBoardProvider.notifier).loadMore(stage.id),
            );
          }
          return const SrSkeletonBox(height: 64, radius: 10);
        },
      ),
    );
  }
}

class _DraggableCard extends ConsumerWidget {
  const _DraggableCard({
    required this.lead,
    required this.onDrag,
    required this.onDragEnd,
  });

  final Lead lead;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(moduleAccessProvider(AppModule.lead));
    final card = _MiniCard(
      lead: lead,
      onTap: () => context.push(Routes.leadFor(lead.id)),
    );
    if (!access.canEdit) return card;
    return LongPressDraggable<Lead>(
      data: lead,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: _Column.width,
          child: _MiniCard(lead: lead, lifted: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      onDragUpdate: (details) => onDrag(details.globalPosition),
      onDragEnd: (_) => onDragEnd(),
      onDraggableCanceled: (_, _) => onDragEnd(),
      child: card,
    );
  }
}

/// The prototype's `.mini`: name, value and the next step or source.
class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.lead, this.onTap, this.lifted = false});

  final Lead lead;
  final VoidCallback? onTap;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final fmt = context.fmt;
    final amount = lead.estimatedAmount;
    final created = lead.createdOn;
    final meta =
        lead.nextLine(context) ??
        leadMeta([
          leadSourceLabel(context.l10n, lead.source),
          created == null ? null : fmt.dayMonth(created),
        ]);
    return Material(
      color: c.surface,
      elevation: lifted ? 6 : 0,
      shadowColor: c.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        side: BorderSide(color: lifted ? c.accent : c.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SrMetrics.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lead.leadName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowTitle(c.ink, size: 13),
              ),
              const SizedBox(height: 3),
              Text(
                amount == null
                    ? context.l10n.leadsNone
                    : fmt.moneyCompact(amount),
                style: AppText.meta(c.ink2, size: 12),
              ),
              if (meta.isNotEmpty)
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta(
                    lead.isOverdue ? c.danger : c.ink2,
                    size: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
