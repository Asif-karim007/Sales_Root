import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:salesroot/core/format/app_format.dart';
import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/features/sales/data/sales_fixtures.dart';
import 'package:salesroot/features/sales/data/sales_ledger.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/pdf/sales_pdf.dart';
import 'package:salesroot/translations/translations.dart';

import 'sales_test_helpers.dart';

void expectPdf(Uint8List bytes) {
  expect(bytes.length, greaterThan(1000));
  expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  for (final locale in const [Locale('bn'), Locale('en')]) {
    test(
      'quotation, bill and receipt PDFs in ${locale.languageCode}',
      () async {
        final container = await salesContainer();
        addTearDown(container.dispose);
        final backend = container.read(fakeBackendProvider);
        final ledger = SalesLedger(backend);
        final l10n = lookupAppLocalizations(locale);
        final pdf = SalesPdf(l10n, AppFormat(l10n, locale));
        final seller = SellerProfile.fromJson(sellerFixture(backend.graph));

        final quotation = Quotation.fromJson(ledger.quotations.rows.first);
        final invoice = Invoice.fromJson(
          ledger.invoiceJson(ledger.invoices.rows.first),
        );
        final receipt = Collection.fromJson(ledger.collections.rows.first);

        expectPdf(await pdf.quotation(quotation, seller));
        expectPdf(await pdf.invoice(invoice, seller));
        expectPdf(await pdf.receipt(receipt, seller));
      },
    );
  }
}
