import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/experience_level.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/providers/collection_providers.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/providers/product_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';
import 'package:salesroot/features/sales/view/sales_links.dart';
import 'package:salesroot/features/sales/view/widget/list_sheets.dart';
import 'package:salesroot/features/sales/view/widget/sales_rows.dart';
import 'package:salesroot/features/sales/view/widget/sales_tile.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #50: this month's sales, open quotations, what to deliver and collect.
class SalesHomeScreen extends ConsumerWidget {
  const SalesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(moduleAccessProvider(AppModule.product));
    final orders = ref.watch(moduleAccessProvider(AppModule.order));
    final collection = ref.watch(moduleAccessProvider(AppModule.collection));
    return SrScaffold(
      appBar: const _SalesHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(salesOverviewProvider)
            ..invalidate(awaitingQuotationsProvider)
            ..invalidate(productListProvider)
            ..invalidate(orderListProvider)
            ..invalidate(dueListProvider);
          await ref.read(salesOverviewProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SrMetrics.gutter,
            16,
            SrMetrics.gutter,
            120,
          ),
          children: [
            const _Kpis(),
            const SizedBox(height: 12),
            const _QuickTiles(),
            if (products.canView) ...[
              const SizedBox(height: 22),
              const _ProductsSection(),
            ],
            const SizedBox(height: 22),
            const _AwaitingSection(),
            if (orders.canView) ...[
              const SizedBox(height: 22),
              const _ToDeliverSection(),
            ],
            if (collection.canView) ...[
              const SizedBox(height: 22),
              const _DuesSection(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SalesHeader extends ConsumerWidget {
  const _SalesHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final locale = ref.watch(appLocaleProvider);
    final level = ref.watch(experienceLevelProvider);
    final workspace = ref.watch(
      currentWorkspaceProvider.select((w) => w?.name),
    );
    return SrHeader(
      children: [
        Row(
          children: [
            Icon(Icons.eco_rounded, color: c.accent, size: 22),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.pageTitle(c.accent, size: 17),
              ),
            ),
            SrLanguageToggle(
              isBangla: locale == bangla,
              onChanged: (isBangla) => ref
                  .read(appLocaleProvider.notifier)
                  .set(isBangla ? bangla : english),
            ),
            const SizedBox(width: 6),
            SrIconButton(
              icon: Icons.search_rounded,
              compact: true,
              tooltip: l10n.commonSearch,
              onTap: () => context.push(Routes.search),
            ),
            SrIconButton(
              icon: Icons.notifications_none_rounded,
              compact: true,
              tooltip: l10n.salesNotifications,
              onTap: () => context.push(Routes.notifications),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(switch (level) {
                    ExperienceLevel.easy => l10n.salesModeEasy,
                    ExperienceLevel.standard => l10n.salesModeStandard,
                    ExperienceLevel.advanced => l10n.salesModeAdvanced,
                  }, style: AppText.meta(c.ink2)),
                  Text(l10n.salesTitle, style: AppText.hero(c.ink, size: 24)),
                ],
              ),
            ),
            if (workspace != null)
              SrTag(workspace, icon: Icons.groups_2_outlined),
          ],
        ),
      ],
    );
  }
}

class _Kpis extends ConsumerWidget {
  const _Kpis();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final overview = ref.watch(salesOverviewProvider);
    final canCollect = ref
        .watch(moduleAccessProvider(AppModule.collection))
        .canView;
    return switch (overview) {
      AsyncValue(:final value?) => SrStatGrid(
        tiles: [
          SrKpiTile(
            label: l10n.salesThisMonth,
            value: fmt.moneyCompact(value.salesThisMonth),
            delta: switch (value.growth) {
              final growth? => l10n.salesVsLastMonth(fmt.percent(growth.abs())),
              null => null,
            },
            deltaUp: switch (value.growth) {
              final growth? => growth >= 0,
              null => null,
            },
          ),
          SrKpiTile(
            label: l10n.salesOpenQuotes,
            value: fmt.number(value.openQuotations),
            delta: fmt.moneyCompact(value.openQuotationValue),
            onTap: () => context.push(Routes.quotations),
          ),
          SrKpiTile(
            label: l10n.salesOutstanding,
            value: fmt.moneyCompact(value.receivable),
            delta: l10n.salesToDeliverCount(fmt.number(value.ordersToDeliver)),
            onTap: canCollect ? () => context.push(Routes.outstanding) : null,
          ),
        ],
      ),
      AsyncValue(:final error?) => SrErrorState(
        error: error,
        compact: true,
        onRetry: () => ref.invalidate(salesOverviewProvider),
      ),
      _ => const SrStatGrid(
        tiles: [
          SrSkeletonBox(height: 84, radius: 14),
          SrSkeletonBox(height: 84, radius: 14),
          SrSkeletonBox(height: 84, radius: 14),
        ],
      ),
    };
  }
}

