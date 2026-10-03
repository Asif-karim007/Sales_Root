import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';
import 'package:salesroot/features/sales/providers/paging.dart';
import 'package:salesroot/features/sales/providers/sales_refresh.dart';

part 'collection_providers.g.dart';

@riverpod
Future<CollectionSummary> collectionSummary(Ref ref) =>
    ref.watch(collectionRepositoryProvider).summary();

@riverpod
class DueList extends _$DueList {
  @override
  Future<Paged<DueRow>> build() async =>
      Paged.first(await ref.watch(collectionRepositoryProvider).dues(1));

  Future<void> loadMore() => loadNextPage(
    current: state.value,
    fetch: (page) => ref.read(collectionRepositoryProvider).dues(page),
    mounted: () => ref.mounted,
    emit: (next) => state = AsyncData(next),
  );
}

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
Future<Collection> collection(Ref ref, int id) =>
    ref.watch(collectionRepositoryProvider).get(id);

@riverpod
Future<CustomerDues> customerDues(Ref ref, int companyId) =>
    ref.watch(collectionRepositoryProvider).customerDues(companyId);

@riverpod
Future<OutstandingSummary> outstandingSummary(Ref ref) =>
    ref.watch(collectionRepositoryProvider).outstandingSummary();

@riverpod
class OutstandingFilterNotifier extends _$OutstandingFilterNotifier {
  @override
  OutstandingFilter build() => OutstandingFilter.all;

  void set(OutstandingFilter filter) => state = filter;
}

/// Customers with unpaid bills under [filter], 20 at a time.
@riverpod
class OutstandingList extends _$OutstandingList {
  @override
  Future<Paged<CustomerOutstanding>> build(
    OutstandingFilter filter, {
    String search = '',
  }) async => Paged.first(
    await ref
        .watch(collectionRepositoryProvider)
        .outstanding(filter, search: search),
  );

  Future<void> loadMore() => loadNextPage(
    current: state.value,
    fetch: (page) => ref
        .read(collectionRepositoryProvider)
        .outstanding(filter, search: search, page: page),
    mounted: () => ref.mounted,
    emit: (next) => state = AsyncData(next),
  );
}

class CollectionDraft {
  const CollectionDraft({
    required this.collectedAt,
    this.dues,
    this.amount = 0,
    this.method = PaymentMethod.cash,
    this.reference = '',
    this.senderNumber = '',
    this.bankName = '',
    this.chequeNumber = '',
    this.chequeDate,
    this.note = '',
    this.photoPath,
    this.selected,
    this.submission,
  });

  /// The customer and their open instalments; null until one is picked.
  final CustomerDues? dues;
  final int amount;
  final PaymentMethod method;
  final DateTime collectedAt;
  final String reference;
  final String senderNumber;
  final String bankName;
  final String chequeNumber;
  final DateTime? chequeDate;
  final String note;
  final String? photoPath;

  /// Keys of the instalments the user chose to apply to; null applies to all.
  final Set<String>? selected;
  final AsyncValue<Collection>? submission;

  bool get isSaving => submission?.isLoading ?? false;

  List<DueItem> get targets {
    final items = dues?.items ?? const <DueItem>[];
    final keys = selected;
    if (keys == null) return items;
    return items.where((i) => keys.contains(i.key)).toList();
  }

  List<Allocation> get allocations => allocateOldestFirst(targets, amount);

  int get allocated => allocations.fold(0, (sum, a) => sum + a.amount);

  /// What does not fit the chosen instalments.
  int get unallocated => amount - allocated;

