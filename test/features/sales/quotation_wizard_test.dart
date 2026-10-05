import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/providers/quotation_wizard.dart';

import '../../helpers/api_stub.dart';
import 'sales_test_setup.dart';

List<Product> _products() => [
  for (final row in fixture('sales_products') as List)
    Product.fromJson(row as Map<String, dynamic>),
];

void main() {
  test('from a lead the customer, contact and lead are set', () async {
    final container = await salesContainer(salesStub());
    final provider = quotationWizardProvider(leadId: leadId);
    listenTo(container, provider);

    final draft = await container.read(provider.future);

    expect(draft.customer?.name, 'Rahim Traders');
    expect(draft.customer?.companyId, rahimId);
    expect(draft.customer?.contactName, 'Mr Rahim');
    expect(draft.customer?.leadId, leadId);
    expect(draft.canContinue, isFalse);
  });

  test('a picked company brings its main contact and open lead', () async {
    final stub = salesStub();
    final container = await salesContainer(stub);
    final provider = quotationWizardProvider();
    listenTo(container, provider);
    await container.read(provider.future);

    await container
        .read(provider.notifier)
        .setCustomer(
          SalesCustomer.fromCompany(
            (fixtureMap('sales_companies')['items'] as List).last
                as Map<String, dynamic>,
          ),
        );

    final customer = container.read(provider).value?.customer;
    expect(customer?.name, 'Rahim Traders');
    expect(customer?.contactName, 'Mr Rahim');
    expect(customer?.leadId, leadId);
    expect(stub.last('GET', 'companies/{id}')?.path, contains(rahimId));
  });

  test('items add up; adding again raises the quantity', () async {
    final container = await salesContainer(salesStub());
    final provider = quotationWizardProvider(leadId: leadId);
    listenTo(container, provider);
    await container.read(provider.future);
    final wizard = container.read(provider.notifier);
    final [delivery, _, soap] = _products();

    wizard
      ..addProduct(soap)
      ..addProduct(soap)
      ..addProduct(delivery)
      ..setLineDiscount(soap.id, 500)
      ..setDiscount(400);

    final draft = container.read(provider).requireValue;
    expect(draft.qtyOf(soap.id), 2);
    expect(draft.totals.gross, 10100);
    expect(draft.totals.subtotal, 9670);
    expect(draft.totals.discount, closeTo(386.8, 0.001));
    expect(draft.canContinue, isTrue);

    wizard.setQty(delivery.id, 0);
    expect(container.read(provider).requireValue.itemCount, 1);
  });

  test('saving a draft posts a QuoteCreate', () async {
    final stub = salesStub();
    final container = await salesContainer(stub);
    final provider = quotationWizardProvider(leadId: leadId);
    listenTo(container, provider);
    await container.read(provider.future);
    final wizard = container.read(provider.notifier)
      ..addProduct(_products().last)
      ..setValidUntil(DateTime(2026, 10, 20))
      ..setTerms('50% advance')
      ..setNote(' ');

    await wizard.submit(null);

    final draft = container.read(provider).requireValue;
    expect(draft.submission?.value?.number, 'QT-2026-00002');
    expect(stub.lastBody('POST', 'quotes'), {
      'companyId': rahimId,
      'leadId': leadId,
      'contactId': '01a10101-865e-7196-8bd5-2cf8d667f937',
      'lines': [
        {
          'productId': soapId,
          'description': 'Soap 100g (carton of 48)',
          'qty': 1.0,
          'unit': 'ctn',
          'unitPrice': 4300.0,
          'discountPct': 0.0,
          'taxPct': 0.0,
        },
      ],
      'discountPct': 0.0,
      'validUntil': '2026-10-20',
      'terms': '50% advance',
    });
    expect(stub.last('POST', 'quotes/{id}/send'), isNull);
  });

  test('sending saves, then has the server send it', () async {
    final stub = salesStub();
    final container = await salesContainer(stub);
    final provider = quotationWizardProvider(leadId: leadId);
    listenTo(container, provider);
    await container.read(provider.future);
    final wizard = container.read(provider.notifier)
      ..addProduct(_products().last);

    await wizard.submit(SendChannel.whatsApp);

    expect(stub.last('POST', 'quotes'), isNotNull);
    expect(stub.last('POST', 'quotes/{id}/send')?.path, contains(draftQuoteId));
    expect(container.read(provider).value?.sentVia, SendChannel.whatsApp);
  });

  test('a discount above the limit can go for approval', () async {
    final stub = salesStub()
      ..on(
        'POST',
        'quotes',
        (r) => (r.data as Map)['requestApproval'] == true
            ? fixture('sales_quote_pending_approval')
            : StubReply(422, fixture('sales_error_discount')),
      );
    final container = await salesContainer(stub);
    final provider = quotationWizardProvider(leadId: leadId);
    listenTo(container, provider);
    await container.read(provider.future);
    final wizard = container.read(provider.notifier)
      ..addProduct(_products().last)
      ..setDiscount(1000);

    await wizard.submit(SendChannel.sms);
    final error = container.read(provider).value?.submission?.error;
    expect((error as ApiFailure?)?.fieldError('discountPct'), isNotNull);

    await wizard.submit(null, requestApproval: true);

    final saved = container.read(provider).value?.submission?.value;
    expect(saved?.status, QuotationStatus.pendingApproval);
    expect(stub.lastBody('POST', 'quotes')['discountPct'], 10.0);
    expect(stub.last('POST', 'quotes/{id}/send'), isNull);
  });

  test('editing loads the quotation and saves it in place', () async {
    final stub = salesStub();
    final container = await salesContainer(stub);
    final provider = quotationWizardProvider(editId: draftQuoteId);
    listenTo(container, provider);

    final draft = await container.read(provider.future);
    expect(draft.editing?.number, 'QT-2026-00002');
    expect(draft.lines, hasLength(2));
    expect(draft.discountBps, 400);
    expect(draft.note, '[test] probe');

    await container.read(provider.notifier).submit(null);

    expect(stub.last('PATCH', 'quotes/{id}')?.path, contains(draftQuoteId));
    expect(stub.last('POST', 'quotes'), isNull);
    expect(stub.lastBody('PATCH', 'quotes/{id}')['lines'], hasLength(2));
  });

  test('going back from the first step closes the wizard', () async {
    final container = await salesContainer(salesStub());
    final provider = quotationWizardProvider(leadId: leadId);
    listenTo(container, provider);
    await container.read(provider.future);
    final wizard = container.read(provider.notifier);

    expect(wizard.back(), isFalse);
    wizard
      ..addProduct(_products().first)
      ..next();
    expect(container.read(provider).value?.step, QuotationStep.terms);
    expect(wizard.back(), isTrue);
    expect(container.read(provider).value?.step, QuotationStep.items);
  });
}
