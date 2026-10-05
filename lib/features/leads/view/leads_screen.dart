import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/leads/models/lead.dart';
import 'package:salesroot/features/leads/models/lead_activity.dart';
import 'package:salesroot/features/leads/models/lead_query.dart';
import 'package:salesroot/features/leads/providers/lead_providers.dart';
import 'package:salesroot/features/leads/view/widget/call_outcome_sheet.dart';
import 'package:salesroot/features/leads/view/widget/lead_board_view.dart';
import 'package:salesroot/features/leads/view/widget/lead_card.dart';
import 'package:salesroot/features/leads/view/widget/lead_events.dart';
import 'package:salesroot/features/leads/view/widget/lead_filter_sheet.dart';
import 'package:salesroot/features/leads/view/widget/lead_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #21, the Leads tab: "My leads" as cards with chips, or "Pipeline" as the
/// board. With [pick] set it is a picker for logging a call or note.
class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key, this.pick, this.board = false});

  final LeadActivityKind? pick;

  /// Opens on the Pipeline board.
  final bool board;

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  late bool _board = widget.board;
  bool _searching = false;
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) ref.read(leadFilterProvider.notifier).search(text);
    });
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (_searching) return;
    _search.clear();
    ref.read(leadFilterProvider.notifier).search('');
  }

  Future<void> _pick(Lead lead) async {
    final kind = widget.pick ?? LeadActivityKind.note;
    final saved = await context.push<bool>(
      '${Routes.leadActivityFor(lead.id)}?type=${kind.query}',
    );
    if (saved != true || !mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.leads);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pick = widget.pick;
    listenLeadEvents(context, ref, LeadSurface.list);
    if (pick != null) {
      final l10n = context.l10n;
      return SrScaffold(
        appBar: SrAppBar(
          title: l10n.leadsPickTitle,
          subtitle: pick == LeadActivityKind.call
              ? l10n.leadsPickForCall
              : l10n.leadsPickForNote,
          bottom: _SearchField(controller: _search, onChanged: _onSearch),
        ),
        body: _LeadList(onPick: _pick),
      );
    }
    return LeadCallWatcher(
      child: SrScaffold(
        appBar: _Header(
          board: _board,
          searching: _searching,
          search: _search,
          onSearch: _onSearch,
          onToggleSearch: _toggleSearch,
          onMode: (board) => setState(() => _board = board),
        ),
        body: _board ? const LeadBoardView() : const _LeadList(),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.board,
    required this.searching,
    required this.search,
    required this.onSearch,
    required this.onToggleSearch,
    required this.onMode,
  });

  final bool board;
  final bool searching;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final VoidCallback onToggleSearch;
  final ValueChanged<bool> onMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = SrColors.of(context);
    final filter = ref.watch(leadFilterProvider);
    final paged = board ? null : ref.watch(leadListProvider).value;
    final locale = ref.watch(appLocaleProvider);

    return SrHeader(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                board ? l10n.leadsPipeline : l10n.leadsTitle,
                style: AppText.pageTitle(c.ink, size: 22),
              ),
            ),
            SrLanguageToggle(
              isBangla: locale == bangla,
              onChanged: (isBangla) => ref
                  .read(appLocaleProvider.notifier)
                  .set(isBangla ? bangla : english),
            ),
            if (!board) ...[
              const SizedBox(width: 6),
              SrIconButton(
                icon: searching ? Icons.close_rounded : Icons.search_rounded,
                tooltip: l10n.commonSearch,
                onTap: onToggleSearch,
              ),
            ],
            const SizedBox(width: 6),
            SrIconButton(
              icon: Icons.tune_rounded,
              tooltip: l10n.commonFilter,
              badge: filter.activeCount > 0,
              onTap: () => showSrSheet<void>(
                context: context,
                builder: (_) => const LeadFilterSheet(),
              ),
            ),
          ],
        ),
        if (searching && !board)
          _SearchField(
            controller: search,
            onChanged: onSearch,
            autofocus: true,
          ),
        SrSegmented(
          segments: [
            SrSegment(l10n.leadsMyLeads, count: paged?.totalCount),
            SrSegment(l10n.leadsPipeline),
          ],
          index: board ? 1 : 0,
          onChanged: (i) => onMode(i == 1),
        ),
        if (!board)
          SrChipRow(
            padding: EdgeInsets.zero,
            chips: [
              for (final chip in LeadChip.values) SrChipItem(chip.label(l10n)),
            ],
            index: filter.chip.index,
            onChanged: (i) =>
                ref.read(leadFilterProvider.notifier).chip(LeadChip.values[i]),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => SrTextField(
    controller: controller,
    hint: context.l10n.leadsSearchHint,
    prefixIcon: Icons.search_rounded,
    textInputAction: TextInputAction.search,
    autofocus: autofocus,
    onChanged: onChanged,
  );
}

class _LeadList extends ConsumerWidget {
  const _LeadList({this.onPick});

  final ValueChanged<Lead>? onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SrAsyncView(
      value: ref.watch(leadListProvider),
      loading: (_) => const SrSkeletonList(cards: true, count: 4),
      onRetry: () => ref.invalidate(leadListProvider),
      onUpgrade: () =>
          context.push('${Routes.planChoose}?reason=quota&kind=records'),
      isEmpty: (paged) => paged.isEmpty,
      empty: (_) => const _Empty(),
      data: (context, paged) => RefreshIndicator(
        onRefresh: () => ref.refresh(leadListProvider.future),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 400) {
              ref.read(leadListProvider.notifier).loadMore();
            }
            return false;
          },
          child: _Cards(paged: paged, onPick: onPick),
        ),
      ),
    );
  }
}

class _Cards extends ConsumerWidget {
  const _Cards({required this.paged, this.onPick});

  final Paged<Lead> paged;
  final ValueChanged<Lead>? onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = paged.loadMoreError;
    final footer = paged.isLoadingMore || failure != null || paged.hasMore;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        14,
        SrMetrics.gutter,
        24,
      ),
      itemCount: paged.items.length + (footer ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i < paged.items.length) {
          return LeadCard(lead: paged.items[i], onPick: onPick);
        }
        if (failure != null) {
          return SrErrorState(
            error: failure,
            compact: true,
            onRetry: () => ref.read(leadListProvider.notifier).loadMore(),
          );
        }
        return const SrSkeletonCard();
      },
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(leadFilterProvider);
    final narrowed =
        filter.search.isNotEmpty ||
        filter.chip != LeadChip.all ||
        filter.activeCount > 0;
    final canAdd = ref.watch(moduleAccessProvider(AppModule.lead)).canAdd;
    final empty = narrowed
        ? SrEmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: l10n.leadsNoMatchTitle,
            message: l10n.leadsNoMatchBody,
            actionLabel: l10n.leadsClearFilter,
            onAction: () =>
                ref.read(leadFilterProvider.notifier).apply(const LeadFilter()),
          )
        : SrEmptyState(
            icon: Icons.person_add_alt_1_outlined,
            title: l10n.leadsEmptyTitle,
            message: l10n.leadsEmptyBody,
            actionLabel: canAdd ? l10n.leadsAddLead : null,
            onAction: canAdd ? () => context.push(Routes.leadQuick) : null,
          );
    return Center(child: SingleChildScrollView(child: empty));
  }
}
