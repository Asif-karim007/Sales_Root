import 'package:collection/collection.dart';

import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/sales/data/quotation_repository.dart';
import 'package:salesroot/features/sales/data/sales_api.dart';
import 'package:salesroot/features/sales/models/quotation.dart';
import 'package:salesroot/features/sales/models/sales_order.dart';
import 'package:salesroot/features/sales/models/sales_party.dart';

class ApiQuotationRepository implements QuotationRepository {
  ApiQuotationRepository(this._api);

  final SalesApi _api;

  @override
  Future<PageResult<Quotation>> list(QuotationQuery query) async {
    final json = await apiRequest(
      'Quotation list',
      () => _api.quotes(query.toQuery()),
    );
    return PageResult.fromJson(jsonMap(json), Quotation.fromJson);
  }

  @override
  Future<Quotation> get(String id) async {
    final quotation = await _detail('Quotation $id', () => _api.quote(id));
    final companyId = quotation.companyId;
    if (quotation.status != QuotationStatus.accepted || companyId == null) {
      return quotation;
    }
    final orders = await apiRequest(
      'Quotation order',
      () => _api.orders({'companyId': companyId, ...pageQuery(1, size: 50)}),
    );
    final order = jsonList(
      jsonMap(orders)['items'],
      SalesOrder.fromJson,
    ).firstWhereOrNull((order) => order.quotationId == id);
    return order == null
        ? quotation
        : quotation.withOrder(order.id, order.number);
  }

  @override
  Future<Quotation> create(QuotationInput input) =>
      _detail('Quotation create', () => _api.createQuote(input.toJson()));

  @override
  Future<Quotation> save(String id, QuotationInput input) =>
      _detail('Quotation save', () => _api.editQuote(id, input.toJson()));

  @override
  Future<Quotation> approve(String id) async {
    await apiRequest('Quotation approve', () => _api.approveQuote(id, {}));
    return get(id);
  }

  @override
  Future<Quotation> send(String id) async {
    await apiRequest('Quotation send', () => _api.sendQuote(id, {}));
    return get(id);
  }

  @override
  Future<Quotation> duplicate(String id) =>
      _detail('Quotation duplicate', () => _api.duplicateQuote(id, {}));

  @override
  Future<SalesOrder> convertToOrder(String id) async {
    final json = jsonMap(
      await apiRequest('Quotation convert', () => _api.convertQuote(id, {})),
    );
    final orderId = jsonId(json['orderId']) ?? '';
    return SalesOrder.fromDetail(
      jsonMap(await apiRequest('Order $orderId', () => _api.order(orderId))),
    );
  }

  @override
  Future<List<SalesCustomer>> customers(String search, int page) async {
    final text = search.trim();
    final json = await apiRequest(
      'Customer lookup',
      () =>
          _api.companies({if (text.isNotEmpty) 'q': text, ...pageQuery(page)}),
    );
    return jsonList(jsonMap(json)['items'], SalesCustomer.fromCompany);
  }

  @override
  Future<SalesCustomer> customer(String companyId) async =>
      SalesCustomer.fromCompanyDetail(
        jsonMap(
          await apiRequest(
            'Customer $companyId',
            () => _api.company(companyId),
          ),
        ),
      );

  @override
  Future<SalesCustomer> customerForLead(String leadId) async {
    final json = jsonMap(
      await apiRequest('Lead $leadId', () => _api.lead(leadId)),
    );
    return SalesCustomer.fromLead(jsonMap(json['lead']));
  }

  @override
  Future<SellerProfile> seller() async => SellerProfile.fromJson(
    jsonMap(await apiRequest('Workspace', _api.workspace)),
  );

  Future<Quotation> _detail(
    String label,
    Future<dynamic> Function() request,
  ) async => Quotation.fromDetail(jsonMap(await apiRequest(label, request)));
}
