import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/hr/models/payroll.dart';
import 'package:salesroot/features/hr/providers/payroll_providers.dart';
import 'package:salesroot/features/hr/view/payslip_pdf.dart';
import 'package:salesroot/translations/translations.dart';

import '../../helpers/api_stub.dart';
import 'hr_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no payslip issued yet is an empty list', () async {
    final container = await hrContainer(hrStub());
    listenTo(container, payslipsProvider(null));

    expect(await container.read(payslipsProvider(null).future), isEmpty);
  });

  test('my card names me and my manager; no salary is set up', () async {
    final container = await hrContainer(hrStub());
    listenTo(container, employeeCardProvider(null));

    final card = await container.read(employeeCardProvider(null).future);

    expect(card.employeeId, rafiId);
    expect(card.name, 'Rafi Ahmed');
    expect(card.reportsTo, 'Rumpa Sarker');
    expect(card.salary, isNull);
  });

  test('someone else’s payslips need the payroll right', () async {
    final stub = hrStub()
      ..on('GET', 'hr/payroll', fixture('hr_payroll_forbidden'), status: 403);
    final container = await hrContainer(stub);
    listenTo(container, payslipsProvider(rumpaId));

    await expectLater(
      container.read(payslipsProvider(rumpaId).future),
      throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', isTrue)),
    );
  });

  test('someone else’s salary history needs the salary right', () async {
    final stub = hrStub()
      ..on(
        'GET',
        'hr/salary/{membershipId}/history',
        fixture('hr_salary_forbidden'),
        status: 403,
      );
    final container = await hrContainer(stub);
    listenTo(container, employeeCardProvider(rumpaId));

    await expectLater(
      container.read(employeeCardProvider(rumpaId).future),
      throwsA(isA<ApiFailure>().having((f) => f.isForbidden, '403', isTrue)),
    );
  });

  test('a salary save keeps the fields the sheet does not edit', () {
    final current = SalaryStructure.fromJson({
      'basic': 20000,
      'paymentMethod': 'bkash',
      'paymentAccount': '01811000033',
      'taxMonthly': 500,
      'workspaceId': 'w1',
    });
    expect(current?.paymentMethod, 'bkash');
    final body = const SalaryInput(
      basic: 25000,
      houseRent: 5000,
      medical: 1000,
      conveyance: 2000,
      pfPct: 5,
    ).toJson(current ?? const SalaryStructure(), DateTime(2026, 11, 1));

    expect(body, {
      'taxMonthly': 500,
      'paymentMethod': 'bkash',
      'paymentAccount': '01811000033',
      'effectiveFrom': '2026-11-01',
      'basic': 25000.0,
      'houseRent': 5000.0,
      'medical': 1000.0,
      'conveyance': 2000.0,
      'pfPct': 5.0,
    });
  });

  test('the payslip PDF builds with the bundled font', () async {
    final slip = Payslip(
      employeeName: 'Rafi Ahmed',
      period: DateTime(2026, 9),
      lines: const [
        PayslipLine(code: PayslipLineCode.basic, amount: 20000),
        PayslipLine(code: PayslipLineCode.providentFund, amount: 1000),
      ],
      netPay: 19000,
    );
    expect(slip.totalEarnings - slip.totalDeductions, slip.netPay);

    await initializeDateFormatting('bn');
    final l10n = lookupAppLocalizations(bangla);

    final bytes = await buildPayslipPdf(
      slip,
      l10n,
      AppFormat(l10n, bangla),
      'Dhaka Sales Ltd.',
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
