import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/sales/data/sales_repositories.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';
import 'package:salesroot/features/sales/providers/paging.dart';
import 'package:salesroot/features/sales/providers/sales_refresh.dart';

part 'quotation_providers.g.dart';

/// The status chip on the quotation list; null is "All".
@riverpod
class QuotationStatusFilter extends _$QuotationStatusFilter {
  @override
  QuotationStatus? build() => null;

  void set(QuotationStatus? status) => state = status;
}

@riverpod
class QuotationList extends _$QuotationList {
  @override
  Future<Paged<Quotation>> build() async {
    final status = ref.watch(quotationStatusFilterProvider);
    final result = await ref
        .watch(quotationRepositoryProvider)
        .list(QuotationQuery(status: status));
    return Paged.first(result, facetKeys: const ['StatusCounts']);
  }

  Future<void> loadMore() => loadNextPage(
    current: state.value,
    fetch: (page) => ref
        .read(quotationRepositoryProvider)
        .list(
          QuotationQuery(
            status: ref.read(quotationStatusFilterProvider),
            page: page,
          ),
        ),
    mounted: () => ref.mounted,
    emit: (next) => state = AsyncData(next),
  );
}

/// The newest quotations still waiting on the customer, for the sales home.
@riverpod
Future<List<Quotation>> awaitingQuotations(Ref ref) async {
  final result = await ref
      .watch(quotationRepositoryProvider)
      .list(const QuotationQuery());
  return result.items.where((q) => q.status.isAwaiting).take(3).toList();
}

@riverpod
Future<Quotation> quotation(Ref ref, int id) =>
    ref.watch(quotationRepositoryProvider).get(id);

@riverpod
Future<SellerProfile> sellerProfile(Ref ref) =>
    ref.watch(quotationRepositoryProvider).seller();

sealed class QuotationOutcome {
  const QuotationOutcome();
}

class QuotationUpdated extends QuotationOutcome {
  const QuotationUpdated(this.quotation);

  final Quotation quotation;
}

class QuotationConverted extends QuotationOutcome {
  const QuotationConverted(this.order);

  final SalesOrder order;
}

class QuotationDeleted extends QuotationOutcome {
  const QuotationDeleted();
}

/// The actions on one quotation. The screen listens for the outcome to show
/// a message or move on.
@riverpod
class QuotationActions extends _$QuotationActions {
  @override
  AsyncValue<QuotationOutcome?> build(int id) => const AsyncData(null);

  Future<void> markAccepted() => _run(
    () async => QuotationUpdated(
      await ref.read(quotationRepositoryProvider).markAccepted(id),
    ),
  );

  Future<void> markRejected() => _run(
    () async => QuotationUpdated(
      await ref.read(quotationRepositoryProvider).markRejected(id),
    ),
  );

  Future<void> convertToOrder() => _run(
    () async => QuotationConverted(
      await ref.read(quotationRepositoryProvider).convertToOrder(id),
    ),
  );

  Future<void> send(SendChannel channel) => _run(
    () async => QuotationUpdated(
      await ref.read(quotationRepositoryProvider).send(id, channel),
    ),
  );

  Future<void> delete() => _run(() async {
    await ref.read(quotationRepositoryProvider).delete(id);
    return const QuotationDeleted();
  });

  Future<void> _run(Future<QuotationOutcome> Function() action) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) refreshSales(ref);
  }
}
