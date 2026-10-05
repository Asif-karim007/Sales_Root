import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/network/api_request.dart';
import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/contacts/data/contacts_api.dart';
import 'package:salesroot/features/contacts/data/customer_repository.dart';
import 'package:salesroot/features/contacts/models/company_detail.dart';
import 'package:salesroot/features/contacts/models/customer.dart';

/// Customer 360 from `GET companies/{id}` plus the customer's invoices and
/// quotations. A list the role may not see (403) counts as empty.
class ApiCustomerRepository implements CustomerRepository {
  ApiCustomerRepository(this._api);

  static const _scanSize = 100;
  static const _scanPages = 10;

  final ContactsApi _api;

  @override
  Future<CustomerSummary> summary(String companyId) async {
    final results = await Future.wait<dynamic>([
      apiRequest('Customer $companyId', () => _api.company(companyId)),
      _all('Customer invoices', companyId, _api.invoices),
      _all('Customer quotations', companyId, _api.quotes),
    ]);
    final detail = CompanyDetail.fromJson(jsonMap(results[0]));
    final company = detail.company;
    return CustomerSummary(
      companyId: company.id,
      companyName: company.name,
      outstanding: company.outstanding,
      overdue: company.overdue,
      leads: detail.leads,
      quotations: jsonList(results[2], SalesDocRef.fromQuote),
      orders: detail.orders,
      invoices: jsonList(results[1], SalesDocRef.fromInvoice),
      payments: detail.payments,
      activities: detail.activities,
      documents: detail.documents,
    );
  }

  @override
  Future<void> upload(String companyId, DocumentUpload upload) => apiRequest(
    'Document upload',
    () => _api.upload(
      FormData.fromMap({
        'file': MultipartFile.fromBytes(
          upload.bytes,
          filename: upload.fileName,
        ),
        'entityType': 'company',
        'entityId': companyId,
      }),
    ),
  );

  @override
  Future<Uint8List> download(CustomerDocument document) async {
    final bytes = await apiRequest(
      'Document ${document.id}',
      () => _api.file(document.key),
    );
    return bytes is List<int> ? Uint8List.fromList(bytes) : Uint8List(0);
  }

  /// Every row of a `companyId`-filtered list, a page of [_scanSize] at a
  /// time.
  Future<List<Map<String, dynamic>>> _all(
    String label,
    String companyId,
    Future<dynamic> Function(Map<String, dynamic> query) request,
  ) async {
    final rows = <Map<String, dynamic>>[];
    try {
      for (var page = 1; page <= _scanPages; page++) {
        final json = jsonMap(
          await apiRequest(
            label,
            () => request({
              'companyId': companyId,
              ...pageQuery(page, size: _scanSize),
            }),
          ),
        );
        final items = jsonList(json['items'], (row) => row);
        rows.addAll(items);
        final total = jsonInt(json['total']) ?? rows.length;
        if (items.isEmpty || rows.length >= total) break;
      }
    } on ApiFailure catch (failure) {
      if (!failure.isForbidden) rethrow;
    }
    return rows;
  }
}
