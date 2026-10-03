import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/workspace/workspace.dart';
import 'package:salesroot/features/sales/data/sales_ledger.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/providers/collection_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';

import 'sales_test_helpers.dart';

void main() {
  group('fixtures', () {
    late ProviderContainer container;

    setUp(() async => container = await salesContainer());
    tearDown(() => container.dispose());

    test(
      'quotations come from Quotation and Won leads in every status',
      () async {
        final graph = container.read(seedGraphProvider);
        final ledger = SalesLedger(container.read(fakeBackendProvider));
        final rows = ledger.quotations.rows.map(Quotation.fromJson).toList();

        expect(rows, isNotEmpty);
        for (final q in rows) {
          final lead = graph.lead(q.leadId ?? 0);
          expect(lead.stageId, anyOf(4, 5));
          expect(q.status == QuotationStatus.accepted, lead.stageId == 5);
        }
        expect(
          rows.map((q) => q.status).toSet(),
          containsAll([
            QuotationStatus.draft,
            QuotationStatus.sent,
            QuotationStatus.viewed,
            QuotationStatus.accepted,
            QuotationStatus.rejected,
            QuotationStatus.expired,
          ]),
        );
      },
    );

    test('bills match their order and lines, and outstanding is bills less '
        'collections', () async {
      final ledger = SalesLedger(container.read(fakeBackendProvider));
      final paid = ledger.paidByInstalment();
      var billed = 0;
      var collectedOnBills = 0;
      for (final row in ledger.invoices.rows) {
        final invoice = Invoice.fromJson(ledger.invoiceJson(row, paid));
        final order = SalesOrder.fromJson(
          ledger.orderJson(ledger.orders.byId(invoice.orderId), paid),
        );
        final lineSum = invoice.lines.fold<int>(0, (s, l) => s + l.net);
        expect(invoice.totals.subtotal, lineSum);
        expect(invoice.totals.total, order.totals.total);
        expect(
          order.instalments.fold<int>(0, (s, i) => s + i.amount),
          order.totals.total,
        );
        billed += invoice.totals.total;
        collectedOnBills += invoice.paid;
      }
      final summary = await container
          .read(collectionRepositoryProvider)
          .outstandingSummary();

      expect(billed, greaterThan(0));
      expect(summary.total, billed - collectedOnBills);
      expect(
        summary.buckets.values.fold<int>(0, (s, v) => s + v),
        summary.total,
      );
    });
  });

  group('quotation to order', () {
    test(
      'converting accepts the quotation and opens an order on its terms',
      () async {
        final container = await salesContainer();
        addTearDown(container.dispose);
        final repository = container.read(quotationRepositoryProvider);
        final open = (await repository.list(
          const QuotationQuery(status: QuotationStatus.viewed),
        )).items.first;
        final actions = quotationActionsProvider(open.id);
        container.listen(actions, (_, _) {});

        await container.read(actions.notifier).convertToOrder();

        final outcome = container.read(actions).value;
        expect(outcome, isA<QuotationConverted>());
        final order = (outcome as QuotationConverted?)?.order;
        expect(order?.status, OrderStatus.confirmed);
        expect(order?.quotationId, open.id);
        expect(order?.totals.total, open.totals.total);
        expect(
          order?.instalments.fold<int>(0, (s, i) => s + i.amount),
          open.totals.total,
        );
        final after = await repository.get(open.id);
        expect(after.status, QuotationStatus.accepted);
        expect(after.orderId, order?.id);

        await container.read(actions.notifier).convertToOrder();
        final again = container.read(actions).error;
        expect((again as ApiFailure?)?.isConflict, isTrue);
      },
    );

    test('a member may not open orders', () async {
      final container = await salesContainer(role: WorkspaceRole.member);
      addTearDown(container.dispose);
      final repository = container.read(quotationRepositoryProvider);
      final open = (await repository.list(
        const QuotationQuery(status: QuotationStatus.sent),
      )).items.first;

      expect(
        () => repository.convertToOrder(open.id),
        throwsA(
          isA<ApiFailure>().having((f) => f.isForbidden, 'forbidden', true),
        ),
      );
    });
  });

  group('collection', () {
    test('allocating a payment reduces the outstanding by that much', () async {
      final container = await salesContainer();
      addTearDown(container.dispose);
      final repository = container.read(collectionRepositoryProvider);
      final debtor = (await repository.outstanding(
        OutstandingFilter.all,
      )).items.first;
      final before = await repository.outstandingSummary();
      final entry = collectionEntryProvider(customerId: debtor.companyId);
      container.listen(entry, (_, _) {});
      final draft = await container.read(entry.future);
      final billed = draft.dues?.items.firstWhere((i) => i.invoiceId != null);
      expect(billed, isNotNull);
      final form = container.read(entry.notifier)
        ..setTargets({billed?.key ?? ''})
        ..setAmount(billed?.due ?? 0)
        ..setMethod(PaymentMethod.bkash)
        ..setReference('BKX7H2K9Q1');

      await form.save();

      final saved = container.read(entry).value?.submission?.value;
      expect(saved, isNotNull);
      expect(saved?.amount, billed?.due);
      expect(saved?.allocations.single.seq, billed?.instalment.seq);
      final after = await repository.outstandingSummary();
      expect(after.total, before.total - (billed?.due ?? 0));
    });

    test('a bKash collection needs its TrxID', () async {
      final container = await salesContainer();
      addTearDown(container.dispose);
      final debtor =
          (await container
                  .read(collectionRepositoryProvider)
                  .outstanding(OutstandingFilter.all))
              .items
              .first;
      final entry = collectionEntryProvider(customerId: debtor.companyId);
      container.listen(entry, (_, _) {});
      await container.read(entry.future);

      await (container.read(
        entry.notifier,
      )..setMethod(PaymentMethod.nagad)).save();

      final error = container.read(entry).value?.submission?.error;
      expect((error as ApiFailure?)?.fieldError('Reference'), isNotNull);
    });
  });

  group('lists', () {
    test('quotations page 20 at a time', () async {
      final container = await salesContainer();
      addTearDown(container.dispose);
      container.listen(quotationListProvider, (_, _) {});

      final first = await container.read(quotationListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.hasMore, isTrue);

      await container.read(quotationListProvider.notifier).loadMore();
      final second = container.read(quotationListProvider).value;
      expect(second?.items.length, greaterThan(20));
      expect(second?.facets['StatusCounts']?['All'], first.totalCount);
    });

    test('offline shows as a failure on the list', () async {
      final container = await salesContainer();
      addTearDown(container.dispose);
      setDev(container, (s) => s.copyWith(offline: true));
      container.listen(collectionSummaryProvider, (_, _) {});

      await expectLater(
        container.read(collectionSummaryProvider.future),
        throwsA(isA<ApiFailure>().having((f) => f.isOffline, 'offline', true)),
      );
    });
  });
}