  CollectionDraft copyWith({
    CustomerDues? dues,
    int? amount,
    PaymentMethod? method,
    DateTime? collectedAt,
    String? reference,
    String? senderNumber,
    String? bankName,
    String? chequeNumber,
    DateTime? chequeDate,
    String? note,
    String? Function()? photoPath,
    Set<String>? Function()? selected,
    AsyncValue<Collection>? Function()? submission,
  }) => CollectionDraft(
    dues: dues ?? this.dues,
    amount: amount ?? this.amount,
    method: method ?? this.method,
    collectedAt: collectedAt ?? this.collectedAt,
    reference: reference ?? this.reference,
    senderNumber: senderNumber ?? this.senderNumber,
    bankName: bankName ?? this.bankName,
    chequeNumber: chequeNumber ?? this.chequeNumber,
    chequeDate: chequeDate ?? this.chequeDate,
    note: note ?? this.note,
    photoPath: photoPath != null ? photoPath() : this.photoPath,
    selected: selected != null ? selected() : this.selected,
    submission: submission != null ? submission() : this.submission,
  );
}

/// The record-a-collection form. Opened for a customer, a bill or an order,
/// it starts on the oldest instalment due there.
@riverpod
class CollectionEntry extends _$CollectionEntry {
  @override
  Future<CollectionDraft> build({
    int? customerId,
    int? invoiceId,
    int? orderId,
  }) async {
    final draft = CollectionDraft(collectedAt: DateTime.now());
    final companyId = customerId ?? await _companyOf();
    if (companyId == null) return draft;
    final dues = await ref
        .read(collectionRepositoryProvider)
        .customerDues(companyId);
    return _focus(draft.copyWith(dues: dues), dues);
  }

  /// The customer of the bill or order the form was opened for.
  Future<int?> _companyOf() async {
    final orders = ref.read(orderRepositoryProvider);
    final invoice = invoiceId;
    if (invoice != null) return (await orders.invoice(invoice)).companyId;
    final order = orderId;
    if (order != null) return (await orders.get(order)).companyId;
    return null;
  }

  CollectionDraft _focus(CollectionDraft draft, CustomerDues dues) {
    final focus = dues.items
        .where(
          (i) =>
              (invoiceId != null && i.invoiceId == invoiceId) ||
              (orderId != null && i.orderId == orderId),
        )
        .toList();
    final first = focus.isEmpty
        ? (dues.items.isEmpty ? null : dues.items.first)
        : focus.first;
    return draft.copyWith(
      amount: first?.due ?? 0,
      selected: () => focus.isEmpty ? null : {for (final i in focus) i.key},
    );
  }

  void _edit(CollectionDraft Function(CollectionDraft draft) change) {
    final draft = state.value;
    if (draft == null) return;
    state = AsyncData(change(draft));
  }

  Future<void> pickCustomer(int companyId) async {
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

  void setAmount(int amount) => _edit((d) => d.copyWith(amount: amount));

  void setMethod(PaymentMethod method) =>
      _edit((d) => d.copyWith(method: method));

  void setCollectedAt(DateTime value) =>
      _edit((d) => d.copyWith(collectedAt: value));

  void setReference(String value) => _edit((d) => d.copyWith(reference: value));

  void setSenderNumber(String value) =>
      _edit((d) => d.copyWith(senderNumber: value));

  void setBankName(String value) => _edit((d) => d.copyWith(bankName: value));

  void setChequeNumber(String value) =>
      _edit((d) => d.copyWith(chequeNumber: value));

  void setChequeDate(DateTime value) =>
      _edit((d) => d.copyWith(chequeDate: value));

  void setNote(String value) => _edit((d) => d.copyWith(note: value));

  void setPhoto(String? path) =>
      _edit((d) => d.copyWith(photoPath: () => path));

  void setTargets(Set<String>? keys) =>
      _edit((d) => d.copyWith(selected: () => keys));

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
              senderNumber: method.isMobile ? draft.senderNumber : null,
              bankName: method.needsBank ? draft.bankName : null,
              chequeNumber: method == PaymentMethod.cheque
                  ? draft.chequeNumber
                  : null,
              chequeDate: method == PaymentMethod.cheque
                  ? draft.chequeDate
                  : null,
              note: draft.note,
              photoPath: draft.photoPath,
            ),
          ),
    );
    if (!ref.mounted) return;
    final current = state.value ?? draft;
    state = AsyncData(current.copyWith(submission: () => result));
    if (result.hasValue) refreshSales(ref);
  }
}
