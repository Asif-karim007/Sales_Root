import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/data/collection_repository.dart';
import 'package:salesroot/features/sales/data/sales_api.dart';
import 'package:salesroot/features/sales/models/collection.dart';
import 'package:salesroot/features/sales/models/instalment.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';

class ApiCollectionRepository implements CollectionRepository {
  ApiCollectionRepository(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SalesApi _api;
  final DateTime Function() _clock;

  @override
  Future<CollectionSummary> summary() async {
    final [dues, week] = await Future.wait([
      apiRequest('Dues summary', _api.duesSummary),
      apiRequest(
        'Collection this week',
        () => _api.collectionReport({'preset': 'last_7', 'group': 'day'}),
      ),
    ]);
    return CollectionSummary.from(
      OutstandingSummary.fromJson(jsonMap(dues)),
      jsonMap(week),
    );
  }

  @override
  Future<PageResult<Collection>> list(int page) async {
    final json = await apiRequest(
      'Payment list',
      () => _api.payments(pageQuery(page)),
    );
    return PageResult.fromJson(jsonMap(json), Collection.fromJson);
  }

  @override
  Future<Collection> get(String id) async {
    final payment = Collection.fromJson(
      jsonMap(await apiRequest('Payment $id', () => _api.payment(id))),
    );
    final companyId = payment.companyId;
    if (companyId == null) return payment;
    final dues = await apiRequest(
      'Customer dues',
      () => _api.companyDues(companyId),
    );
    return payment.withBalance(
      _instalments(dues).fold(0, (sum, item) => sum + item.due),
    );
  }

  @override
  Future<CustomerDues> customerDues(String companyId) async {
    final [company, dues] = await Future.wait([
      apiRequest('Customer $companyId', () => _api.company(companyId)),
      apiRequest('Customer dues', () => _api.companyDues(companyId)),
    ]);
    final detail = jsonMap(jsonMap(company)['company']);
    return CustomerDues(
      companyId: companyId,
      companyName: detail['name'] as String? ?? '',
      items: _instalments(dues),
    );
  }

  @override
  Future<Collection> record(CollectionInput input) async => Collection.fromJson(
    jsonMap(
      await apiRequest(
        'Payment record',
        () => _api.createPayment(input.toJson()),
      ),
    ),
  );

  @override
  Future<Collection> setChequeStatus(String id, ChequeStatus status) async {
    await apiRequest(
      'Cheque ${status.wire}',
      () => _api.chequeStatus(id, {'status': status.wire}),
    );
    return get(id);
  }

  @override
  Future<Collection> cancel(String id, String reason) async {
    await apiRequest(
      'Payment cancel',
      () => _api.cancelPayment(id, {'reason': reason.trim()}),
    );
    return get(id);
  }

  @override
  Future<OutstandingSummary> outstandingSummary() async =>
      OutstandingSummary.fromJson(
        jsonMap(await apiRequest('Dues summary', _api.duesSummary)),
      );

  @override
  Future<PageResult<CustomerOutstanding>> outstanding(
    OutstandingQuery query,
  ) async {
    final json = await apiRequest('Dues', () => _api.dues(query.toQuery()));
    return PageResult.fromJson(jsonMap(json), CustomerOutstanding.fromJson);
  }

  /// A customer's open receivables, oldest first.
  List<Instalment> _instalments(dynamic json) {
    final today = _clock();
    return [
      for (final row in jsonList(json, (row) => row))
        Instalment.fromJson(row, today: today),
    ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
}
