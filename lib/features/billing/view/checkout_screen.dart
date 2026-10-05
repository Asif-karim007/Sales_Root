import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/billing_catalog.dart';
import 'package:salesroot/features/billing/models/checkout.dart';
import 'package:salesroot/features/billing/models/subscription.dart';
import 'package:salesroot/features/billing/providers/billing_providers.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/billing_labels.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Where bank transfers and cards are paid.
const String billingWebUrl = 'https://app.salesrootcrm.com/billing';

/// #100 Order review and payment, with referral credits (#189). The server
/// prices the order; the gateway's page opens to pay.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key, required this.request});

  final CheckoutRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(checkoutDataProvider);
    final flow = ref.watch(checkoutFlowProvider);
    ref.listen(checkoutFlowProvider, (previous, next) {
      if (previous?.phase == next.phase) return;
      final url = next.result?.paymentUrl;
      if (next.phase == CheckoutPhase.awaitingPayment && url != null) {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
      if (next.phase != CheckoutPhase.done) return;
      context.pushReplacement(
        Uri(
          path: Routes.planActivated,
          queryParameters: {'invoice': ?next.result?.invoiceId},
        ).toString(),
      );
    });
    final quote = data.hasValue
        ? ref.watch(
            checkoutQuoteProvider(request, flow.method, flow.useCredits),
          )
        : null;
    final priced = quote?.value;

    return PopScope(
      canPop: flow.phase != CheckoutPhase.processing,
      child: SrScaffold(
        appBar: SrAppBar(
          title: l10n.billingOrderTitle,
          actions: const [BillingLanguageAction()],
        ),
        footer: priced == null || request.isEmpty
            ? null
            : _PayButton(request: request, quote: priced, flow: flow),
        body: request.isEmpty
            ? const _NothingToPay()
            : SrAsyncView(
                value: data,
                onRetry: () => ref.invalidate(checkoutDataProvider),
                loading: (_) => const SrSkeletonList(count: 2, cards: true),
                data: (context, loaded) => SrAsyncView(
                  value: quote ?? const AsyncLoading<Quote>(),
                  onRetry: () => ref.invalidate(
                    checkoutQuoteProvider(
                      request,
                      flow.method,
                      flow.useCredits,
                    ),
                  ),
                  loading: (_) => const SrSkeletonList(count: 2, cards: true),
                  data: (context, quote) => quote.lines.isEmpty
                      ? const _NothingToPay()
                      : _CheckoutBody(
                          data: loaded,
                          quote: quote,
                          flow: flow,
                          request: request,
                        ),
                ),
              ),
      ),
    );
  }
}

class _NothingToPay extends StatelessWidget {
  const _NothingToPay();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SrEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: l10n.billingNothingToPay,
        actionLabel: l10n.billingSeePlans,
        onAction: () => context.pushReplacement(Routes.planChoose),
      ),
    );
  }
}

class _PayButton extends ConsumerWidget {
  const _PayButton({
    required this.request,
    required this.quote,
    required this.flow,
  });

  final CheckoutRequest request;
  final Quote quote;
  final CheckoutFlow flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(checkoutFlowProvider.notifier);
    final method = flow.method;
    final web = !method.inApp && !quote.isFree;
    final awaiting = flow.phase == CheckoutPhase.awaitingPayment;
    final label = switch (quote) {
      _ when awaiting => l10n.billingCheckPayment,
      Quote(lines: []) => l10n.billingNothingToPay,
      Quote(isFree: true) => l10n.billingActivateNow,
      _ when web => l10n.billingContinueWeb,
      _ => l10n.billingPayWith(
        context.fmt.money(quote.total),
        context.methodName(method),
      ),
    };
    return SrButton(
      label: label,
      expand: true,
      loading: flow.phase == CheckoutPhase.processing,
      onPressed: quote.lines.isEmpty
          ? null
          : awaiting
          ? notifier.confirm
          : web
          ? () => launchUrl(
              Uri.parse(billingWebUrl),
              mode: LaunchMode.externalApplication,
            )
          : () => notifier.pay(request),
    );
  }
}

class _CheckoutBody extends ConsumerWidget {
  const _CheckoutBody({
    required this.data,
    required this.quote,
    required this.flow,
    required this.request,
  });

