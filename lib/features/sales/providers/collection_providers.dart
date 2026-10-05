import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/providers/paging.dart';
import 'package:salesroot/features/sales/providers/sales_refresh.dart';

part 'collection_providers.g.dart';

@riverpod
Future<CollectionSummary> collectionSummary(Ref ref) =>
    ref.watch(collectionRepositoryProvider).summary();

@riverpod
class CollectionList extends _$CollectionList {
  @override
  Future<Paged<Collection>> build() async =>
      Paged.first(await ref.watch(collectionRepositoryProvider).list(1));

  Future<void> loadMore() => loadNextPage(
    current: state.value,
    fetch: (page) => ref.read(collectionRepositoryProvider).list(page),
    mounted: () => ref.mounted,
    emit: (next) => state = AsyncData(next),
  );
}

@riverpod
Future<Collection> collection(Ref ref, String id) =>
    ref.watch(collectionRepositoryProvider).get(id);

@riverpod
Future<OutstandingSummary> outstandingSummary(Ref ref) =>
    ref.watch(collectionRepositoryProvider).outstandingSummary();

@riverpod
class OutstandingFilterNotifier extends _$OutstandingFilterNotifier {
  @override
  OutstandingFilter build() => OutstandingFilter.all;

  void set(OutstandingFilter filter) => state = filter;
}

/// Customers with dues under [filter], most overdue first, 20 at a time.
@riverpod
class OutstandingList extends _$OutstandingList {
  @override
  Future<Paged<CustomerOutstanding>> build(OutstandingFilter filter) async =>
      Paged.first(
        await ref
            .watch(collectionRepositoryProvider)
            .outstanding(OutstandingQuery(filter: filter)),
      );

  Future<void> loadMore() => loadNextPage(
    current: state.value,
    fetch: (page) => ref
        .read(collectionRepositoryProvider)
        .outstanding(OutstandingQuery(filter: filter, page: page)),
    mounted: () => ref.mounted,
    emit: (next) => state = AsyncData(next),
  );
}

/// Changes the cheque's status or cancels one receipt.
@riverpod
class ReceiptActions extends _$ReceiptActions {
  @override
  AsyncValue<Collection?> build(String id) => const AsyncData(null);

  Future<void> setChequeStatus(ChequeStatus status) => _run(
    () => ref.read(collectionRepositoryProvider).setChequeStatus(id, status),
  );

  Future<void> cancel(String reason) =>
      _run(() => ref.read(collectionRepositoryProvider).cancel(id, reason));

  Future<void> _run(Future<Collection> Function() action) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) refreshSales(ref);
  }
}

class CollectionDraft {
  const CollectionDraft({
    required this.collectedAt,
    this.dues,
    this.amount = 0,
    this.method = PaymentMethod.cash,
    this.reference = '',
    this.chequeDate,
    this.note = '',
    this.selected,
    this.submission,
  });

  /// The customer and their open receivables; null until one is picked.
  final CustomerDues? dues;
  final double amount;
  final PaymentMethod method;
  final DateTime collectedAt;

  /// The TrxID, cheque number or bank reference.
  final String reference;
  final DateTime? chequeDate;
  final String note;

  /// Ids of the receivables the user chose to apply to; null applies to all.
  final Set<String>? selected;
  final AsyncValue<Collection>? submission;

  bool get isSaving => submission?.isLoading ?? false;

  List<Instalment> get targets {
    final items = dues?.items ?? const <Instalment>[];
    final ids = selected;
    if (ids == null) return items;
    return items.where((i) => ids.contains(i.id)).toList();
  }

  List<Allocation> get allocations => allocateOldestFirst(targets, amount);

  double get allocated => allocations.fold(0, (sum, a) => sum + a.amount);

  /// What does not fit the chosen receivables; kept as an advance.
  double get unallocated => amount - allocated;

