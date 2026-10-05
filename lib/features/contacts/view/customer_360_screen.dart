import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/contacts/models/customer.dart';
import 'package:salesroot/features/contacts/providers/customer_providers.dart';
import 'package:salesroot/features/contacts/view/widget/contact_rows.dart';
import 'package:salesroot/features/contacts/view/widget/contacts_header.dart';
import 'package:salesroot/features/contacts/view/widget/customer_timeline.dart';
import 'package:salesroot/features/contacts/view/widget/detail_parts.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #48: everything about one customer — money, deals, documents, visits and
/// the timeline — in one place.
class Customer360Screen extends ConsumerWidget {
  const Customer360Screen({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(customerSummaryProvider(companyId));
    final loaded = summary.value;

    return SrScaffold(
      appBar: SrAppBar(
        title: loaded?.companyName ?? l10n.contactsCustomer360,
        subtitle: l10n.contactsCustomer360Subtitle,
        actions: [
          const ContactsLanguageToggle(),
          SrIconButton(
            icon: Icons.folder_open_outlined,
            tooltip: l10n.contactsDocuments,
            onTap: () => context.push(Routes.customerDocumentsFor(companyId)),
          ),
        ],
      ),
      footer: loaded == null ? null : _Footer(summary: loaded),
      body: SrAsyncView<CustomerSummary>(
        value: summary,
        onRetry: () => ref.invalidate(customerSummaryProvider(companyId)),
        data: (context, summary) => RefreshIndicator(
          color: SrColors.of(context).accent,
          onRefresh: () =>
              ref.refresh(customerSummaryProvider(companyId).future),
          child: _Body(summary: summary),
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.summary});

  final CustomerSummary summary;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  CustomerEventGroup _group = CustomerEventGroup.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final c = SrColors.of(context);
    final summary = widget.summary;
    final events = _group == CustomerEventGroup.all
        ? summary.events
        : summary.events.where((e) => e.kind.group == _group).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            KpiStrip(
              cells: [
                KpiCell(
                  l10n.contactsTotalSales,
                  fmt.moneyCompact(summary.totalSales),
                ),
                KpiCell(
                  l10n.contactsCollected,
                  fmt.moneyCompact(summary.collected),
                  color: c.success,
                ),
                KpiCell(
                  l10n.contactsOutstanding,
                  fmt.moneyCompact(summary.outstanding),
                  color: summary.outstanding > 0 ? c.danger : null,
                ),
                KpiCell(
                  l10n.contactsOverdue,
                  fmt.moneyCompact(summary.overdue),
                  color: summary.overdue > 0 ? c.danger : null,
                ),
              ],
            ),
            _ValueLine(summary: summary),
            _Tiles(summary: summary),
            SrChipRow(
              padding: EdgeInsets.zero,
              chips: [
                SrChipItem(l10n.commonAll),
                SrChipItem(l10n.contactsTimelineMoney),
                SrChipItem(l10n.contactsTimelineTalk),
                SrChipItem(l10n.contactsTimelineVisits),
                SrChipItem(l10n.contactsTimelineDocuments),
              ],
              index: _group.index,
              onChanged: (index) =>
                  setState(() => _group = CustomerEventGroup.values[index]),
            ),
            if (events.isEmpty)
              SectionEmpty(l10n.contactsTimelineEmpty)
            else
              CustomerTimeline(events: events),
          ],
        ),
      ],
    );
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.summary});

  final CustomerSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final c = SrColors.of(context);
    return SrCard(
      tone: SrCardTone.tint,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, size: 18, color: c.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.contactsValueLine(
                fmt.moneyCompact(summary.totalSales),
                fmt.moneyCompact(summary.openDealValue),
                fmt.number(summary.visitCount),
              ),
              style: AppText.meta(c.ink, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tiles extends ConsumerWidget {
  const _Tiles({required this.summary});

  final CustomerSummary summary;

  void _showLeads(BuildContext context) => showSrSheet<void>(
    context: context,
    builder: (_) => SrSheet(
      title: context.l10n.contactsDeals,
      child: summary.leads.isEmpty
          ? SectionEmpty(context.l10n.contactsNoLeads)
          : SingleChildScrollView(
              child: SrRowGroup(
                rows: [
                  for (final lead in summary.leads) LinkedLeadRow(lead: lead),
                ],
              ),
            ),
    ),
  );

  void _showDocs(
    BuildContext context, {
    required String title,
    required List<SalesDocRef> docs,
    required String Function(String id)? routeOf,
  }) => showSrSheet<void>(
    context: context,
    builder: (_) => SrSheet(
      title: title,
      child: docs.isEmpty
          ? SectionEmpty(context.l10n.contactsNothingYet)
          : SingleChildScrollView(
              child: SrRowGroup(
                rows: [
                  for (final doc in docs) _DocRow(doc: doc, routeOf: routeOf),
                ],
              ),
            ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    bool can(AppModule module) =>
        ref.watch(moduleAccessProvider(module)).canView;
    final canLeads = can(AppModule.lead);

    return ActionTiles(
      tiles: [
        ActionTileData(
          icon: Icons.handshake_outlined,
          label: l10n.contactsDeals,
          count: fmt.number(summary.openDeals.length),
          onTap: canLeads ? () => _showLeads(context) : null,
        ),
        ActionTileData(
          icon: Icons.request_quote_outlined,
          label: l10n.contactsQuotes,
          count: fmt.number(summary.quotations.length),
          onTap: can(AppModule.quotation)
              ? () => _showDocs(
                  context,
                  title: l10n.contactsQuotes,
                  docs: summary.quotations,
                  routeOf: Routes.quotationFor,
                )
              : null,
        ),
        ActionTileData(
          icon: Icons.inventory_2_outlined,
          label: l10n.contactsOrders,
          count: fmt.number(summary.orders.length),
          onTap: can(AppModule.order)
              ? () => _showDocs(
                  context,
                  title: l10n.contactsOrders,
                  docs: summary.orders,
                  routeOf: Routes.orderFor,
                )
              : null,
        ),
        ActionTileData(
          icon: Icons.receipt_long_outlined,
          label: l10n.contactsInvoices,
          count: fmt.number(summary.invoices.length),
          onTap: can(AppModule.invoice)
              ? () => _showDocs(
                  context,
                  title: l10n.contactsInvoices,
                  docs: summary.invoices,
                  routeOf: Routes.invoiceFor,
                )
              : null,
        ),
      ],
    );
  }
}

String docStatusLabel(AppLocalizations l10n, String? status) =>
    switch (status) {
      'draft' => l10n.contactsStatusDraft,
      'sent' => l10n.contactsStatusSent,
      'accepted' => l10n.contactsStatusAccepted,
      'confirmed' || 'processing' => l10n.contactsStatusProcessing,
      'delivered' => l10n.contactsStatusDelivered,
      'paid' => l10n.contactsStatusPaid,
      'partial' => l10n.contactsStatusPartial,
      'due' || 'unpaid' || 'overdue' => l10n.contactsStatusUnpaid,
      'cancelled' => l10n.contactsStatusCancelled,
      _ => status ?? '',
    };

class _DocRow extends StatelessWidget {
  const _DocRow({required this.doc, required this.routeOf});

  final SalesDocRef doc;
  final String Function(String id)? routeOf;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final route = routeOf;
    final due = doc.dueOn;
    return SrListRow(
      title: doc.number,
      subtitle: [
        fmt.date(doc.on),
        docStatusLabel(l10n, doc.status),
      ].where((part) => part.isNotEmpty).join(' · '),
      chevron: route != null,
      onTap: route == null
          ? null
          : () {
              Navigator.of(context).pop();
              context.push(route(doc.id));
            },
      trailing: SrRowTrailing(
        value: fmt.moneyCompact(doc.amount),
        meta: due == null || doc.due <= 0
            ? null
            : l10n.contactsDueOn(fmt.moneyCompact(doc.due), fmt.dayMonth(due)),
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.summary});

  final CustomerSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canCollect = ref
        .watch(moduleAccessProvider(AppModule.collection))
        .canAdd;
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: SrButton(
            label: l10n.contactsDocuments,
            variant: SrButtonVariant.secondary,
            expand: true,
            onPressed: () =>
                context.push(Routes.customerDocumentsFor(summary.companyId)),
          ),
        ),
        if (canCollect && summary.outstanding > 0)
          Expanded(
            child: SrButton(
              label: l10n.contactsCollectPayment,
              expand: true,
              onPressed: () => context.push(
                '${Routes.collectionNew}?customerId=${summary.companyId}',
              ),
            ),
          ),
      ],
    );
  }
}