class _QuickTiles extends ConsumerWidget {
  const _QuickTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    bool can(AppModule module) =>
        ref.watch(moduleAccessProvider(module)).canView;
    return SalesTileRow(
      tiles: [
        SalesTile(
          icon: Icons.request_quote_outlined,
          label: l10n.salesQuotations,
          onTap: () => context.push(Routes.quotations),
        ),
        if (can(AppModule.order))
          SalesTile(
            icon: Icons.inventory_2_outlined,
            label: l10n.salesOrders,
            onTap: () => showOrdersSheet(context),
          ),
        if (can(AppModule.invoice))
          SalesTile(
            icon: Icons.receipt_long_outlined,
            label: l10n.salesBills,
            onTap: () => showInvoicesSheet(context),
          ),
        if (can(AppModule.collection))
          SalesTile(
            icon: Icons.payments_outlined,
            label: l10n.salesCollection,
            onTap: () => context.push(Routes.collection),
          ),
      ],
    );
  }
}

/// A titled card of up to three rows, with its own loading and error.
class _Section<T> extends StatelessWidget {
  const _Section({
    required this.title,
    required this.value,
    required this.row,
    required this.empty,
    required this.onRetry,
    this.onSeeAll,
    this.seeAllLabel,
  });

  final String title;
  final AsyncValue<List<T>> value;
  final Widget Function(T item) row;
  final String empty;
  final VoidCallback onRetry;
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final Widget body = switch (value) {
      AsyncValue(:final value?) when value.isEmpty => SrCard(
        child: Text(empty, style: AppText.meta(c.ink2, size: 13)),
      ),
      AsyncValue(:final value?) => SrRowGroup(
        rows: [for (final item in value) row(item)],
        dividerIndent: 66,
      ),
      AsyncValue(:final error?) => SrErrorState(
        error: error,
        compact: true,
        onRetry: onRetry,
      ),
      _ => const SrSkeletonList(
        count: 3,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SrSectionHeader(
          title: title,
          actionLabel: onSeeAll == null
              ? null
              : seeAllLabel ?? context.l10n.commonSeeAll,
          onAction: onSeeAll,
        ),
        const SizedBox(height: 8),
        body,
      ],
    );
  }
}

class _ProductsSection extends ConsumerWidget {
  const _ProductsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final list = ref.watch(productListProvider('', null));
    final total = list.value?.totalCount ?? 0;
    return _Section(
      title: l10n.salesProductsTitle,
      value: list.whenData((paged) => paged.items.take(3).toList()),
      row: (product) => ProductRow(
        product: product,
        priceList: PriceList.list,
        showStock: true,
        onTap: () => context.push(Routes.products),
      ),
      empty: l10n.salesProductsEmpty,
      onRetry: () => ref.invalidate(productListProvider('', null)),
      onSeeAll: () => context.push(Routes.products),
      seeAllLabel: l10n.salesAllCount(fmt.number(total)),
    );
  }
}

class _AwaitingSection extends ConsumerWidget {
  const _AwaitingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _Section(
      title: l10n.salesAwaitingReply,
      value: ref.watch(awaitingQuotationsProvider),
      row: (quotation) => QuotationRow(
        quotation: quotation,
        onTap: () => context.push(Routes.quotationFor(quotation.id)),
      ),
      empty: l10n.salesAwaitingEmpty,
      onRetry: () => ref.invalidate(awaitingQuotationsProvider),
      onSeeAll: () => context.push(Routes.quotations),
    );
  }
}

class _ToDeliverSection extends ConsumerWidget {
  const _ToDeliverSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _Section(
      title: l10n.salesToDeliver,
      value: ref
          .watch(orderListProvider(toDeliver: true))
          .whenData((paged) => paged.items.take(3).toList()),
      row: (order) => OrderRow(
        order: order,
        onTap: () => context.push(Routes.orderFor(order.id)),
      ),
      empty: l10n.salesToDeliverEmpty,
      onRetry: () => ref.invalidate(orderListProvider(toDeliver: true)),
      onSeeAll: () => showOrdersSheet(context, toDeliver: true),
    );
  }
}

class _DuesSection extends ConsumerWidget {
  const _DuesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _Section(
      title: l10n.salesCollectionsDue,
      value: ref
          .watch(dueListProvider)
          .whenData((paged) => paged.items.take(3).toList()),
      row: (due) => DueRowTile(
        due: due,
        onTap: () => context.push(collectionNewForDue(due)),
      ),
      empty: l10n.salesDuesEmpty,
      onRetry: () => ref.invalidate(dueListProvider),
      onSeeAll: () => context.push(Routes.collection),
    );
  }
}
