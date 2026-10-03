import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/fake/fake_providers.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/providers/product_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_providers.dart';
import 'package:salesroot/features/sales/providers/quotation_wizard.dart';

import 'sales_test_helpers.dart';

void main() {
  late ProviderContainer container;

  setUp(() async => container = await salesContainer());
  tearDown(() => container.dispose());

  Future<List<Product>> products() async {
    container.listen(productListProvider('', null), (_, _) {});
    return (await container.read(productListProvider('', null).future)).items;
  }

  test('a lead prefills the customer and its price list', () async {
    final lead = container.read(seedGraphProvider).leads.first;
    final provider = quotationWizardProvider(leadId: lead.id);
    container.listen(provider, (_, _) {});

    final draft = await container.read(provider.future);

    expect(draft.customer?.companyId, lead.companyId);
    expect(draft.customer?.leadId, lead.id);
    expect(draft.step, QuotationStep.items);
    expect(draft.canContinue, isFalse);
  });

  test('steps forward only with a customer and items, and back', () async {
    final lead = container.read(seedGraphProvider).leads.first;
    final provider = quotationWizardProvider(leadId: lead.id);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final wizard = container.read(provider.notifier);
    final catalogue = await products();

    wizard.next();
    expect(container.read(provider).value?.step, QuotationStep.items);

    wizard
      ..addProduct(catalogue[0])
      ..addProduct(catalogue[0])
      ..addProduct(catalogue[5])
      ..setQty(catalogue[5].id, 3)
      ..next();
    var draft = container.read(provider).value;
    expect(draft?.step, QuotationStep.terms);
    expect(draft?.qtyOf(catalogue[0].id), 2);
    expect(draft?.qtyOf(catalogue[5].id), 3);

    wizard
      ..setQty(catalogue[5].id, 0)
      ..setDiscount(500)
      ..next();
    draft = container.read(provider).value;
    expect(draft?.lines, hasLength(1));
    expect(draft?.step, QuotationStep.review);

    expect(wizard.back(), isTrue);
    expect(wizard.back(), isTrue);
    expect(wizard.back(), isFalse);
    expect(container.read(provider).value?.step, QuotationStep.items);
  });

  test('switching the price list re-prices the items', () async {
    final lead = container.read(seedGraphProvider).leads.first;
    final provider = quotationWizardProvider(leadId: lead.id);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final wizard = container.read(provider.notifier);
    final panel = (await products()).first;

    wizard
      ..setPriceList(PriceList.list)
      ..addProduct(panel)
      ..setPriceList(PriceList.dealer);

    expect(
      container.read(provider).value?.lines.single.unitPrice,
      panel.dealerPrice,
    );
  });

  test('sending saves the quotation as sent with the drafted totals', () async {
    final lead = container.read(seedGraphProvider).leads.first;
    final provider = quotationWizardProvider(leadId: lead.id);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final wizard = container.read(provider.notifier);
    final catalogue = await products();

    wizard
      ..addProduct(catalogue[0])
      ..setQty(catalogue[0].id, 12)
      ..setDiscount(500);
    final expected = container.read(provider).value?.totals.total;
    await wizard.submit(SendChannel.whatsApp);

    final saved = container.read(provider).value?.submission?.value;
    expect(saved, isNotNull);
    expect(saved?.status, QuotationStatus.sent);
    expect(saved?.sentVia, SendChannel.whatsApp);
    expect(saved?.totals.total, expected);
    expect(saved?.number, quotationNumber(saved?.id ?? 0));
  });

  test('saving without items fails with the server validation', () async {
    final lead = container.read(seedGraphProvider).leads.first;
    final provider = quotationWizardProvider(leadId: lead.id);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);

    await container.read(provider.notifier).submit(null);

    final error = container.read(provider).value?.submission?.error;
    expect(error, isA<ApiFailure>());
    expect((error as ApiFailure?)?.isValidation, isTrue);
  });

  test('a new version replaces the terms and bumps the version', () async {
    container.listen(quotationListProvider, (_, _) {});
    final list = await container.read(quotationListProvider.future);
    final open = list.items.firstWhere((q) => q.status == QuotationStatus.sent);
    final provider = quotationWizardProvider(fromId: open.id, revise: true);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final wizard = container.read(provider.notifier)..setDiscount(1000);

    await wizard.submit(null);

    final saved = container.read(provider).value?.submission?.value;
    expect(saved?.id, open.id);
    expect(saved?.version, open.version + 1);
    expect(saved?.discountBps, 1000);
    expect(saved?.status, QuotationStatus.draft);
  });
}
