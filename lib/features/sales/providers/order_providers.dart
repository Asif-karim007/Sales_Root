import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/app_module.dart';
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
Future<SalesOrder> order(Ref ref, String id) =>
    ref.watch(orderRepositoryProvider).get(id);

@riverpod
Future<Invoice> invoice(Ref ref, String id) =>
    ref.watch(orderRepositoryProvider).invoice(id);

/// Bills one order. The screen listens for the new bill to open it.
@riverpod
class OrderActions extends _$OrderActions {
  @override
  AsyncValue<Invoice?> build(String id) => const AsyncData(null);

  Future<void> createInvoice() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).createInvoice(id),
    );
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) refreshSales(ref);
  }
}

enum InvoiceChange { split, cancelled }

/// Splits one bill into instalments or cancels it.
@riverpod
class InvoiceActions extends _$InvoiceActions {
  @override
  AsyncValue<InvoiceChange?> build(String id) => const AsyncData(null);

  Future<void> split(InstalmentPlan plan) => _run(InvoiceChange.split, () {
    return ref.read(orderRepositoryProvider).splitInvoice(id, plan);
  });

  Future<void> cancel(String reason) => _run(InvoiceChange.cancelled, () {
    return ref.read(orderRepositoryProvider).cancelInvoice(id, reason);
  });

  Future<void> _run(
    InvoiceChange change,
    Future<Invoice> Function() action,
  ) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await action();
      return change;
    });
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) refreshSales(ref);
  }
}

class DeliveryDraft {
  const DeliveryDraft({
    required this.order,
    required this.deliveredOn,
    required this.note,
    required this.delivered,
    this.createBill = true,
    this.submission,
  });

  final SalesOrder order;
  final DateTime deliveredOn;
  final String note;

  /// Keys of the lines ticked on the checklist.
  final Set<String> delivered;
  final bool createBill;
  final AsyncValue<SalesOrder>? submission;

  bool get isSaving => submission?.isLoading ?? false;

  DeliveryDraft copyWith({
    DateTime? deliveredOn,
    String? note,
    Set<String>? delivered,
    bool? createBill,
    AsyncValue<SalesOrder>? Function()? submission,
  }) => DeliveryDraft(
    order: order,
    deliveredOn: deliveredOn ?? this.deliveredOn,
    note: note ?? this.note,
    delivered: delivered ?? this.delivered,
    createBill: createBill ?? this.createBill,
    submission: submission != null ? submission() : this.submission,
  );
}

/// Marks one order delivered, and bills it at once when asked.
@riverpod
class DeliveryForm extends _$DeliveryForm {
  @override
  Future<DeliveryDraft> build(String orderId) async {
    final order = await ref.read(orderRepositoryProvider).get(orderId);
    return DeliveryDraft(
      order: order,
      deliveredOn: DateTime.now(),
      note: order.note,
      delivered: {for (final line in order.lines) line.key},
      createBill:
          order.invoices.isEmpty &&
          ref.read(moduleAccessProvider(AppModule.invoice)).canAdd,
    );
  }

  void _edit(DeliveryDraft Function(DeliveryDraft draft) change) {
    final draft = state.value;
    if (draft == null) return;
    state = AsyncData(change(draft));
  }

  void setDeliveredOn(DateTime value) =>
      _edit((d) => d.copyWith(deliveredOn: value));

  void setNote(String value) => _edit((d) => d.copyWith(note: value));

  void toggleItem(String key) => _edit((d) {
    final next = {...d.delivered};
    next.contains(key) ? next.remove(key) : next.add(key);
    return d.copyWith(delivered: next);
  });

  void setCreateBill(bool value) => _edit((d) => d.copyWith(createBill: value));

  Future<void> save() async {
    final draft = state.value;
    if (draft == null || draft.isSaving) return;
    state = AsyncData(draft.copyWith(submission: () => const AsyncLoading()));
    final repository = ref.read(orderRepositoryProvider);
    final result = await AsyncValue.guard(() async {
      final order = await repository.logDelivery(
        orderId,
        DeliveryInput(deliveredOn: draft.deliveredOn, note: draft.note),
      );
      if (!draft.createBill || order.invoices.isNotEmpty) return order;
      await repository.createInvoice(orderId);
      return repository.get(orderId);
    });
    if (!ref.mounted) return;
    final current = state.value ?? draft;
    state = AsyncData(current.copyWith(submission: () => result));
    if (result.hasValue) refreshSales(ref);
  }
}
