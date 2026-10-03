import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/billing/models/billing_overview.dart';
import 'package:salesroot/features/billing/models/invoice.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/features/billing/view/widget/invoice_pdf_viewer.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #104 Billing history: invoices as PDFs, the next renewal and the method.
class BillingHistoryScreen extends ConsumerWidget {
  const BillingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.billingHistoryTitle,
        actions: const [BillingLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(invoicesProvider),
        onRetry: () => ref.invalidate(invoicesProvider),
        isEmpty: (paged) => paged.isEmpty,
        empty: (context) => Center(
          child: SrEmptyState(
            icon: Icons.receipt_long_outlined,
            title: l10n.billingHistoryEmpty,
            message: l10n.billingHistoryEmptyBody,
            actionLabel: l10n.billingSeePlans,
            onAction: () => context.push(Routes.planChoose),
          ),
        ),
        data: (context, paged) => _HistoryBody(paged: paged),
      ),
    );
  }
}

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({required this.paged});

  final Paged<Invoice> paged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(invoicesProvider.notifier);
    final workspace = ref.watch(
      currentWorkspaceProvider.select((w) => w?.name ?? ''),
    );
    final items = paged.items;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(invoicesProvider.future),
      child: LoadMoreListener(
        onLoadMore: notifier.loadMore,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            SrCard(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  for (final invoice in items)
                    _InvoiceRow(
                      invoice: invoice,
                      last: invoice == items.last,
                      onTap: () => context.openPdf(
                        name: '${invoice.number}.pdf',
                        title: invoice.number,
                        load: () => context.invoicesPdf([invoice], workspace),
                      ),
                    ),
                ],
              ),
            ),
            LoadMoreFooter(
              loading: paged.isLoadingMore,
              error: paged.loadMoreError,
              onRetry: notifier.loadMore,
            ),
            const SizedBox(height: 12),
            const _RenewalCard(),
            const SizedBox(height: 12),
            _DownloadAll(workspace: workspace),
          ],
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.invoice,
    required this.last,
    required this.onTap,
  });

  final Invoice invoice;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final method = invoice.method;
    final retried = invoice.retriedAt;
    final paid = invoice.status == InvoiceStatus.paid;

    return SrListRow(
      title: context.invoiceTitle(invoice),
      subtitle: joinDot([
        fmt.dayMonth(invoice.issuedAt),
        if (method != null) context.methodName(method.kind),
        invoice.number,
        if (retried != null) l10n.billingRetried(fmt.dayMonth(retried)),
      ]),
      leading: SrAvatar(
        icon: paid ? Icons.check_rounded : Icons.undo_rounded,
        tone: paid ? SrAvatarTone.accent : SrAvatarTone.danger,
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SrRowTrailing(value: fmt.money(invoice.total)),
          const SizedBox(height: 4),
          SrTag(
            context.invoiceStatus(invoice.status),
            tone: paid ? SrTone.ok : SrTone.err,
          ),
        ],
      ),
      divider: !last,
      onTap: onTap,
    );
  }
}

class _RenewalCard extends ConsumerWidget {
  const _RenewalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(billingOverviewProvider).value;
    if (overview == null || overview.plan.isFree) {
      return const SizedBox.shrink();
    }
    return _RenewalLines(overview: overview);
  }
}

class _RenewalLines extends StatelessWidget {
  const _RenewalLines({required this.overview});

  final BillingOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final renewsAt = overview.subscription.renewsAt;
    final method = overview.subscription.paymentMethod;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          BillingLine(
            label: l10n.billingNextRenewal,
            value: joinDot([
              if (renewsAt != null) fmt.dayMonth(renewsAt),
              fmt.money(overview.renewal),
            ]),
            last: method == null,
          ),
          if (method != null)
            BillingLine(
              label: l10n.billingMethod,
              value: context.methodLine(method),
              last: true,
            ),
        ],
      ),
    );
  }
}

class _DownloadAll extends ConsumerStatefulWidget {
  const _DownloadAll({required this.workspace});

  final String workspace;

  @override
  ConsumerState<_DownloadAll> createState() => _DownloadAllState();
}

class _DownloadAllState extends ConsumerState<_DownloadAll> {
  static const _fileName = 'salesroot-receipts.pdf';

  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      final invoices = await ref.read(billingRepositoryProvider).receipts();
      if (!mounted) return;
      final bytes = await context.invoicesPdf(invoices, widget.workspace);
      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: _fileName);
    } on ApiFailure catch (failure) {
      if (mounted) showSrError(context, failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canExport = ref.watch(
      moduleAccessProvider(AppModule.billing).select((a) => a.canExport),
    );
    if (!canExport) return const SizedBox.shrink();
    return SrButton(
      label: context.l10n.billingDownloadAll,
      icon: Icons.download_rounded,
      variant: SrButtonVariant.secondary,
      expand: true,
      loading: _busy,
      onPressed: _download,
    );
  }
}
