import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salesroot/core/access/access_providers.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/workspace/workspace_providers.dart';

import '../../helpers/api_stub.dart';

const quoteId = '01a10101-8690-7963-915f-6bb20aa6c9e7';
const draftQuoteId = '01a10cf6-a6c4-7934-b41b-78b3d58041b7';
const orderId = '01a10101-869f-7916-b997-939393716475';
const confirmedOrderId = '01a10cf6-ec94-7f9b-a23c-7c03baa31ff7';
const invoiceId = '01a10101-86a8-78f8-a541-3fcb7add305d';
const paymentId = '01a10101-86b7-7e01-8f91-9b87ec1e2fb0';
const rahimId = '01a10101-8657-7f15-8630-b08119f1ae61';
const greenAgroId = '01a10101-865d-7e81-90c1-c811923c2adf';
const leadId = '01a10101-866a-7007-90bc-2326bcdb9d50';
const soapId = '01a10101-8689-78e8-a72d-31b71e965856';

/// Every sales endpoint, answering from the recorded responses of the test
/// user. Details answer by id where more than one was recorded.
ApiStub salesStub() => ApiStub()
  ..on('GET', 'products', fixture('sales_products'))
  ..on('GET', 'quotes', fixture('sales_quotes'))
  ..on(
    'GET',
    'quotes/{id}',
    (RequestOptions r) => r.path.endsWith(draftQuoteId)
        ? fixture('sales_quote_created')
        : fixture('sales_quote'),
  )
  ..on('POST', 'quotes', fixture('sales_quote_created'))
  ..on('PATCH', 'quotes/{id}', fixture('sales_quote_created'))
  ..on('POST', 'quotes/{id}/duplicate', fixture('sales_quote_duplicate'))
  ..on('POST', 'quotes/{id}/convert', fixture('sales_quote_convert'))
  ..on('POST', 'quotes/{id}/send', const {})
  ..on('GET', 'orders', fixture('sales_orders'))
  ..on(
    'GET',
    'orders/{id}',
    (RequestOptions r) => r.path.endsWith(confirmedOrderId)
        ? fixture('sales_order_confirmed')
        : fixture('sales_order'),
  )
  ..on('PATCH', 'orders/{id}', fixture('sales_order'))
  ..on('POST', 'orders/{id}/invoice', fixture('sales_invoice_created'))
  ..on('GET', 'invoices', fixture('sales_invoices'))
  ..on('GET', 'invoices/{id}', fixture('sales_invoice'))
  ..on('POST', 'invoices/{id}/instalments', fixture('sales_instalments'))
  ..on('GET', 'payments', fixture('sales_payments'))
  ..on('GET', 'payments/{id}', fixture('sales_payment'))
  ..on('POST', 'payments', fixture('sales_payment_created'))
  ..on('GET', 'dues', fixture('sales_dues'))
  ..on('GET', 'dues/summary', fixture('sales_dues_summary'))
  ..on('GET', 'companies', fixture('sales_companies'))
  ..on('GET', 'companies/{id}', fixture('sales_company'))
  ..on('GET', 'companies/{id}/dues', fixture('sales_company_dues'))
  ..on('GET', 'leads/{id}', fixture('sales_lead'))
  ..on('GET', 'workspaces/current', fixture('sales_workspace'))
  ..on(
    'GET',
    'reports/sales',
    (RequestOptions r) => r.queryParameters['preset'] == 'last_month'
        ? fixture('sales_report_sales_last_month')
        : fixture('sales_report_sales_month'),
  )
  ..on('GET', 'reports/collection', fixture('sales_report_collection_week'));

/// A signed-in container over [stub] as Rafi with [role], whose workspace and
/// grants are loaded. [fullAccess] grants every right in every module.
Future<ProviderContainer> salesContainer(
  ApiStub stub, {
  String role = 'executive',
  bool fullAccess = false,
}) async {
  final container = await apiContainer(
    stub,
    me: meWith(role: role, level: 'standard'),
    overrides: <Override>[
      if (fullAccess)
        moduleAccessProvider.overrideWith(
          (ref, module) => const ModuleAccess(
            canView: true,
            canAdd: true,
            canEdit: true,
            canDelete: true,
            canApprove: true,
            canExport: true,
          ),
        ),
    ],
  );
  container.listen(currentWorkspaceProvider, (_, _) {});
  await container.read(workspacesProvider.future);
  await container.read(permissionsProvider.future);
  return container;
}

void listenTo(ProviderContainer container, ProviderListenable<Object?> p) {
  final sub = container.listen(p, (_, _) {});
  addTearDown(sub.close);
}