  CollectionDraft copyWith({
    CustomerDues? dues,
    double? amount,
    PaymentMethod? method,
    DateTime? collectedAt,
    String? reference,
    DateTime? chequeDate,
    String? note,
    Set<String>? Function()? selected,
    AsyncValue<Collection>? Function()? submission,
  }) => CollectionDraft(
    dues: dues ?? this.dues,
    amount: amount ?? this.amount,
    method: method ?? this.method,
    collectedAt: collectedAt ?? this.collectedAt,
    reference: reference ?? this.reference,
    chequeDate: chequeDate ?? this.chequeDate,
    note: note ?? this.note,
    selected: selected != null ? selected() : this.selected,
    submission: submission != null ? submission() : this.submission,
  );
}

/// The record-a-collection form. Opened for a customer or a bill, it starts
/// on the oldest receivable due there.
@riverpod
class CollectionEntry extends _$CollectionEntry {
  @override
  Future<CollectionDraft> build({String? customerId, String? invoiceId}) async {
    final draft = CollectionDraft(collectedAt: DateTime.now());
    final companyId = customerId ?? await _companyOf();
    if (companyId == null) return draft;
    final dues = await ref
        .read(collectionRepositoryProvider)
        .customerDues(companyId);
    return _focus(draft.copyWith(dues: dues), dues);
  }

  /// The customer of the bill the form was opened for.
  Future<String?> _companyOf() async {
    final invoice = invoiceId;
    if (invoice == null) return null;
    return (await ref.read(orderRepositoryProvider).invoice(invoice)).companyId;
  }

  CollectionDraft _focus(CollectionDraft draft, CustomerDues dues) {
    final focus = dues.items
        .where((i) => invoiceId != null && i.invoiceId == invoiceId)
        .toList();
    final first = focus.isEmpty
        ? (dues.items.isEmpty ? null : dues.items.first)
        : focus.first;
    return draft.copyWith(
      amount: first?.due ?? 0,
      selected: () => focus.isEmpty ? null : {for (final i in focus) i.id},
    );
  }

  void _edit(CollectionDraft Function(CollectionDraft draft) change) {
    final draft = state.value;
    if (draft == null) return;
    state = AsyncData(change(draft));
  }

  Future<void> pickCustomer(String companyId) async {
    final draft = state.value;
    if (draft == null) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(collectionRepositoryProvider).customerDues(companyId),
    );
    if (!ref.mounted) return;
    state = result.whenData(
      (dues) => _focus(
        CollectionDraft(
          collectedAt: draft.collectedAt,
          method: draft.method,
          dues: dues,
        ),
        dues,
      ),
    );
  }

  void setAmount(double amount) => _edit((d) => d.copyWith(amount: amount));

  void setMethod(PaymentMethod method) =>
      _edit((d) => d.copyWith(method: method));

  void setCollectedAt(DateTime value) =>
      _edit((d) => d.copyWith(collectedAt: value));

  void setReference(String value) => _edit((d) => d.copyWith(reference: value));

  void setChequeDate(DateTime value) =>
      _edit((d) => d.copyWith(chequeDate: value));

  void setNote(String value) => _edit((d) => d.copyWith(note: value));

  void setTargets(Set<String>? ids) =>
      _edit((d) => d.copyWith(selected: () => ids));

  Future<void> save() async {
    final draft = state.value;
    if (draft == null || draft.isSaving) return;
    state = AsyncData(draft.copyWith(submission: () => const AsyncLoading()));
    final method = draft.method;
    final result = await AsyncValue.guard(
      () => ref
          .read(collectionRepositoryProvider)
          .record(
            CollectionInput(
              companyId: draft.dues?.companyId,
              amount: draft.amount,
              method: method,
              collectedAt: draft.collectedAt,
              allocations: draft.allocations,
              reference: method == PaymentMethod.cash ? null : draft.reference,
              chequeDate: method == PaymentMethod.cheque
                  ? draft.chequeDate
                  : null,
              note: draft.note,
            ),
          ),
    );
    if (!ref.mounted) return;
    final current = state.value ?? draft;
    state = AsyncData(current.copyWith(submission: () => result));
    if (result.hasValue) refreshSales(ref);
  }
}
