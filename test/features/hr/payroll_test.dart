import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/hr/data/expense_fixtures.dart';
import 'package:salesroot/features/hr/data/leave_fixtures.dart';
import 'package:salesroot/features/hr/data/payroll_fixtures.dart';
import 'package:salesroot/features/hr/models/expense.dart';
import 'package:salesroot/features/hr/models/leave.dart';
import 'package:salesroot/features/hr/models/payroll.dart';
import 'package:salesroot/features/hr/providers/payroll_providers.dart';
import 'package:salesroot/features/hr/view/payslip_pdf.dart';
import 'package:salesroot/l10n/l10n.dart';

import 'hr_test_utils.dart';

void main() {
  test('net pay is earnings minus deductions', () {
    const slip = Payslip(
      employeeId: 1,
      employeeName: LocalizedName('Bushra Nowshin', 'বুশরা নওশিন'),
      year: 2026,
      month: 9,
      netPay: 34750,
      lines: [
        PayslipLine(code: PayslipLineCode.basic, amount: 25000),
        PayslipLine(code: PayslipLineCode.houseRent, amount: 7500),
        PayslipLine(code: PayslipLineCode.conveyance, amount: 2000),
        PayslipLine(code: PayslipLineCode.commission, amount: 3100),
        PayslipLine(code: PayslipLineCode.reimbursement, amount: 1450),
        PayslipLine(code: PayslipLineCode.unpaidLeave, amount: 1150),
        PayslipLine(code: PayslipLineCode.late, amount: 0, count: 2),
        PayslipLine(code: PayslipLineCode.advanceRecovery, amount: 3000),
        PayslipLine(code: PayslipLineCode.providentFund, amount: 150),
      ],
    );

    expect(slip.totalEarnings, 39050);
    expect(slip.totalDeductions, 4300);
    expect(slip.totalEarnings - slip.totalDeductions, slip.netPay);
  });

  test(
    'every issued payslip balances, with commission from won deals',
    () async {
      final container = await hrContainer();
      final repository = container.read(payrollRepositoryProvider);
      final graph = container.read(seedGraphProvider);
      final card = await repository.employeeCard();
      final months = await repository.payslipMonths();

      expect(months, isNotEmpty);
      expect(
        months.first.month,
        DateTime(graph.anchor.year, graph.anchor.month - 1).month,
      );
      for (final month in months) {
        final slip = await repository.payslip(month);
        expect(slip, isNotNull);
        if (slip == null) continue;
        expect(slip.netPay, slip.totalEarnings - slip.totalDeductions);
        final won = graph.leads.where(
          (l) =>
              l.ownerId == SeedGraph.meId &&
              l.stageId == 5 &&
              wonOn(graph, l).year == month.year &&
              wonOn(graph, l).month == month.month,
        );
        final expected =
            (won.fold<int>(0, (sum, l) => sum + l.value) *
                    card.commissionRate /
                    100)
                .roundToDouble();
        final commission = slip.earnings
            .where((l) => l.code == PayslipLineCode.commission)
            .fold<double>(0, (sum, l) => sum + l.amount);
        expect(commission, expected);
      }
    },
  );

  test('the payslip PDF builds with the bundled font', () async {
    final container = await hrContainer();
    final repository = container.read(payrollRepositoryProvider);
    final month = (await repository.payslipMonths()).first;
    final slip = await repository.payslip(month);
    expect(slip, isNotNull);
    if (slip == null) return;
    const locale = Locale('bn');
    await initializeDateFormatting('bn');
    final l10n = lookupAppLocalizations(locale);

    final bytes = await buildPayslipPdf(
      slip,
      l10n,
      AppFormat(l10n, locale),
      'Dhaka Sales',
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('the current month is not issued yet', () async {
    final container = await hrContainer();
    final now = DateTime.now();

    final slip = await container
        .read(payrollRepositoryProvider)
        .payslip(DateTime(now.year, now.month));

    expect(slip, isNull);
  });

  test('approved claims are reimbursed and unpaid leave deducted', () async {
    final container = await hrContainer();
    final graph = container.read(seedGraphProvider);
    final profile = payrollProfileRow(graph, graph.me);
    final month = issuedPayslipMonths(graph, profile).first;
    Map<String, dynamic> claim(int id, ExpenseStage stage) => expenseRow(
      graph: graph,
      id: id,
      employeeId: SeedGraph.meId,
      typeId: travelTypeId,
      amount: 850,
      day: DateTime(month.year, month.month, 10),
      stage: stage,
    );
    final unpaid = leaveRow(
      graph: graph,
      id: 1,
      employeeId: SeedGraph.meId,
      typeId: unpaidLeaveId,
      start: DateTime(month.year, month.month, 12),
      end: DateTime(month.year, month.month, 12),
      statusId: LeaveStatusRef.approved,
      appliedAt: DateTime(month.year, month.month, 8),
    );

    final slip = Payslip.fromJson(
      payslipRow(
        graph: graph,
        profile: profile,
        leaveRows: [unpaid],
        expenseRows: [
          claim(1, ExpenseStage.approved),
          claim(2, ExpenseStage.paid),
          claim(3, ExpenseStage.pending),
          claim(4, ExpenseStage.rejected),
        ],
        month: month,
      ),
    );

    PayslipLine line(PayslipLineCode code) =>
        slip.lines.firstWhere((l) => l.code == code);
    expect(line(PayslipLineCode.reimbursement).amount, 1700);
    expect(line(PayslipLineCode.reimbursement).count, 2);
    final dailyRate = (25000 / payrollDayDivisor).roundToDouble();
    expect(line(PayslipLineCode.unpaidLeave).amount, dailyRate);
    expect(slip.netPay, slip.totalEarnings - slip.totalDeductions);
  });

  test('a team lead cannot read someone else’s payslip', () async {
    final container = await hrContainer(role: WorkspaceRole.teamLead);

    await expectLater(
      container.read(payrollRepositoryProvider).employeeCard(employeeId: 5),
      throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', true)),
    );
  });

  test('the owner edits a salary and the card shows it', () async {
    final container = await hrContainer(role: WorkspaceRole.owner);
    keep(container, salaryEditProvider);

    await container
        .read(salaryEditProvider.notifier)
        .save(
          5,
          const SalaryInput(
            basic: 30000,
            houseRent: 9000,
            conveyance: 2500,
            commissionRate: 1.5,
            providentFund: 200,
          ),
        );

    final card = await container
        .read(payrollRepositoryProvider)
        .employeeCard(employeeId: 5);
    expect(card.basic, 30000);
    expect(card.commissionRate, 1.5);
    expect(card.canEdit, isTrue);
  });
}
