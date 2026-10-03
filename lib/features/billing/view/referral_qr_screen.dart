import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/billing/models/referral.dart';
import 'package:salesroot/features/billing/pdf/referral_card_pdf.dart';
import 'package:salesroot/features/billing/providers/referral_providers.dart';
import 'package:salesroot/features/billing/view/refer_screen.dart';
import 'package:salesroot/features/billing/view/widget/billing_bits.dart';
import 'package:salesroot/features/billing/view/widget/referral_widgets.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #187 Shop-counter QR card, printable as A5.
class ReferralQrScreen extends ConsumerWidget {
  const ReferralQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SrScaffold(
      appBar: SrAppBar(
        title: context.l10n.billingQrTitle,
        actions: const [BillingLanguageAction()],
      ),
      body: SrAsyncView(
        value: ref.watch(referralOverviewProvider),
        onRetry: () => ref.invalidate(referralOverviewProvider),
        loading: (_) => const SrSkeletonList(count: 1, cards: true),
        data: (context, overview) => _QrBody(overview: overview),
      ),
    );
  }
}

class _QrBody extends StatelessWidget {
  const _QrBody({required this.overview});

  final ReferralOverview overview;

  String _body(BuildContext context) => context.l10n.billingQrBody(
    context.fmt.money(overview.registerReward),
    context.fmt.number(overview.trialDays),
  );

  Future<void> _print(BuildContext context) async {
    final l10n = context.l10n;
    final bytes = await buildReferralCardPdf(
      brand: l10n.appName,
      code: overview.code,
      link: overview.link,
      body: _body(context),
      tip: l10n.billingQrTip,
    );
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      format: PdfPageFormat.a5,
      name: overview.code,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        SrCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco_rounded, color: c.accent),
                  const SizedBox(width: 8),
                  Text(l10n.appName, style: AppText.pageTitle(c.ink)),
                ],
              ),
              const SizedBox(height: 14),
              QrCodeView(data: overview.link),
              const SizedBox(height: 14),
              Text(overview.code, style: AppText.hero(c.ink, size: 24)),
              const SizedBox(height: 8),
              Text(
                _body(context),
                textAlign: TextAlign.center,
                style: AppText.lead(c.ink2),
              ),
              const SizedBox(height: 6),
              Text(
                overview.link.split('//').last,
                style: AppText.meta(c.ink2, size: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.billingQrTip,
          textAlign: TextAlign.center,
          style: AppText.lead(c.ink2),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SrButton(
                label: l10n.commonShare,
                icon: Icons.ios_share_rounded,
                variant: SrButtonVariant.secondary,
                expand: true,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: referralShareText(context, overview)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SrButton(
                label: l10n.billingPrintA5,
                icon: Icons.print_outlined,
                variant: SrButtonVariant.secondary,
                expand: true,
                onPressed: () => _print(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
