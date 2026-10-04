import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/features/hr/models/payroll.dart';
import 'package:salesroot/features/hr/providers/payroll_providers.dart';
import 'package:salesroot/features/hr/view/widget/hr_feedback.dart';
import 'package:salesroot/features/hr/view/widget/hr_labels.dart';
import 'package:salesroot/features/hr/view/widget/hr_language_toggle.dart';
import 'package:salesroot/features/hr/view/widget/hr_line.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

/// #158 `employeecard`: job details, salary structure and payout. Only the
/// owner, a payroll manager and the employee can open it.
class EmployeeCardScreen extends ConsumerWidget {
  const EmployeeCardScreen({super.key, this.employeeId});

  final int? employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final card = ref.watch(employeeCardProvider(employeeId));
    final loaded = card.value;

    return SrScaffold(
      appBar: SrAppBar(
        title: loaded?.name.of(fmt.isBangla) ?? l10n.hrCardTitle,
        subtitle: loaded == null ? null : l10n.hrCardTitle,
        actions: [
          const HrLanguageToggle(),
          if (loaded != null && loaded.canEdit)
            SrIconButton(
              icon: Icons.edit_outlined,
              tooltip: l10n.hrCardEdit,
              onTap: () => showSrSheet<void>(
                context: context,
                builder: (_) => _SalarySheet(card: loaded),
              ),
            ),
        ],
      ),
      body: SrAsyncView(
        value: card,
        onRetry: () => ref.invalidate(employeeCardProvider(employeeId)),
        loading: (_) => const SrSkeletonList(count: 8),
        data: (context, value) =>
            _CardBody(card: value, employeeId: employeeId),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.card, required this.employeeId});

