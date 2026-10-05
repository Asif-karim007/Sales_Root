import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
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
    this.lines = const [],
    this.discountBps = 0,
    this.terms = '',
    this.note = '',
    this.channel = SendChannel.whatsApp,
    this.editing,
    this.submission,
    this.sentVia,
  });

  final QuotationStep step;
  final SalesCustomer? customer;
  final List<SalesLine> lines;
  final int discountBps;
  final DateTime validUntil;

  /// Payment and delivery terms as printed.
  final String terms;
  final String note;
  final SendChannel channel;

  /// The quotation being edited; null for a new one.
  final Quotation? editing;
  final AsyncValue<Quotation>? submission;

  /// The channel the last submission went out on; null for a draft.
  final SendChannel? sentVia;

  SalesTotals get totals => computeTotals(lines, discountBps: discountBps);

  int get itemCount => lines.length;
  bool get isSaving => submission?.isLoading ?? false;
  bool get hasItems => lines.any((line) => line.qty > 0);
  bool get canContinue => customer != null && hasItems;

  double qtyOf(String key) {
    for (final line in lines) {
      if (line.key == key) return line.qty;
    }
    return 0;
  }

  QuotationDraft copyWith({
    QuotationStep? step,
    SalesCustomer? customer,
    List<SalesLine>? lines,
    int? discountBps,
    DateTime? validUntil,
    String? terms,
    String? note,
    SendChannel? channel,
    AsyncValue<Quotation>? Function()? submission,
    SendChannel? Function()? sentVia,
  }) => QuotationDraft(
    step: step ?? this.step,
    customer: customer ?? this.customer,
    lines: lines ?? this.lines,
    discountBps: discountBps ?? this.discountBps,
    validUntil: validUntil ?? this.validUntil,
    terms: terms ?? this.terms,
    note: note ?? this.note,
    channel: channel ?? this.channel,
    editing: editing,
    submission: submission != null ? submission() : this.submission,
    sentVia: sentVia != null ? sentVia() : this.sentVia,
  );

  QuotationInput toInput({bool requestApproval = false}) => QuotationInput(
    companyId: customer?.companyId,
    leadId: customer?.leadId,
    contactId: customer?.contactId,
    lines: lines,
    discountBps: discountBps,
    validUntil: validUntil,
    terms: terms,
    note: note,
    requestApproval: requestApproval,
  );
}

/// The three-step quotation: customer and items, then discount and terms,
/// then review and send. [editId] edits an existing quotation in place.
@riverpod
class QuotationWizard extends _$QuotationWizard {
  @override
  Future<QuotationDraft> build({String? leadId, String? editId}) async {
    final repository = ref.read(quotationRepositoryProvider);
    final now = DateTime.now();
    final validUntil = DateTime(now.year, now.month, now.day + 14);
    final sourceId = editId;
    if (sourceId != null) {
      final source = await repository.get(sourceId);
      final current = source.validUntil;
      return QuotationDraft(
        validUntil: current != null && current.isAfter(now)
            ? current
            : validUntil,
        customer: SalesCustomer(
          companyId: source.companyId,
          name: source.companyName,
          contactId: source.contactId,
          contactName: source.contactName,
          contactPhone: source.contactPhone,
          leadId: source.leadId,
        ),
        lines: source.lines,
        discountBps: source.discountBps,
        terms: source.terms,
        note: source.note,
        editing: source,
      );
    }
    final lead = leadId;
    if (lead == null) return QuotationDraft(validUntil: validUntil);
    return QuotationDraft(
      validUntil: validUntil,
      customer: await repository.customerForLead(lead),
    );
  }

  void _edit(QuotationDraft Function(QuotationDraft draft) change) {
    final draft = state.value;
    if (draft == null) return;
    state = AsyncData(change(draft));
  }

  /// Takes the picked company at once, then its main contact and open lead.
  Future<void> setCustomer(SalesCustomer customer) async {
    _edit((d) => d.copyWith(customer: customer));
    final companyId = customer.companyId;
    if (companyId == null) return;
    try {
      final detail = await ref
          .read(quotationRepositoryProvider)
          .customer(companyId);
      if (!ref.mounted) return;
      _edit(
        (d) => d.customer?.companyId == companyId
            ? d.copyWith(customer: detail)
            : d,
      );
    } on ApiFailure {
      return;
    }
  }

  void addProduct(Product product) => _edit((d) {
    if (d.qtyOf(product.id) > 0) return _withQty(d, product.id, 1, add: true);
    return d.copyWith(lines: [...d.lines, SalesLine.of(product)]);
  });

  void setQty(String key, double qty) => _edit((d) => _withQty(d, key, qty));

  QuotationDraft _withQty(
    QuotationDraft draft,
    String key,
    double qty, {
    bool add = false,
  }) {
    final lines = <SalesLine>[];
    for (final line in draft.lines) {
      if (line.key != key) {
        lines.add(line);
        continue;
      }
      final next = add ? line.qty + qty : qty;
      if (next > 0) lines.add(line.copyWith(qty: next));
    }
    return draft.copyWith(lines: lines);
  }

  void setLineDiscount(String key, int bps) => _edit(
    (d) => d.copyWith(
      lines: [
        for (final line in d.lines)
          line.key == key
              ? line.copyWith(discountBps: bps.clamp(0, bpsPerWhole))
              : line,
      ],
    ),
  );

  void setDiscount(int bps) => _edit((d) => d.copyWith(discountBps: bps));

  void setValidUntil(DateTime date) =>
      _edit((d) => d.copyWith(validUntil: date));

  void setTerms(String terms) => _edit((d) => d.copyWith(terms: terms));

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

  /// Saves the quotation, and has the server send it when [via] is given.
  /// [requestApproval] sends a discount above the user's limit to a manager
  /// instead.
  Future<void> submit(SendChannel? via, {bool requestApproval = false}) async {
    final draft = state.value;
    if (draft == null || draft.isSaving) return;
    state = AsyncData(
      draft.copyWith(
        submission: () => const AsyncLoading(),
        sentVia: () => via,
      ),
    );
    final repository = ref.read(quotationRepositoryProvider);
    final input = draft.toInput(requestApproval: requestApproval);
    final editing = draft.editing;
    final result = await AsyncValue.guard(() async {
      final saved = editing == null
          ? await repository.create(input)
          : await repository.save(editing.id, input);
      if (via == null || saved.status == QuotationStatus.pendingApproval) {
        return saved;
      }
      return repository.send(saved.id);
    });
    if (!ref.mounted) return;
    final current = state.value ?? draft;
    state = AsyncData(current.copyWith(submission: () => result));
    if (result.hasValue) refreshSales(ref);
  }
}
