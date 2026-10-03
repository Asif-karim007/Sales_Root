import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/providers/expense_providers.dart';
import 'package:salesroot/features/hr/view/widget/expense_widgets.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_language_toggle.dart';
import 'package:salesroot/features/hr/view/widget/hr_paged_list.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The signed-in rep's claims with their statuses.
class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  static const List<ExpenseStage?> _filters = [
    null,
    ExpenseStage.pending,
    ExpenseStage.approved,
    ExpenseStage.paid,
    ExpenseStage.returned,
    ExpenseStage.rejected,
    ExpenseStage.withdrawn,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAdd = ref.watch(moduleAccessProvider(AppModule.expense)).canAdd;
    final list = ref.watch(expenseListProvider);
    final filter = ref.watch(expenseStageFilterProvider);
    final counts = list.value?.facets[expenseFacets.first] ?? const {};
    void add() => context.push(Routes.expenseNew);

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.hrExpenseTitle,
        actions: [
          const HrLanguageToggle(),
          if (canAdd)
            SrIconButton(
              icon: Icons.add_rounded,
              tooltip: l10n.hrExpenseNew,
              onTap: add,
            ),
        ],
        bottom: SrChipRow(
          padding: EdgeInsets.zero,
          chips: [
            for (final stage in _filters)
              stage == null
                  ? SrChipItem(l10n.commonAll)
                  : SrChipItem(
                      l10n.expenseStage(stage),
                      count: counts[stage.wire],
                    ),
          ],
          index: _filters.indexOf(filter),
          onChanged: (i) =>
              ref.read(expenseStageFilterProvider.notifier).set(_filters[i]),
        ),
      ),
      body: SrAsyncView(
        value: list,
        onRetry: () => ref.invalidate(expenseListProvider),
        onUpgrade: () => openHrUpgrade(context),
        loading: (_) => const SrSkeletonList(cards: true, count: 5),
        data: (context, paged) => HrPagedList<ExpenseClaim>(
          paged: paged,
          onLoadMore: () => ref.read(expenseListProvider.notifier).loadMore(),
          onRefresh: () async {
            ref.invalidate(expenseListProvider);
            await ref.read(expenseListProvider.future);
          },
          header: [
            ExpenseTotals(totals: paged.facets[expenseFacets.last] ?? const {}),
            const SizedBox(height: 16),
            if (paged.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: SrMetrics.gutter),
                child: SrEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.hrExpenseEmptyTitle,
                  message: l10n.hrExpenseEmptyBody,
                  actionLabel: canAdd ? l10n.hrExpenseNew : null,
                  onAction: canAdd ? add : null,
                ),
              ),
          ],
          itemBuilder: (context, claim) => ExpenseCard(claim: claim),
        ),
      ),
    );
  }
}