  final EmployeeCard card;
  final int? employeeId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final designation = card.designation;
    final joined = card.joinedOn;
    final reportsTo = card.reportsTo;
    final id = employeeId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SrMetrics.gutter,
        16,
        SrMetrics.gutter,
        24,
      ),
      children: [
        HrLineCard(
          lines: [
            HrLine(label: l10n.hrCardId, value: card.employeeCode),
            if (designation != null)
              HrLine(label: l10n.hrCardDesignation, value: designation),
            if (joined != null)
              HrLine(label: l10n.hrCardJoined, value: fmt.date(joined)),
            HrLine(label: l10n.hrCardDuty, value: _duty(context)),
            if (reportsTo != null)
              HrLine(
                label: l10n.hrCardReportsTo,
                value: reportsTo.of(fmt.isBangla),
              ),
          ],
        ),
        const SizedBox(height: 18),
        SrSectionHeader(
          title: l10n.hrCardSalary,
          actionLabel: l10n.hrCardPayslips,
          onAction: () => context.push(
            id == null ? Routes.payslip : '${Routes.payslip}?memberId=$id',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.hrCardPayrollOnly,
          style: AppText.meta(SrColors.of(context).ink3, size: 12),
        ),
        const SizedBox(height: 8),
        HrLineCard(
          lines: [
            HrLine(label: l10n.hrCardBasic, value: fmt.money(card.basic)),
            HrLine(
              label: l10n.hrCardHouseRent,
              value: fmt.money(card.houseRent),
            ),
            HrLine(
              label: l10n.hrCardConveyance,
              value: fmt.money(card.conveyance),
            ),
            HrLine(
              label: l10n.hrCardCommission,
              value: l10n.hrCardCommissionValue(fmt.rate(card.commissionRate)),
            ),
            HrLine(label: l10n.hrCardPf, value: fmt.money(card.providentFund)),
          ],
        ),
        const SizedBox(height: 12),
        HrLineCard(
          lines: [
            HrLine(
              label: l10n.hrCardPayout,
              value: [
                card.payoutMethod,
                card.payoutAccount,
              ].whereType<String>().join(' '),
            ),
            HrLine(
              label: l10n.hrCardAdvance,
              value: card.advanceOutstanding <= 0
                  ? l10n.hrCardNone
                  : l10n.hrCardAdvanceValue(
                      fmt.money(card.advanceOutstanding),
                      fmt.number(card.advanceInstallments),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SrNote(
          tone: SrNoteTone.gold,
          icon: Icons.lock_outline_rounded,
          message: l10n.hrCardPrivacy,
        ),
      ],
    );
  }

  /// "9:00–18:00 · Sat–Thu"
  String _duty(BuildContext context) {
    final fmt = context.fmt;
    final weekday = DateFormat.E(fmt.locale.languageCode);
    final firstDay = card.weeklyOff % 7 + 1;
    final lastDay = (card.weeklyOff + 5) % 7 + 1;
    DateTime on(int weekday) => DateTime(2026, 6, weekday);
    return '${fmt.clock(card.dutyStart)}–${fmt.clock(card.dutyEnd)}'
        ' · ${weekday.format(on(firstDay))}–${weekday.format(on(lastDay))}';
  }
}

/// Edits the salary structure; owner only.
class _SalarySheet extends ConsumerStatefulWidget {
  const _SalarySheet({required this.card});

  final EmployeeCard card;

  @override
  ConsumerState<_SalarySheet> createState() => _SalarySheetState();
}

class _SalarySheetState extends ConsumerState<_SalarySheet> {
  late final _basic = _controller(widget.card.basic);
  late final _houseRent = _controller(widget.card.houseRent);
  late final _conveyance = _controller(widget.card.conveyance);
  late final _commission = TextEditingController(
    text: _plain(widget.card.commissionRate),
  );
  late final _pf = _controller(widget.card.providentFund);
  bool _showErrors = false;

  static TextEditingController _controller(double value) =>
      TextEditingController(text: value.round().toString());

  static String _plain(double value) =>
      value % 1 == 0 ? value.round().toString() : value.toString();

  @override
  void dispose() {
    for (final c in [_basic, _houseRent, _conveyance, _commission, _pf]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final basic = double.tryParse(_basic.text);
    if (basic == null || basic <= 0) {
      setState(() => _showErrors = true);
      return;
    }
    ref
        .read(salaryEditProvider.notifier)
        .save(
          widget.card.employeeId,
          SalaryInput(
            basic: basic,
            houseRent: double.tryParse(_houseRent.text) ?? 0,
            conveyance: double.tryParse(_conveyance.text) ?? 0,
            commissionRate: double.tryParse(_commission.text) ?? 0,
            providentFund: double.tryParse(_pf.text) ?? 0,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saving = ref.watch(salaryEditProvider).isLoading;

    ref.listen(salaryEditProvider, (_, next) {
      switch (next) {
        case AsyncData(value: final EmployeeCard _):
          showSrSuccess(context, l10n.hrCardSaved);
          Navigator.of(context).pop();
        case AsyncError(:final error):
          showHrFailure(context, error);
        default:
      }
    });

    final money = [FilteringTextInputFormatter.digitsOnly];
    return SrSheet(
      title: l10n.hrCardEdit,
      subtitle: widget.card.name.of(context.fmt.isBangla),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SrTextField(
              controller: _basic,
              label: l10n.hrCardBasic,
              keyboardType: TextInputType.number,
              inputFormatters: money,
              error: _showErrors ? l10n.hrCardBasicError : null,
            ),
            const SizedBox(height: 12),
            SrTextField(
              controller: _houseRent,
              label: l10n.hrCardHouseRent,
              keyboardType: TextInputType.number,
              inputFormatters: money,
            ),
            const SizedBox(height: 12),
            SrTextField(
              controller: _conveyance,
              label: l10n.hrCardConveyance,
              keyboardType: TextInputType.number,
              inputFormatters: money,
            ),
            const SizedBox(height: 12),
            SrTextField(
              controller: _commission,
              label: l10n.hrCardCommissionRate,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            const SizedBox(height: 12),
            SrTextField(
              controller: _pf,
              label: l10n.hrCardPf,
              keyboardType: TextInputType.number,
              inputFormatters: money,
            ),
            const SizedBox(height: 16),
            SrButton(
              label: l10n.commonSave,
              expand: true,
              loading: saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
