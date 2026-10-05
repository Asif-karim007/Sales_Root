import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';
import 'package:salesroot/features/hr/models/payroll.dart';
import 'package:salesroot/features/hr/providers/payroll_providers.dart';
import 'package:salesroot/features/hr/view/payslip_pdf.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_language_toggle.dart';
import 'package:salesroot/features/hr/view/widget/hr_line.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #154 `payslip`: a month's earnings, deductions and net pay, with a PDF.
/// [employeeId] null is the signed-in employee.
class PayslipScreen extends ConsumerWidget {
  const PayslipScreen({super.key, this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final slips = ref.watch(payslipsProvider(employeeId));

    return SrScaffold(
      appBar: SrAppBar(
        title: l10n.hrPayslipTitle,
        actions: const [HrLanguageToggle()],
      ),
      body: SrAsyncView(
        value: slips,
        onRetry: () => ref.invalidate(payslipsProvider(employeeId)),
        loading: (_) => const SrSkeletonList(count: 6),
        isEmpty: (list) => list.isEmpty,
        empty: (_) => const _NotIssued(),
        data: (context, list) {
          final picked = ref.watch(payslipPickProvider(employeeId));
          return _MonthPayslip(
            employeeId: employeeId,
            slips: list,
            picked: list.where((s) => s.id == picked).firstOrNull ?? list.first,
          );
        },
      ),
    );
  }
}

class _NotIssued extends StatelessWidget {
  const _NotIssued();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SrEmptyState(
        icon: Icons.request_page_outlined,
        title: l10n.hrPayslipNotIssuedTitle,
        message: l10n.hrPayslipNotIssuedBody,
      ),
    );
  }
}

class _MonthPayslip extends ConsumerWidget {
  const _MonthPayslip({
    required this.employeeId,
    required this.slips,
    required this.picked,
  });

  final String? employeeId;
  final List<PayslipRef> slips;
  final PayslipRef picked;

  Future<void> _pickMonth(BuildContext context, WidgetRef ref) async {
    final fmt = context.fmt;
    final chosen = await showSrSheet<PayslipRef>(
      context: context,
      builder: (_) => SrOptionSheet<PayslipRef>(
        title: context.l10n.hrPayslipPickMonth,
        options: slips,
        labelOf: (s) => fmt.monthYear(s.period),
        isSelected: (s) => s.id == picked.id,
      ),
    );
    if (chosen == null) return;
    ref.read(payslipPickProvider(employeeId).notifier).set(chosen.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = payslipProvider(employeeId, picked.id);
    final slip = ref.watch(provider);

    return SrAsyncView(
      value: slip,
      onRetry: () => ref.invalidate(provider),
      loading: (_) => const SrSkeletonList(count: 6),
      isEmpty: (value) => value == null,
      empty: (_) => const _NotIssued(),
      data: (context, value) => value == null
          ? const _NotIssued()
          : _PayslipBody(
              slip: value,
              onPickMonth: slips.length > 1
                  ? () => _pickMonth(context, ref)
                  : null,
            ),
    );
  }
}

class _PayslipBody extends ConsumerStatefulWidget {
  const _PayslipBody({required this.slip, required this.onPickMonth});

  final Payslip slip;
  final VoidCallback? onPickMonth;

  @override
  ConsumerState<_PayslipBody> createState() => _PayslipBodyState();
}

class _PayslipBodyState extends ConsumerState<_PayslipBody> {
  bool _sharing = false;

  Future<void> _sharePdf() async {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final workspace = ref.read(currentWorkspaceProvider)?.name ?? '';
    setState(() => _sharing = true);
    try {
      await sharePayslipPdf(
        slip: widget.slip,
        l10n: l10n,
        fmt: fmt,
        workspace: workspace,
      );
    } on Exception catch (error) {
      if (mounted) showHrFailure(context, error);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final slip = widget.slip;
    final canAsk = ref.watch(moduleAccessProvider(AppModule.support)).canAdd;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        _NetCard(slip: slip, onPickMonth: widget.onPickMonth),
        const SizedBox(height: 18),
        SrSectionHeader(title: l10n.hrPayslipEarnings),
        const SizedBox(height: 8),
        HrLineCard(
          lines: [
            for (final line in slip.earnings)
              HrLine(
                label: line.label(l10n, fmt),
                value: fmt.money(line.amount),
              ),
          ],
        ),
        const SizedBox(height: 18),
        SrSectionHeader(title: l10n.hrPayslipDeductions),
        const SizedBox(height: 8),
        HrLineCard(
          lines: [
            for (final line in slip.deductions)
              HrLine(
                label: line.label(l10n, fmt),
                value: '− ${fmt.money(line.amount)}',
                valueColor: c.danger,
              ),
          ],
        ),
        const SizedBox(height: 12),
        HrLineCard(
          lines: [
            if (presentText(slip, fmt) case final present?)
              HrLine(label: l10n.hrPayslipPresent, value: present, small: true),
            HrLine(
              label: l10n.hrPayslipPaidVia,
              value: payoutText(slip, fmt),
              small: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SrButton(
                label: l10n.hrPayslipPdf,
                icon: Icons.picture_as_pdf_outlined,
                variant: SrButtonVariant.secondary,
                size: SrButtonSize.sm,
                expand: true,
                loading: _sharing,
                onPressed: _sharePdf,
              ),
            ),
            if (canAsk) ...[
              const SizedBox(width: 10),
              Expanded(
                child: SrButton(
                  label: l10n.hrPayslipQuestion,
                  icon: Icons.help_outline_rounded,
                  variant: SrButtonVariant.secondary,
                  size: SrButtonSize.sm,
                  expand: true,
                  onPressed: () => context.push(Routes.supportNew),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _NetCard extends StatelessWidget {
  const _NetCard({required this.slip, required this.onPickMonth});

  final Payslip slip;
  final VoidCallback? onPickMonth;

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    final fmt = context.fmt;
    final designation = slip.designation;

    return SrCard(
      tone: SrCardTone.tint,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: onPickMonth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fmt.monthYear(slip.period),
                        style: AppText.rowTitle(c.ink),
                      ),
                    ),
                    if (onPickMonth != null)
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: c.ink2,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (slip.employeeName.isNotEmpty) slip.employeeName,
                    ?designation,
                  ].join(' · '),
                  style: AppText.meta(c.ink2),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l10n.hrPayslipNet, style: AppText.label(c.ink2)),
              Text(
                fmt.money(slip.netPay),
                style: AppText.metric(c.ink, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
