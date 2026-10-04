import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/pdf/sales_pdf.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_wizard.dart';
import 'package:salesroot/features/sales/view/sales_labels.dart';
import 'package:salesroot/features/sales/view/widget/pdf_sheet.dart';
import 'package:salesroot/features/sales/view/widget/quote_items_step.dart';
import 'package:salesroot/features/sales/view/widget/quote_review_step.dart';
import 'package:salesroot/features/sales/view/widget/quote_terms_step.dart';
import 'package:salesroot/features/sales/view/widget/sales_failure.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #52–54: a new quotation (or a copy, or the next version) in three steps.
class QuotationWizardScreen extends ConsumerWidget {
  const QuotationWizardScreen({
    super.key,
    this.leadId,
    this.fromId,
    this.revise = false,
  });

  final int? leadId;
  final int? fromId;
  final bool revise;

  QuotationWizardProvider get _provider =>
      quotationWizardProvider(leadId: leadId, fromId: fromId, revise: revise);

  Future<void> _saved(
    BuildContext context,
    WidgetRef ref,
    Quotation quotation,
    SendChannel? via,
  ) async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    if (via == null) {
      showSrSuccess(context, l10n.salesDraftSaved);
    } else {
      try {
        final seller = await ref.read(sellerProfileProvider.future);
        final bytes = await SalesPdf(l10n, fmt).quotation(quotation, seller);
        await shareSalesPdf(
          bytes: bytes,
          fileName: '${quotation.number}.pdf',
          text: l10n.salesQuotationShareText(
            quotation.number,
            fmt.money(quotation.totals.total),
          ),
          subject: l10n.salesQuotationNumber(quotation.number),
        );
      } on Exception {
        if (context.mounted) showSrError(context, l10n.salesPdfFailed);
      }
    }
    if (!context.mounted) return;
    if (revise) {
      context.pop();
    } else {
      context.pushReplacement(Routes.quotationFor(quotation.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(_provider);
    final wizard = ref.read(_provider.notifier);
    ref.listen(_provider.select((s) => s.value?.submission), (previous, next) {
      if (previous == next) return;
      switch (next) {
        case AsyncData(:final value):
          _saved(context, ref, value, ref.read(_provider).value?.sentVia);
        case AsyncError(:final error):
          showSalesFailure(context, error);
        default:
          break;
      }
    });
    final draft = state.value;
    return PopScope(
      canPop: draft == null || draft.step == QuotationStep.items,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) wizard.back();
      },
      child: SrScaffold(
        appBar: _WizardBar(
          draft: draft,
          onBack: () {
            if (!wizard.back()) context.pop();
          },
        ),
        body: SrAsyncView<QuotationDraft>(
          value: state,
          onRetry: () => ref.invalidate(_provider),
          onUpgrade: upgradeFor(context, state.error),
          data: (context, draft) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SrMetrics.gutter,
                  14,
                  SrMetrics.gutter,
                  0,
                ),
                child: SrSteps(
                  steps: [
                    l10n.salesStepItems,
                    l10n.salesStepTerms,
                    l10n.salesStepReview,
                  ],
                  current: draft.step.index,
                ),
              ),
              Expanded(
                child: switch (draft.step) {
                  QuotationStep.items => QuoteItemsStep(
                    draft: draft,
                    wizard: wizard,
                  ),
                  QuotationStep.terms => QuoteTermsStep(
                    draft: draft,
                    wizard: wizard,
                  ),
                  QuotationStep.review => QuoteReviewStep(
                    draft: draft,
                    wizard: wizard,
                  ),
                },
              ),
            ],
          ),
        ),
        footer: draft == null
            ? null
            : _WizardFooter(draft: draft, wizard: wizard),
      ),
    );
  }
}

class _WizardBar extends ConsumerWidget {
  const _WizardBar({required this.draft, required this.onBack});

  final QuotationDraft? draft;
  final VoidCallback onBack;

  String? _subtitle(BuildContext context) {
    final current = draft;
    if (current == null) return null;
    final l10n = context.l10n;
    final fmt = context.fmt;
    final revising = current.revising;
    return switch (current.step) {
      QuotationStep.items when current.hasItems => l10n.salesItemsSummary(
        fmt.number(current.itemCount),
        fmt.money(current.totals.subtotal),
      ),
      QuotationStep.terms when revising != null =>
        '${revising.number} · ${l10n.salesVersion(fmt.number(revising.version + 1))}',
      QuotationStep.terms => l10n.salesDraft,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final revising = draft?.revising;
    final step = draft?.step ?? QuotationStep.items;
    final locale = ref.watch(appLocaleProvider);
    return SrAppBar(
      title: switch (step) {
        QuotationStep.review => l10n.salesReviewTitle,
        _ when revising != null => l10n.salesNewVersionTitle,
        _ => l10n.salesNewQuotation,
      },
      subtitle: _subtitle(context),
      onBack: onBack,
      actions: [
        if (step == QuotationStep.items)
          SrLanguageToggle(
            isBangla: locale == bangla,
            onChanged: (isBangla) => ref
                .read(appLocaleProvider.notifier)
                .set(isBangla ? bangla : english),
          ),
      ],
    );
  }
}

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({required this.draft, required this.wizard});

  final QuotationDraft draft;
  final QuotationWizard wizard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (draft.step != QuotationStep.review) {
      return SrButton(
        label: l10n.commonNext,
        expand: true,
        onPressed: draft.canContinue ? wizard.next : null,
      );
    }
    final saving = draft.isSaving;
    final drafting = saving && draft.sentVia == null;
    return Row(
      children: [
        Expanded(
          child: SrButton(
            label: l10n.salesSaveDraft,
            variant: SrButtonVariant.secondary,
            loading: drafting,
            onPressed: saving ? null : () => wizard.submit(null),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SrButton(
            label: l10n.salesSendOn(l10n.channel(draft.channel)),
            loading: saving && !drafting,
            onPressed: saving ? null : () => wizard.submit(draft.channel),
          ),
        ),
      ],
    );
  }
}
