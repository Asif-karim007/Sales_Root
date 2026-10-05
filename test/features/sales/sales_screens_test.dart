import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/locale/locale_provider.dart';
import 'package:salesroot/core/theme/app_theme.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/pdf/sales_pdf.dart';
import 'package:salesroot/features/sales/view/collection_entry_screen.dart';
import 'package:salesroot/features/sales/view/collection_screen.dart';
import 'package:salesroot/features/sales/view/delivery_screen.dart';
import 'package:salesroot/features/sales/view/invoice_screen.dart';
import 'package:salesroot/features/sales/view/order_screen.dart';
import 'package:salesroot/features/sales/view/outstanding_screen.dart';
import 'package:salesroot/features/sales/view/products_screen.dart';
import 'package:salesroot/features/sales/view/quotation_screen.dart';
import 'package:salesroot/features/sales/view/quotation_wizard_screen.dart';
import 'package:salesroot/features/sales/view/quotations_screen.dart';
import 'package:salesroot/features/sales/view/receipt_screen.dart';
import 'package:salesroot/features/sales/view/sales_home_screen.dart';
import 'package:salesroot/translations/translations.dart';

import '../../helpers/api_stub.dart';
import 'sales_test_setup.dart';

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
      'sales home': (const SalesHomeScreen(), 'Rahim Traders'),
      'products': (const ProductsScreen(), 'Soap 100g (carton of 48)'),
      'quotations': (const QuotationsScreen(), 'QT-2026-00001'),
      'quotation': (const QuotationScreen(id: quoteId), 'Mark accepted'),
      'draft quotation': (const QuotationScreen(id: draftQuoteId), 'Send'),
      'new quotation': (
        const QuotationWizardScreen(leadId: leadId),
        'Mr Rahim',
      ),
      'edit quotation': (
        const QuotationWizardScreen(editId: draftQuoteId),
        'Edit quotation',
      ),
      'order': (const OrderScreen(id: orderId), 'INV-2026-00001'),
      'confirmed order': (
        const OrderScreen(id: confirmedOrderId),
        'Create bill',
      ),
      'delivery': (
        const DeliveryScreen(orderId: confirmedOrderId),
        '[test] Soap',
      ),
      'bill': (const InvoiceScreen(id: invoiceId), '2nd instalment'),
      'collection': (const CollectionScreen(), 'RCPT-2026-00001'),
      'record collection': (
        const CollectionEntryScreen(customerId: rahimId),
        'INV-OLD-0031',
      ),
      'pick a debtor': (const CollectionEntryScreen(), null),
      'receipt': (const ReceiptScreen(id: paymentId), 'RCPT-2026-00001'),
      'outstanding': (const OutstandingScreen(), 'Green Agro Ltd.'),
    };

    for (final locale in [english, bangla]) {
      for (final MapEntry(key: name, value: (screen, text))
          in screens.entries) {
        testWidgets('$name in ${locale.languageCode}', (tester) async {
          final container = await tester.runAsync(
            () => salesContainer(salesStub(), role: 'owner', fullAccess: true),
          );
          if (container == null) return;

          await _pump(tester, container, screen, locale);

          expect(tester.takeException(), isNull);
          if (locale == english && text != null) {
            expect(find.textContaining(text), findsWidgets);
          }
        });
      }
    }
  });

  group('states', () {
    testWidgets('a member sees no approve, convert or bill buttons', (
      tester,
    ) async {
      final quote = fixtureMap('sales_quote_pending_approval');
      final stub = salesStub()..on('GET', 'quotes/{id}', quote);
      final container = await tester.runAsync(() => salesContainer(stub));
      if (container == null) return;
      final l10n = lookupAppLocalizations(english);

      await _pump(
        tester,
        container,
        const QuotationScreen(id: draftQuoteId),
        english,
      );

      expect(find.text(l10n.salesStatusPendingApproval), findsWidgets);
      expect(find.text(l10n.salesApprove), findsNothing);
      expect(find.text(l10n.commonEdit), findsOneWidget);
    });

    testWidgets('a manager approves', (tester) async {
      final quote = fixtureMap('sales_quote_pending_approval');
      final stub = salesStub()
        ..on('GET', 'quotes/{id}', quote)
        ..on('POST', 'quotes/{id}/approve', const {});
      final container = await tester.runAsync(
        () => salesContainer(stub, role: 'teamlead'),
      );
      if (container == null) return;
      final l10n = lookupAppLocalizations(english);

      await _pump(
        tester,
        container,
        const QuotationScreen(id: draftQuoteId),
        english,
      );
      expect(find.text(l10n.salesApprove), findsOneWidget);
      await tester.tap(find.text(l10n.salesApprove));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(stub.last('POST', 'quotes/{id}/approve'), isNotNull);
    });

    testWidgets('an empty list and a failed list', (tester) async {
      final stub = salesStub()
        ..on('GET', 'quotes', {'items': <Object>[], 'total': 0})
        ..fail('GET', 'products', 500, message: 'Server down');
      final container = await tester.runAsync(
        () => salesContainer(stub, role: 'owner', fullAccess: true),
      );
      if (container == null) return;
      final l10n = lookupAppLocalizations(english);

      await _pump(tester, container, const QuotationsScreen(), english);
      expect(find.text(l10n.salesQuotationsEmpty), findsOneWidget);

      await _pump(tester, container, const ProductsScreen(), english);
      expect(find.textContaining('Server down'), findsWidgets);
    });

    testWidgets('the collection methods show their fields', (tester) async {
      final container = await tester.runAsync(
        () => salesContainer(salesStub(), role: 'owner', fullAccess: true),
      );
      if (container == null) return;
      final l10n = lookupAppLocalizations(english);

      await _pump(
        tester,
        container,
        const CollectionEntryScreen(customerId: rahimId),
        english,
      );
      await tester.tap(find.text(l10n.salesMethodBkash));
      await tester.pump();
      expect(find.text(l10n.salesTrxId), findsOneWidget);

      await tester.drag(find.text(l10n.salesMethodCash), const Offset(-300, 0));
      await tester.pump();
      await tester.tap(find.text(l10n.salesMethodCheque));
      await tester.pump();
      expect(find.text(l10n.salesChequeNumber), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PDFs', () {
    setUpAll(initializeDateFormatting);

    for (final locale in [bangla, english]) {
      test('quotation, bill and receipt in ${locale.languageCode}', () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final l10n = lookupAppLocalizations(locale);
        final pdf = SalesPdf(l10n, AppFormat(l10n, locale));
        final seller = SellerProfile.fromJson(fixtureMap('sales_workspace'));

        final documents = [
          await pdf.quotation(
            Quotation.fromDetail(fixtureMap('sales_quote_created')),
            seller,
          ),
          await pdf.invoice(
            Invoice.fromDetail(fixtureMap('sales_invoice')),
            seller,
          ),
          await pdf.receipt(
            Collection.fromJson(fixtureMap('sales_payment')).withBalance(0),
            seller,
          ),
        ];

        for (final bytes in documents) {
          expect(bytes.length, greaterThan(1000));
          expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
        }
      });
    }
  });
}