  final CheckoutData data;
  final Quote quote;
  final CheckoutFlow flow;
  final CheckoutRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(checkoutFlowProvider.notifier);
    final method = flow.method;
    final busy =
        flow.phase == CheckoutPhase.processing ||
        flow.phase == CheckoutPhase.awaitingPayment;
    final failure = flow.failure;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        if (busy) ...[
          SrNote(
            icon: Icons.hourglass_top_rounded,
            title: l10n.billingWaiting(context.methodName(method)),
            message: l10n.billingWaitingBody,
          ),
          const SizedBox(height: 12),
        ],
        if (flow.phase == CheckoutPhase.failed && failure != null) ...[
          _PaymentFailed(
            failure: failure,
            onRetry: failure.isConflict
                ? () {
                    ref.invalidate(checkoutDataProvider);
                    notifier.backToReview();
                  }
                : flow.result != null
                ? notifier.confirm
                : () => notifier.pay(request),
          ),
          const SizedBox(height: 12),
        ],
        _OrderCard(quote: quote),
        if (data.walletBalance > 0) ...[
          const SizedBox(height: 12),
          _CreditsToggle(
            balance: data.walletBalance,
            method: method,
            value: flow.useCredits,
            onChanged: busy ? null : notifier.setUseCredits,
          ),
        ],
        if (!quote.isFree) ...[
          const SizedBox(height: 18),
          SrSectionHeader(
            title: quote.credits > 0
                ? l10n.billingPayRestWith
                : l10n.billingPaymentMethod,
          ),
          const SizedBox(height: 8),
          _Methods(
            selected: method,
            onSelect: busy ? null : notifier.selectMethod,
          ),
        ],
        const SizedBox(height: 12),
        if (quote.credits > 0)
          SrNote(message: l10n.billingCreditsFailNote)
        else
          SrNote(
            message: request.cycle == BillingCycle.yearly
                ? l10n.billingRenewYearlyNote
                : l10n.billingRenewMonthlyNote,
          ),
      ],
    );
  }
}

class _PaymentFailed extends StatelessWidget {
  const _PaymentFailed({required this.failure, required this.onRetry});

  final ApiFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (failure.isOffline) {
      return SrErrorState(error: failure, onRetry: onRetry, compact: true);
    }
    return SrNote(
      tone: SrNoteTone.err,
      title: failure.isConflict
          ? l10n.billingPriceChanged
          : l10n.billingPaymentFailed,
      message: failure.message.isEmpty
          ? l10n.billingPaymentFailedBody
          : failure.message,
      action: SrButton(
        label: failure.isConflict ? l10n.billingReviewAgain : l10n.commonRetry,
        size: SrButtonSize.sm,
        variant: SrButtonVariant.secondary,
        onPressed: onRetry,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    return SrCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (final line in quote.lines)
            BillingLine(
              label: line.item,
              value: context.signedMoney(line.amount),
            ),
          if (quote.credits > 0)
            BillingLine(
              label: l10n.billingCreditsApplied,
              value: context.signedMoney(-quote.credits),
              valueColor: c.success,
            ),
          BillingLine(
            label: l10n.billingVat(fmt.number(quote.vatPercent)),
            value: fmt.money(quote.vat),
          ),
          BillingLine(
            label: l10n.billingPayToday,
            value: fmt.money(quote.total),
            total: true,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _CreditsToggle extends StatelessWidget {
  const _CreditsToggle({
    required this.balance,
    required this.method,
    required this.value,
    required this.onChanged,
  });

  final int balance;
  final PaymentKind method;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return SrCard(
      tone: SrCardTone.gold,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.card_giftcard_rounded, color: c.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.billingUseCredits, style: AppText.rowTitle(c.ink)),
                Text(
                  l10n.billingUseCreditsBody(
                    context.fmt.money(balance),
                    context.methodName(method),
                  ),
                  style: AppText.meta(c.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SrSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Methods extends StatelessWidget {
  const _Methods({required this.selected, required this.onSelect});

  final PaymentKind selected;
  final ValueChanged<PaymentKind>? onSelect;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final onSelect = this.onSelect;

    String subtitle(PaymentKind kind) => switch (kind) {
      PaymentKind.bank => billingWebUrl.split('//').last,
      PaymentKind.card => l10n.billingCardNote,
      _ => l10n.billingConfirmPin,
    };

    return SrCard(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          for (final kind in PaymentKind.values)
            SrListRow(
              title: context.methodName(kind),
              subtitle: subtitle(kind),
              leading: SrAvatar(
                icon: _icon(kind),
                square: true,
                tone: kind == selected
                    ? SrAvatarTone.accent
                    : SrAvatarTone.neutral,
              ),
              trailing: kind == selected
                  ? Icon(Icons.check_circle_rounded, color: c.accent)
                  : null,
              divider: kind != PaymentKind.values.last,
              onTap: onSelect == null ? null : () => onSelect(kind),
            ),
        ],
      ),
    );
  }

  static IconData _icon(PaymentKind kind) => switch (kind) {
    PaymentKind.bkash ||
    PaymentKind.nagad => Icons.account_balance_wallet_outlined,
    PaymentKind.card => Icons.credit_card_rounded,
    PaymentKind.bank => Icons.account_balance_outlined,
  };
}
