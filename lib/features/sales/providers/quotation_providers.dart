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
  QuotationQuery _query = const QuotationQuery();

  @override
  Future<Paged<Quotation>> build() async {
    _query = QuotationQuery(status: ref.watch(quotationStatusFilterProvider));
    return Paged.first(
      await ref.watch(quotationRepositoryProvider).list(_query),
    );
  }

  Future<void> loadMore() => loadNextPage(
    current: state.value,
    fetch: (page) =>
        ref.read(quotationRepositoryProvider).list(_query.atPage(page)),
    mounted: () => ref.mounted,
    emit: (next) => state = AsyncData(next),
  );
}

/// The newest quotations still waiting on the customer, for the sales home.
@riverpod
Future<List<Quotation>> awaitingQuotations(Ref ref) async {
  final result = await ref
      .watch(quotationRepositoryProvider)
      .list(const QuotationQuery(status: QuotationStatus.sent, size: 3));
  return result.items;
}

@riverpod
Future<Quotation> quotation(Ref ref, String id) =>
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

class QuotationDuplicated extends QuotationOutcome {
  const QuotationDuplicated(this.quotation);

  final Quotation quotation;
}

class QuotationConverted extends QuotationOutcome {
  const QuotationConverted(this.order);

  final SalesOrder order;
}

/// The actions on one quotation. The screen listens for the outcome to show
/// a message or move on.
@riverpod
class QuotationActions extends _$QuotationActions {
  @override
  AsyncValue<QuotationOutcome?> build(String id) => const AsyncData(null);

  Future<void> approve() => _run(
    () async => QuotationUpdated(
      await ref.read(quotationRepositoryProvider).approve(id),
    ),
  );

  Future<void> send() => _run(
    () async =>
        QuotationUpdated(await ref.read(quotationRepositoryProvider).send(id)),
  );

  Future<void> duplicate() => _run(
    () async => QuotationDuplicated(
      await ref.read(quotationRepositoryProvider).duplicate(id),
    ),
  );

  Future<void> convertToOrder() => _run(
    () async => QuotationConverted(
      await ref.read(quotationRepositoryProvider).convertToOrder(id),
    ),
  );

  Future<void> _run(Future<QuotationOutcome> Function() action) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (!ref.mounted) return;
    state = result;
    if (result.hasValue) refreshSales(ref);
  }
}
