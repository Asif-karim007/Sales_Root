import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/providers/paging.dart';
import 'package:salesroot/features/sales/providers/sales_refresh.dart';

part 'order_providers.g.dart';

@riverpod
Future<SalesOverview> salesOverview(Ref ref) =>
    ref.watch(orderRepositoryProvider).overview();

/// Orders, or only those still to deliver, 20 at a time.
@riverpod
class OrderList extends _$OrderList {
  @override
  Future<Paged<SalesOrder>> build({bool toDeliver = false}) async {
    final result = await ref
        .watch(orderRepositoryProvider)
        .list(OrderQuery(toDeliver: toDeliver));
    return Paged.first(result);
  }

  Future<void> loadMore() => loadNextPage(
    current: state.value,
    fetch: (page) => ref
        .read(orderRepositoryProvider)
        .list(OrderQuery(toDeliver: toDeliver, page: page)),
    mounted: () => ref.mounted,
    emit: (next) => state = AsyncData(next),
  );
}

@riverpod
class InvoiceList extends _$InvoiceList {
  @override
  Future<Paged<Invoice>> build() async =>
      Paged.first(await ref.watch(orderRepositoryProvider).invoices(1));

  Future<void> loadMore() => loadNextPage(
    current: state.value,
    fetch: (page) => ref.read(orderRepositoryProvider).invoices(page),
    mounted: () => ref.mounted,
    emit: (next) => state = AsyncData(next),
  );
}

@riverpod
Future<SalesOrder> order(Ref ref, int id) =>
    ref.watch(orderRepositoryProvider).get(id);

@riverpod
Future<Invoice> invoice(Ref ref, int id) =>
    ref.watch(orderRepositoryProvider).invoice(id);

sealed class OrderOutcome {
  const OrderOutcome();
}

class OrderBilled extends OrderOutcome {
  const OrderBilled(this.invoice);

  final Invoice invoice;
}

class OrderScheduleSaved extends OrderOutcome {
  const OrderScheduleSaved();
}

@riverpod
class OrderActions extends _$OrderActions {
  @override
  AsyncValue<OrderOutcome?> build(int id) => const AsyncData(null);

  Future<void> createInvoice() => _run(
    () async =>
        OrderBilled(await ref.read(orderRepositoryProvider).createInvoice(id)),
  );

  Future<void> saveSchedule(List<Instalment> instalments) => _run(() async {
    await ref.read(orderRepositoryProvider).updateSchedule(id, instalments);
    return const OrderScheduleSaved();
  });

  Future<void> _run(Future<OrderOutcome> Function() action) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) refreshSales(ref);
  }
}

class DeliveryDraft {
  const DeliveryDraft({
    required this.order,
    required this.deliveredAt,
    required this.receivedBy,
    required this.note,
    required this.delivered,
    this.photos = const [],
    this.signature,
    this.createBill = true,
    this.submission,
  });

  final SalesOrder order;
  final DateTime deliveredAt;
  final String receivedBy;
  final String note;

  /// Product ids ticked on the checklist.
  final Set<int> delivered;
  final List<String> photos;
  final Uint8List? signature;
  final bool createBill;
  final AsyncValue<SalesOrder>? submission;

  bool get isSaving => submission?.isLoading ?? false;

  DeliveryDraft copyWith({
    DateTime? deliveredAt,
    String? receivedBy,
    String? note,
    Set<int>? delivered,
    List<String>? photos,
    Uint8List? Function()? signature,
    bool? createBill,
    AsyncValue<SalesOrder>? Function()? submission,
  }) => DeliveryDraft(
    order: order,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    receivedBy: receivedBy ?? this.receivedBy,
    note: note ?? this.note,
    delivered: delivered ?? this.delivered,
    photos: photos ?? this.photos,
    signature: signature != null ? signature() : this.signature,
    createBill: createBill ?? this.createBill,
    submission: submission != null ? submission() : this.submission,
  );
}

/// The delivery or service completion form for one order.
@riverpod
class DeliveryForm extends _$DeliveryForm {
  @override
  Future<DeliveryDraft> build(int orderId) async {
    final order = await ref.read(orderRepositoryProvider).get(orderId);
    return DeliveryDraft(
      order: order,
      deliveredAt: DateTime.now(),
      receivedBy: order.contactName,
      note: '',
      delivered: {for (final line in order.lines) line.productId},
      createBill: order.invoiceId == null,
    );
  }

  void _edit(DeliveryDraft Function(DeliveryDraft draft) change) {
    final draft = state.value;
    if (draft == null) return;
    state = AsyncData(change(draft));
  }

  void setDeliveredAt(DateTime value) =>
      _edit((d) => d.copyWith(deliveredAt: value));

  void setReceivedBy(String value) =>
      _edit((d) => d.copyWith(receivedBy: value));

  void setNote(String value) => _edit((d) => d.copyWith(note: value));

  void toggleItem(int productId) => _edit((d) {
    final next = {...d.delivered};
    next.contains(productId) ? next.remove(productId) : next.add(productId);
    return d.copyWith(delivered: next);
  });

  void addPhoto(String path) =>
      _edit((d) => d.copyWith(photos: [...d.photos, path]));

  void removePhoto(String path) => _edit(
    (d) => d.copyWith(photos: d.photos.where((p) => p != path).toList()),
  );

  void setSignature(Uint8List? png) =>
      _edit((d) => d.copyWith(signature: () => png));

  void setCreateBill(bool value) => _edit((d) => d.copyWith(createBill: value));

  Future<void> save() async {
    final draft = state.value;
    if (draft == null || draft.isSaving) return;
    state = AsyncData(draft.copyWith(submission: () => const AsyncLoading()));
    final result = await AsyncValue.guard(
      () => ref
          .read(orderRepositoryProvider)
          .logDelivery(
            orderId,
            DeliveryInput(
              deliveredAt: draft.deliveredAt,
              receivedBy: draft.receivedBy,
              note: draft.note,
              deliveredProductIds: draft.delivered.toList(),
              photos: draft.photos,
              signaturePng: draft.signature,
              createBill: draft.createBill && draft.order.invoiceId == null,
            ),
          ),
    );
    if (!ref.mounted) return;
    final current = state.value ?? draft;
    state = AsyncData(current.copyWith(submission: () => result));
    if (result.hasValue) refreshSales(ref);
  }
}
