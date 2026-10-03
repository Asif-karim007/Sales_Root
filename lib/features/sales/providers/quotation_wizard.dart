import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/product.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_line.dart';
import 'package:salesroot/features/sales/models/sales_math.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/providers/sales_refresh.dart';

part 'quotation_wizard.g.dart';

enum QuotationStep { items, terms, review }

class QuotationDraft {
  const QuotationDraft({
    required this.validUntil,
    this.step = QuotationStep.items,
    this.customer,
    this.priceList = PriceList.list,
    this.lines = const [],
    this.discountBps = 0,
    this.paymentTerms = PaymentTerms.advance50,
    this.deliveryDays = 14,
    this.note = '',
    this.channel = SendChannel.whatsApp,
    this.revisionOf,
    this.revising,
    this.catalog = const {},
    this.submission,
    this.sentVia,
  });

  final QuotationStep step;
  final SalesCustomer? customer;
  final PriceList priceList;
  final List<SalesLine> lines;
  final int discountBps;
  final DateTime validUntil;
  final PaymentTerms paymentTerms;
  final int deliveryDays;
  final String note;
  final SendChannel channel;

  /// The quotation this will replace as a new version.
  final int? revisionOf;

  /// The quotation being revised, for its number and version.
  final Quotation? revising;

  /// Products added in this session, so a price list switch can re-price them.
  final Map<int, Product> catalog;
  final AsyncValue<Quotation>? submission;

  /// The channel the last submission went out on; null for a draft.
  final SendChannel? sentVia;

  SalesTotals get totals =>
      computeTotals(lines, discountBps: discountBps, vatBps: standardVatBps);

  int get itemCount => lines.length;
  bool get isSaving => submission?.isLoading ?? false;
  bool get hasItems => lines.any((line) => line.qty > 0);
  bool get canContinue => customer != null && hasItems;

  int qtyOf(int productId) {
    for (final line in lines) {
      if (line.productId == productId) return line.qty;
    }
    return 0;
  }

  QuotationDraft copyWith({
    QuotationStep? step,
    SalesCustomer? customer,
    PriceList? priceList,
    List<SalesLine>? lines,
    int? discountBps,
    DateTime? validUntil,
    PaymentTerms? paymentTerms,
    int? deliveryDays,
    String? note,
    SendChannel? channel,
    Map<int, Product>? catalog,
    AsyncValue<Quotation>? Function()? submission,
    SendChannel? Function()? sentVia,
  }) => QuotationDraft(
    step: step ?? this.step,
    customer: customer ?? this.customer,
    priceList: priceList ?? this.priceList,
    lines: lines ?? this.lines,
    discountBps: discountBps ?? this.discountBps,
    validUntil: validUntil ?? this.validUntil,
    paymentTerms: paymentTerms ?? this.paymentTerms,
    deliveryDays: deliveryDays ?? this.deliveryDays,
    note: note ?? this.note,
    channel: channel ?? this.channel,
    revisionOf: revisionOf,
    revising: revising,
    catalog: catalog ?? this.catalog,
    submission: submission != null ? submission() : this.submission,
    sentVia: sentVia != null ? sentVia() : this.sentVia,
  );

  QuotationInput toInput(SendChannel? via) => QuotationInput(
    companyId: customer?.companyId,
    leadId: customer?.leadId,
    contactId: customer?.contactId,
    priceList: priceList,
    lines: lines,
    discountBps: discountBps,
    vatBps: standardVatBps,
    validUntil: validUntil,
    paymentTerms: paymentTerms,
    deliveryDays: deliveryDays,
    note: note,
    revisionOf: revisionOf,
    sendVia: via,
  );
}

/// The three-step new quotation: customer and items, then discount and
/// terms, then review and send. [fromId] copies an existing quotation, or
/// with [revise] makes its next version.
@riverpod
class QuotationWizard extends _$QuotationWizard {
  @override
  Future<QuotationDraft> build({
    int? leadId,
    int? fromId,
    bool revise = false,
  }) async {
    final repository = ref.read(quotationRepositoryProvider);
    final now = DateTime.now();
    final validUntil = DateTime(now.year, now.month, now.day + 14);
    final sourceId = fromId;
    if (sourceId != null) {
      final source = await repository.get(sourceId);
      final customer = await repository.customer(source.companyId);
      return QuotationDraft(
        validUntil: revise && source.validUntil.isAfter(now)
            ? source.validUntil
            : validUntil,
        customer: customer,
        priceList: source.priceList,
        lines: source.lines,
        discountBps: source.discountBps,
        paymentTerms: source.paymentTerms,
        deliveryDays: source.deliveryDays,
        note: source.note,
        revisionOf: revise ? source.id : null,
        revising: revise ? source : null,
      );
    }
    final lead = leadId;
    if (lead == null) return QuotationDraft(validUntil: validUntil);
    final customer = await repository.customerForLead(lead);
    return QuotationDraft(
      validUntil: validUntil,
      customer: customer,
      priceList: customer.priceList,
    );
  }

