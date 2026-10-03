import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/app.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/routing/app_router.dart';
import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/sales/data/sales_ledger.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/view/sales_links.dart';
import 'package:salesroot/l10n/l10n.dart';

import 'sales_test_helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final locale in const [bangla, english]) {
    testWidgets('every sales screen renders at phone width in '
        '${locale.languageCode}', (tester) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final container = await salesContainer();
      addTearDown(container.dispose);
      container.read(appLocaleProvider.notifier).set(locale);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const App()),
      );
      await _settle(tester);

      final ledger = SalesLedger(container.read(fakeBackendProvider));
      final graph = container.read(seedGraphProvider);
      final open = ledger.orders.rows.firstWhere(
        (r) => OrderStatus.fromWire(r['Status'] as String?).toDeliver,
      );
      final invoice = ledger.invoices.rows.first;
      final locations = [
        Routes.products,
        Routes.quotations,
        quotationNewFor(leadId: graph.leads.first.id),
        Routes.quotationFor(ledger.quotations.rows.first['Id'] as int),
        Routes.orderFor(open['Id'] as int),
        Routes.orderDeliveryFor(open['Id'] as int),
        Routes.invoiceFor(invoice['Id'] as int),
        Routes.collection,
        collectionNewFor(
          customerId: invoice['CompanyId'] as int,
          invoiceId: invoice['Id'] as int,
        ),
        Routes.collectionNew,
        Routes.receiptFor(ledger.collections.rows.first['Id'] as int),
        Routes.outstanding,
      ];

      final router = container.read(appRouterProvider);
      router.go(Routes.sales);
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: Routes.sales);

      for (final location in locations) {
        router.push(location);
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: location);
        router.pop();
        await _settle(tester);
      }
    });
  }

  testWidgets('the wizard steps and the collection methods render', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = await salesContainer();
    addTearDown(container.dispose);
    container.read(appLocaleProvider.notifier).set(english);
    final l10n = lookupAppLocalizations(english);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await _settle(tester);
    final router = container.read(appRouterProvider);
    final graph = container.read(seedGraphProvider);

    router.push(quotationNewFor(leadId: graph.leads.first.id));
    await _settle(tester);
    await tester.tap(find.byTooltip(l10n.commonAdd).first);
    await _settle(tester);
    await tester.tap(find.text(l10n.commonNext));
    await _settle(tester);
    expect(find.text(l10n.salesPaymentTerms), findsWidgets);
    await tester.tap(find.text(l10n.commonNext));
    await _settle(tester);
    expect(find.text(l10n.salesHowToSend), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.pop();
    await _settle(tester);

    final ledger = SalesLedger(container.read(fakeBackendProvider));
    final paid = ledger.paidByInstalment();
    final invoice = ledger.invoices.rows.firstWhere(
      (row) => ledger.invoiceDue(row, paid) > 0,
    );
    router.push(
      collectionNewFor(
        customerId: invoice['CompanyId'] as int,
        invoiceId: invoice['Id'] as int,
      ),
    );
    await _settle(tester);
    expect(find.text(l10n.salesOldestFirst), findsNothing);
    for (final method in [l10n.salesMethodBkash, l10n.salesMethodBank]) {
      await tester.tap(find.text(method));
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: method);
    }
    await tester.drag(find.text(l10n.salesMethodCash), const Offset(-300, 0));
    await _settle(tester);
    await tester.tap(find.text(l10n.salesMethodCheque));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.salesChequeNumber), findsOneWidget);
  });
}
