import 'package:salesroot/core/routing/routes.dart';
import 'package:salesroot/features/sales/models/outstanding.dart';

/// `/collection/new?customerId=&invoiceId=&orderId=`
String collectionNewFor({int? customerId, int? invoiceId, int? orderId}) => Uri(
  path: Routes.collectionNew,
  queryParameters: {
    'customerId': ?customerId?.toString(),
    'invoiceId': ?invoiceId?.toString(),
    'orderId': ?orderId?.toString(),
  },
).toString();

/// Collects on [due]: against its bill, or its order before there is one.
String collectionNewForDue(DueRow due) => collectionNewFor(
  customerId: due.companyId,
  invoiceId: due.invoiceId,
  orderId: due.invoiceId == null ? due.orderId : null,
);

/// `/quotations/new?leadId=&from=&mode=revise`
String quotationNewFor({int? leadId, int? fromId, bool revise = false}) => Uri(
  path: Routes.quotationNew,
  queryParameters: {
    'leadId': ?leadId?.toString(),
    'from': ?fromId?.toString(),
    if (revise) 'mode': 'revise',
  },
).toString();