  void _edit(QuotationDraft Function(QuotationDraft draft) change) {
    final draft = state.value;
    if (draft == null) return;
    state = AsyncData(change(draft));
  }

  void setCustomer(SalesCustomer customer) => _edit(
    (d) => _repriced(
      d.copyWith(customer: customer, priceList: customer.priceList),
    ),
  );

  void setPriceList(PriceList list) =>
      _edit((d) => _repriced(d.copyWith(priceList: list)));

  QuotationDraft _repriced(QuotationDraft draft) => draft.copyWith(
    lines: [
      for (final line in draft.lines)
        switch (draft.catalog[line.productId]) {
          final Product product => line.copyWith(
            unitPrice: product.priceIn(draft.priceList),
          ),
          null => line,
        },
    ],
  );

  void addProduct(Product product) => _edit((d) {
    if (d.qtyOf(product.id) > 0) return _withQty(d, product.id, 1, add: true);
    return d.copyWith(
      lines: [...d.lines, SalesLine.of(product, d.priceList)],
      catalog: {...d.catalog, product.id: product},
    );
  });

  void setQty(int productId, int qty) =>
      _edit((d) => _withQty(d, productId, qty));

  QuotationDraft _withQty(
    QuotationDraft draft,
    int productId,
    int qty, {
    bool add = false,
  }) {
    final lines = <SalesLine>[];
    for (final line in draft.lines) {
      if (line.productId != productId) {
        lines.add(line);
        continue;
      }
      final next = add ? line.qty + qty : qty;
      if (next > 0) lines.add(line.copyWith(qty: next));
    }
    return draft.copyWith(lines: lines);
  }

  void setLineDiscount(int productId, int bps) => _edit(
    (d) => d.copyWith(
      lines: [
        for (final line in d.lines)
          line.productId == productId
              ? line.copyWith(discountBps: bps.clamp(0, bpsPerWhole))
              : line,
      ],
    ),
  );

  void setDiscount(int bps) => _edit((d) => d.copyWith(discountBps: bps));

  void setValidUntil(DateTime date) =>
      _edit((d) => d.copyWith(validUntil: date));

  void setPaymentTerms(PaymentTerms terms) =>
      _edit((d) => d.copyWith(paymentTerms: terms));

  void setDeliveryDays(int days) =>
      _edit((d) => d.copyWith(deliveryDays: days));

  void setNote(String note) => _edit((d) => d.copyWith(note: note));

  void setChannel(SendChannel channel) =>
      _edit((d) => d.copyWith(channel: channel));

  /// Moves to the next step when this one is complete.
  void next() => _edit((d) {
    if (!d.canContinue) return d;
    final index = d.step.index + 1;
    if (index >= QuotationStep.values.length) return d;
    return d.copyWith(step: QuotationStep.values[index]);
  });

  /// Goes back a step; false on the first step, so the screen can close.
  bool back() {
    final draft = state.value;
    if (draft == null || draft.step == QuotationStep.items) return false;
    state = AsyncData(
      draft.copyWith(step: QuotationStep.values[draft.step.index - 1]),
    );
    return true;
  }

  void goTo(QuotationStep step) => _edit(
    (d) => step == QuotationStep.items || d.canContinue
        ? d.copyWith(step: step)
        : d,
  );

  /// Saves the quotation, and sends it when [via] is given.
  Future<void> submit(SendChannel? via) async {
    final draft = state.value;
    if (draft == null || draft.isSaving) return;
    state = AsyncData(
      draft.copyWith(
        submission: () => const AsyncLoading(),
        sentVia: () => via,
      ),
    );
    final repository = ref.read(quotationRepositoryProvider);
    final input = draft.toInput(via);
    final revisionOf = draft.revisionOf;
    final result = await AsyncValue.guard(
      () => revisionOf == null
          ? repository.create(input)
          : repository.revise(revisionOf, input),
    );
    if (!ref.mounted) return;
    final current = state.value ?? draft;
    state = AsyncData(current.copyWith(submission: () => result));
    if (result.hasValue) refreshSales(ref);
  }
}
