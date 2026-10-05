import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/providers/collection_providers.dart';
import 'package:salesroot/features/sales/providers/order_providers.dart';
import 'package:salesroot/features/sales/providers/product_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';

import '../../helpers/api_stub.dart';
import 'sales_test_setup.dart';

void main() {
  group('products', () {
    test('the whole catalogue in one answer, searched by q', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);
      listenTo(container, productListProvider('soap'));

      final paged = await container.read(productListProvider('soap').future);

      expect(paged.items, hasLength(3));
      expect(paged.hasMore, isFalse);
      expect(stub.last('GET', 'products')?.queryParameters, {'q': 'soap'});
    });

    test('a member may not add one: the 403 is kept for the form', () async {
      final stub = salesStub()
        ..fail('POST', 'products', 403, message: 'Ask your manager');
      final container = await salesContainer(stub);
      final provider = productEditorProvider(null);
      listenTo(container, provider);

      await container
          .read(provider.notifier)
          .save(
            const ProductInput(
              name: 'Tea 200g',
              nameBn: 'চা ২০০ গ্রাম',
              code: ' ',
              unit: 'ctn',
              price: 6400,
              vatBps: 500,
            ),
          );

      final error = container.read(provider)?.error;
      expect((error as ApiFailure?)?.isForbidden, isTrue);
      expect(stub.lastBody('POST', 'products'), {
        'nameEn': 'Tea 200g',
        'nameBn': 'চা ২০০ গ্রাম',
        'unit': 'ctn',
        'price': 6400.0,
        'taxPct': 5.0,
      });
    });
  });

  group('quotations', () {
    test('a page by status, then the next by offset', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);
      listenTo(container, quotationListProvider);
      container
          .read(quotationStatusFilterProvider.notifier)
          .set(QuotationStatus.sent);

      final paged = await container.read(quotationListProvider.future);

      expect(paged.items.single.number, 'QT-2026-00001');
      expect(paged.items.single.companyName, 'Rahim Traders');
      expect(paged.items.single.totals.total, 206400);
      final query = stub.last('GET', 'quotes')?.queryParameters;
      expect(query, {'status': 'sent', 'offset': 0, 'limit': 20});
    });

    test('an accepted quotation finds the order made from it', () async {
      final quote = fixtureMap('sales_quote');
      final stub = salesStub()
        ..on('GET', 'quotes/{id}', {
          ...quote,
          'quote': {
            ...quote['quote'] as Map<String, dynamic>,
            'status': 'accepted',
          },
        })
        ..on('GET', 'orders', {
          'items': [
            {
              ...(fixtureMap('sales_order')['order'] as Map<String, dynamic>),
              'quoteId': quoteId,
            },
          ],
          'total': 1,
        });
      final container = await salesContainer(stub);

      final quotation = await container
          .read(quotationRepositoryProvider)
          .get(quoteId);

      expect(quotation.orderId, orderId);
      expect(quotation.orderNumber, 'SO-2026-00001');
      expect(stub.last('GET', 'orders')?.queryParameters['companyId'], rahimId);
    });

    test('converting opens the new order', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);
      final actions = quotationActionsProvider(draftQuoteId);
      listenTo(container, actions);

      await container.read(actions.notifier).convertToOrder();

      final outcome = container.read(actions).value;
      expect(outcome, isA<QuotationConverted>());
      expect((outcome as QuotationConverted).order.number, 'SO-2026-00003');
      expect(stub.last('POST', 'quotes/{id}/convert')?.data, isNotNull);
    });

    test('a member cannot approve: the 403 reaches the screen', () async {
      final stub = salesStub()
        ..on(
          'POST',
          'quotes/{id}/approve',
          StubReply(403, fixtureMap('sales_error_forbidden')),
        );
      final container = await salesContainer(stub);
      final actions = quotationActionsProvider(draftQuoteId);
      listenTo(container, actions);

      await container.read(actions.notifier).approve();

      final error = container.read(actions).error;
      expect((error as ApiFailure?)?.isForbidden, isTrue);
    });

    test('duplicating answers with the new draft', () async {
      final container = await salesContainer(salesStub());
      final actions = quotationActionsProvider(draftQuoteId);
      listenTo(container, actions);

      await container.read(actions.notifier).duplicate();

      final outcome = container.read(actions).value;
      expect(
        (outcome as QuotationDuplicated).quotation.number,
        'QT-2026-00003',
      );
    });

    test('offline shows as offline', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);
      stub.offline = true;
      listenTo(container, quotationListProvider);

      await expectLater(
        container.read(quotationListProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });

  group('orders and bills', () {
    test('the sales home figures', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);

      final overview = await container.read(salesOverviewProvider.future);

      expect(overview.salesThisMonth, 100000);
      expect(overview.salesLastMonth, 0);
      expect(overview.growth, isNull);
      expect(overview.openQuotations, 1);
      expect(overview.ordersToDeliver, 2);
      expect(overview.receivable, 118000);
      expect(stub.last('GET', 'orders')?.queryParameters, {
        'status': 'confirmed',
        'offset': 0,
        'limit': 1,
      });
    });

    test('to deliver asks for confirmed orders', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);
      final provider = orderListProvider(toDeliver: true);
      listenTo(container, provider);

      await container.read(provider.future);

      expect(
        stub.last('GET', 'orders')?.queryParameters['status'],
        'confirmed',
      );
    });

    test('billing an order opens the new bill', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);
      final actions = orderActionsProvider(confirmedOrderId);
      listenTo(container, actions);

      await container.read(actions.notifier).createInvoice();

      expect(container.read(actions).value?.number, 'INV-2026-00001');
      expect(stub.last('GET', 'invoices/{id}'), isNotNull);
    });

    test('marking delivered sends the date and note, then bills', () async {
      final stub = salesStub()
        ..on('PATCH', 'orders/{id}', fixture('sales_order_confirmed'));
      final container = await salesContainer(stub, fullAccess: true);
      final form = deliveryFormProvider(confirmedOrderId);
      listenTo(container, form);
      await container.read(form.future);
      container.read(form.notifier)
        ..setDeliveredOn(DateTime(2026, 10, 5))
        ..setNote('Left at the shop');

      await container.read(form.notifier).save();

      expect(container.read(form).value?.submission?.hasValue, isTrue);
      expect(stub.lastBody('PATCH', 'orders/{id}'), {
        'status': 'delivered',
        'deliveryDate': '2026-10-05',
        'note': 'Left at the shop',
      });
      expect(stub.last('POST', 'orders/{id}/invoice'), isNotNull);
    });

    test('splitting a bill sends the plan', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);
      final actions = invoiceActionsProvider(invoiceId);
      listenTo(container, actions);

      await container
          .read(actions.notifier)
          .split(
            InstalmentPlan(
              count: 2,
              intervalDays: 15,
              firstDueDate: DateTime(2026, 10, 10),
            ),
          );

      expect(container.read(actions).value, InvoiceChange.split);
      expect(stub.lastBody('POST', 'invoices/{id}/instalments'), {
        'count': 2,
        'intervalDays': 15,
        'firstDueDate': '2026-10-10',
      });
    });

    test('cancelling a bill sends the reason; a member gets 403', () async {
      final stub = salesStub()
        ..on(
          'POST',
          'invoices/{id}/cancel',
          StubReply(403, fixtureMap('sales_error_forbidden')),
        );
      final container = await salesContainer(stub);
      final actions = invoiceActionsProvider(invoiceId);
      listenTo(container, actions);

      await container.read(actions.notifier).cancel(' Wrong customer ');

      expect(
        (container.read(actions).error as ApiFailure?)?.isForbidden,
        isTrue,
      );
      expect(stub.lastBody('POST', 'invoices/{id}/cancel'), {
        'reason': 'Wrong customer',
      });
    });
  });

  group('collection', () {
    test('the receipt carries what the customer still owes', () async {
      final container = await salesContainer(salesStub());

      final receipt = await container.read(
        collectionProvider(paymentId).future,
      );

      expect(receipt.number, 'RCPT-2026-00001');
      expect(receipt.balanceDue, 68000);
    });

    test('dues filter by bucket and search by q', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);
      final provider = outstandingListProvider(OutstandingFilter.overdue);
      listenTo(container, provider);

      await container.read(provider.future);
      await container
          .read(collectionRepositoryProvider)
          .outstanding(const OutstandingQuery(search: 'rahim', page: 2));

      final requests = stub.requests.where((r) => r.path == 'dues').toList();
      expect(requests.first.queryParameters, {
        'bucket': 'overdue',
        'offset': 0,
        'limit': 20,
      });
      expect(requests.last.queryParameters, {
        'q': 'rahim',
        'offset': 20,
        'limit': 20,
      });
    });

    test('a bill\'s collection starts on its open instalment', () async {
      final stub = salesStub()
        ..on('GET', 'companies/{id}/dues', fixture('sales_company_dues_split'));
      final container = await salesContainer(stub);
      final entry = collectionEntryProvider(
        invoiceId: '01a10cf7-70ca-75c8-967c-e54e929f240d',
      );
      listenTo(container, entry);

      final draft = await container.read(entry.future);

      expect(draft.dues?.companyName, 'Rahim Traders');
      expect(draft.dues?.items, hasLength(2));
      expect(draft.amount, 6450);
      expect(draft.selected, hasLength(2));
      expect(
        stub.last('GET', 'companies/{id}/dues')?.path,
        contains(greenAgroId),
      );
    });

    test('saving sends a PaymentCreate with its allocations', () async {
      final stub = salesStub();
      final container = await salesContainer(stub);
      final entry = collectionEntryProvider(customerId: rahimId);
      listenTo(container, entry);
      await container.read(entry.future);
      container.read(entry.notifier)
        ..setAmount(70000)
        ..setMethod(PaymentMethod.cheque)
        ..setReference('4012345')
        ..setChequeDate(DateTime(2026, 10, 8));

      await container.read(entry.notifier).save();

      final body = stub.lastBody('POST', 'payments');
      expect(body['companyId'], rahimId);
      expect(body['amount'], 70000.0);
      expect(body['method'], 'cheque');
      expect(body['reference'], '4012345');
      expect(body['chequeDate'], '2026-10-08');
      expect(body['keepExtraAsAdvance'], isTrue);
      expect(body['allocations'], [
        {
          'receivableId': '01a10101-86c3-7953-a890-76ae4af30571',
          'amount': 68000.0,
        },
      ]);
      expect(
        container.read(entry).value?.submission?.value?.number,
        'RCPT-2026-00002',
      );
    });

    test('a missing TrxID comes back on the field', () async {
      final stub = salesStub()
        ..fail(
          'POST',
          'payments',
          422,
          message: 'Enter the TrxID',
          field: 'reference',
        );
      final container = await salesContainer(stub);
      final entry = collectionEntryProvider(customerId: rahimId);
      listenTo(container, entry);
      await container.read(entry.future);
      container.read(entry.notifier).setMethod(PaymentMethod.bkash);

      await container.read(entry.notifier).save();

      final error = container.read(entry).value?.submission?.error;
      expect(
        (error as ApiFailure?)?.fieldError('reference'),
        'Enter the TrxID',
      );
    });

    test('cheque status and cancel post to the receipt', () async {
      final stub = salesStub()
        ..on('POST', 'payments/{id}/cheque', const {})
        ..on('POST', 'payments/{id}/cancel', const {});
      final container = await salesContainer(stub);
      final actions = receiptActionsProvider(paymentId);
      listenTo(container, actions);

      await container
          .read(actions.notifier)
          .setChequeStatus(ChequeStatus.cleared);
      await container.read(actions.notifier).cancel('Entered twice');

      expect(stub.lastBody('POST', 'payments/{id}/cheque'), {
        'status': 'cleared',
      });
      expect(stub.lastBody('POST', 'payments/{id}/cancel'), {
        'reason': 'Entered twice',
      });
    });

    test('the collection home figures', () async {
      final container = await salesContainer(salesStub());

      final summary = await container.read(collectionSummaryProvider.future);

      expect(summary.collectedToday, 7000);
      expect(summary.receivable, 118000);
    });
  });
}
