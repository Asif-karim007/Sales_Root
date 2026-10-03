import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/providers/leave_providers.dart';
import 'package:salesroot/features/hr/view/widget/hr_language_toggle.dart';
import 'package:salesroot/features/hr/view/widget/hr_paged_list.dart';
import 'package:salesroot/features/hr/view/widget/leave_widgets.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// The leave list: balances on top, then every request with its status.
class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  static const List<int?> _filters = [
    null,
    LeaveStatusRef.pending,
    LeaveStatusRef.approved,
    LeaveStatusRef.rejected,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canAdd = ref.watch(moduleAccessProvider(AppModule.leave)).canAdd;
    final list = ref.watch(leaveListProvider);
    final filter = ref.watch(leaveStatusFilterProvider);
    final labels = [
      l10n.commonAll,
      l10n.hrStatusPending,
      l10n.hrStatusApproved,
      l10n.hrStatusRejected,
    ];

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.hrLeaveTitle,
        actions: [
          const HrLanguageToggle(),
          if (canAdd)
            SrIconButton(
              icon: Icons.add_rounded,
              tooltip: l10n.hrLeaveNew,
              onTap: () => context.push(Routes.leaveNew),
            ),
        ],
        bottom: SrChipRow(
          padding: EdgeInsets.zero,
          chips: [for (final label in labels) SrChipItem(label)],
          index: _filters.indexOf(filter),
          onChanged: (i) =>
              ref.read(leaveStatusFilterProvider.notifier).set(_filters[i]),
        ),
      ),
      body: SrAsyncView(
        value: list,
        onRetry: () => ref.invalidate(leaveListProvider),
        loading: (_) => const SrSkeletonList(cards: true, count: 4),
        data: (context, paged) => HrPagedList<LeaveRequest>(
          paged: paged,
          onLoadMore: () => ref.read(leaveListProvider.notifier).loadMore(),
          onRefresh: () async {
            ref
              ..invalidate(leaveBalancesProvider)
              ..invalidate(leaveListProvider);
            await ref.read(leaveListProvider.future);
          },
          header: [
            const _Balances(),
            if (paged.isEmpty)
              _Empty(
                onAdd: canAdd ? () => context.push(Routes.leaveNew) : null,
              ),
          ],
          itemBuilder: (context, request) => SrCard(
            padding: EdgeInsets.zero,
            child: LeaveRequestRow(request: request),
          ),
        ),
      ),
    );
  }
}

class _Balances extends ConsumerWidget {
  const _Balances();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(leaveBalancesProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (balances) {
        AsyncValue(:final value?) => LeaveBalanceGrid(balances: value),
        AsyncError(:final error) => SrErrorState(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(leaveBalancesProvider),
        ),
        _ => const Row(
          children: [
            Expanded(child: SrSkeletonBox(height: 64, radius: 14)),
            SizedBox(width: 8),
            Expanded(child: SrSkeletonBox(height: 64, radius: 14)),
            SizedBox(width: 8),
            Expanded(child: SrSkeletonBox(height: 64, radius: 14)),
          ],
        ),
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: SrMetrics.gutter),
      child: SrEmptyState(
        icon: Icons.beach_access_outlined,
        title: l10n.hrLeaveEmptyTitle,
        message: l10n.hrLeaveEmptyBody,
        actionLabel: onAdd == null ? null : l10n.hrLeaveNew,
        onAction: onAdd,
      ),
    );
  }
}
