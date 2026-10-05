import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/hr/view/approvals_screen.dart';
import 'package:salesroot/features/hr/view/employee_card_screen.dart';
import 'package:salesroot/features/hr/view/expense_claim_screen.dart';
import 'package:salesroot/features/hr/view/expense_list_screen.dart';
import 'package:salesroot/features/hr/view/leave_request_screen.dart';
import 'package:salesroot/features/hr/view/leave_screen.dart';
import 'package:salesroot/features/hr/view/payslip_screen.dart';
import 'package:salesroot/features/hr/view/ticket_screen.dart';
import 'package:salesroot/features/hr/view/widget/ticket_summary.dart';
import 'package:salesroot/translations/translations.dart';
import 'package:salesroot/widgets/widgets.dart';

import '../../helpers/api_stub.dart';
import 'hr_test_setup.dart';

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen,
  Locale locale,
) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: screen,
      ),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('screens render', () {
    final screens = <String, (Widget, String?)>{
      'leave': (const LeaveScreen(), 'Casual leave'),
      'leave request': (const LeaveRequestScreen(), 'Casual leave'),
      'expenses': (const ExpenseListScreen(), 'Travel / transport'),
      'expense claim': (
        const ExpenseClaimScreen(visitId: visitId),
        'Rumpa Sarker',
      ),
      'approvals': (const ApprovalsScreen(), 'Rafi Ahmed'),
      'payslip': (const PayslipScreen(), 'No payslip yet'),
      'employee card': (const EmployeeCardScreen(), 'Rumpa Sarker'),
      'new ticket': (const TicketScreen(), 'New support ticket'),
      'ticket': (
        const TicketSummaryScreen(ticketId: ticketId),
        'TKT-2026-00002',
      ),
    };

    for (final locale in [english, bangla]) {
      for (final MapEntry(key: name, value: (screen, text))
          in screens.entries) {
        testWidgets('$name in ${locale.languageCode}', (tester) async {
          final container = await tester.runAsync(
            () => hrContainer(hrStub(), role: 'owner', fullAccess: true),
          );
          if (container == null) return;

          await _pump(tester, container, screen, locale);

          expect(tester.takeException(), isNull);
          expect(find.byType(SrErrorState), findsNothing);
          if (locale == english && text != null) {
            expect(find.textContaining(text), findsWidgets);
          }
        });
      }
    }
  });

  group('states', () {
    testWidgets('no claims shows the empty state', (tester) async {
      final stub = hrStub()
        ..on('GET', 'hr/expenses', fixture('hr_expenses_empty'));
      final container = await tester.runAsync(() => hrContainer(stub));
      if (container == null) return;

      await _pump(tester, container, const ExpenseListScreen(), english);

      expect(find.text('No claims yet'), findsOneWidget);
    });

    testWidgets('offline shows the offline state', (tester) async {
      final stub = hrStub();
      final container = await tester.runAsync(() => hrContainer(stub));
      if (container == null) return;
      stub.offline = true;

      await _pump(tester, container, const LeaveScreen(), english);

      expect(find.byType(SrErrorState), findsWidgets);
      expect(find.text('No internet connection'), findsWidgets);
    });

    testWidgets('another member’s payslips without the right', (tester) async {
      final stub = hrStub()
        ..on('GET', 'hr/payroll', fixture('hr_payroll_forbidden'), status: 403);
      final container = await tester.runAsync(() => hrContainer(stub));
      if (container == null) return;

      await _pump(
        tester,
        container,
        const PayslipScreen(employeeId: rumpaId),
        english,
      );

      expect(find.byType(SrErrorState), findsOneWidget);
    });

    testWidgets('an executive sees no reply or approve buttons', (
      tester,
    ) async {
      final container = await tester.runAsync(() => hrContainer(hrStub()));
      if (container == null) return;

      await _pump(tester, container, const ApprovalsScreen(), english);

      expect(find.text('Approve'), findsNothing);
    });
  });
}
