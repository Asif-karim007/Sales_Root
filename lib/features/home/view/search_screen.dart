import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/home/models/search_result.dart';
import 'package:salesroot/features/home/providers/search_providers.dart';
import 'package:salesroot/features/home/view/widget/search_hit_row.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #20: one box over leads, contacts, companies and tasks. Results arrive as
/// typing pauses; the scope chips narrow them to one kind.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _setTerm(String term) =>
      ref.read(searchQueryProvider.notifier).setTerm(term);

  void _apply(String term) {
    _field.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    _setTerm(term);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBangla = ref.watch(appLocaleProvider) == bangla;
    final query = ref.watch(searchQueryProvider);
    final kinds = [
      for (final kind in SearchKind.values)
        if (ref.watch(
          moduleAccessProvider(_moduleOf(kind)).select((a) => a.canView),
        ))
          kind,
    ];
    return SrKeyboardDismiss(
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.commonSearch,
          actions: [
            SrLanguageToggle(
              isBangla: isBangla,
              onChanged: (bn) => ref
                  .read(appLocaleProvider.notifier)
                  .set(bn ? bangla : english),
            ),
          ],
          bottom: SrTextField(
            controller: _field,
            hint: l10n.homeSearchHint,
            prefixIcon: Icons.search_rounded,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _setTerm,
            onSubmitted: (term) =>
                ref.read(recentSearchesProvider.notifier).remember(term),
            suffix: query.isEmpty
                ? null
                : SrIconButton(
                    icon: Icons.close_rounded,
                    compact: true,
                    tooltip: l10n.commonClear,
                    onTap: () => _apply(''),
                  ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            _ScopeChips(kinds: kinds),
            Expanded(
              child: query.isEmpty
                  ? _RecentSearches(onPick: _apply)
                  : _Results(kinds: kinds),
            ),
          ],
        ),
      ),
    );
  }
}

AppModule _moduleOf(SearchKind kind) => switch (kind) {
  SearchKind.lead => AppModule.lead,
  SearchKind.contact => AppModule.contact,
  SearchKind.company => AppModule.company,
  SearchKind.task => AppModule.task,
};

String _kindLabel(AppLocalizations l10n, SearchKind kind) => switch (kind) {
  SearchKind.lead => l10n.homeSearchLeads,
  SearchKind.contact => l10n.homeSearchContacts,
  SearchKind.company => l10n.homeSearchCompanies,
  SearchKind.task => l10n.homeSearchTasks,
};

class _ScopeChips extends ConsumerWidget {
  const _ScopeChips({required this.kinds});

  final List<SearchKind> kinds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider).value;
    final scopes = [null, ...kinds];
    int? count(SearchKind? kind) => kind == null
        ? (query.kind == null ? results?.totalCount : null)
        : results?.group(kind)?.totalCount;
    return SrChipRow(
      index: scopes.indexOf(query.kind).clamp(0, scopes.length - 1),
      onChanged: (i) =>
          ref.read(searchQueryProvider.notifier).setKind(scopes[i]),
      chips: [
        for (final kind in scopes)
          SrChipItem(
            kind == null ? l10n.commonAll : _kindLabel(l10n, kind),
            count: count(kind),
          ),
      ],
    );
  }
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final recent = ref.watch(recentSearchesProvider);
    if (recent.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: SrEmptyState(
            icon: Icons.manage_search_rounded,
            title: l10n.homeSearchStartTitle,
            message: l10n.homeSearchStartBody,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        SrRowGroup(
          title: l10n.homeRecentSearches,
          seeAllLabel: l10n.commonClear,
          onSeeAll: () => ref.read(recentSearchesProvider.notifier).clear(),
          rows: [
            for (final term in recent)
              SrListRow(
                title: term,
                leading: Icon(Icons.history_rounded, size: 20, color: c.ink3),
                trailing: SrIconButton(
                  icon: Icons.close_rounded,
                  compact: true,
                  tooltip: l10n.commonDelete,
                  onTap: () =>
                      ref.read(recentSearchesProvider.notifier).remove(term),
                ),
                onTap: () => onPick(term),
              ),
          ],
        ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.kinds});

  final List<SearchKind> kinds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final results = ref.watch(searchResultsProvider);
    final kind = ref.watch(searchQueryProvider.select((q) => q.kind));
    final data = results.value;
    final error = results.error;
    if (error != null && !results.isLoading) {
      return Center(
        child: SingleChildScrollView(
          child: SrErrorState(
            error: error,
            onRetry: () => ref.invalidate(searchResultsProvider),
          ),
        ),
      );
    }
    if (data == null || (data.isEmpty && results.isLoading)) {
      return const SrSkeletonList(count: 5);
    }
    if (data.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: SrEmptyState(
            icon: Icons.search_off_rounded,
            title: l10n.dsSearchEmptyTitle,
            message: l10n.dsSearchEmptyBody,
          ),
        ),
      );
    }
    final groups = [
      for (final k in kinds)
        if (data.group(k) case final SearchGroup g when g.items.isNotEmpty) g,
    ];
    return kind == null
        ? _GroupedResults(groups: groups)
        : _SingleKindResults(group: groups.firstOrNull);
  }
}

class _GroupedResults extends ConsumerWidget {
  const _GroupedResults({required this.groups});

  final List<SearchGroup> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final group = groups[i];
        return SrRowGroup(
          title:
              '${_kindLabel(l10n, group.kind)} · '
              '${fmt.number(group.totalCount)}',
          seeAllLabel: group.hasMore
              ? l10n.homeSeeAllCount(fmt.number(group.totalCount))
              : null,
          onSeeAll: group.hasMore
              ? () => ref.read(searchQueryProvider.notifier).setKind(group.kind)
              : null,
          rows: [for (final hit in group.items) SearchHitRow(hit: hit)],
        );
      },
    );
  }
}

class _SingleKindResults extends ConsumerWidget {
  const _SingleKindResults({required this.group});

  final SearchGroup? group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = this.group;
    if (group == null) return const SizedBox.shrink();
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 400) {
          ref.read(searchResultsProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SrRowGroup(
            rows: [for (final hit in group.items) SearchHitRow(hit: hit)],
          ),
          if (group.hasMore)
            const SrSkeletonList(
              count: 2,
              shrinkWrap: true,
              padding: EdgeInsets.only(top: 12),
            ),
        ],
      ),
    );
  }
}
