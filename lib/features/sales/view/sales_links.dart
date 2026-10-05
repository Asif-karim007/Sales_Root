import 'package:salesroot/core/routing/routes.dart';

/// `/collection/new?customerId=&invoiceId=`
String collectionNewFor({String? customerId, String? invoiceId}) => Uri(
  path: Routes.collectionNew,
  queryParameters: {'customerId': ?customerId, 'invoiceId': ?invoiceId},
).toString();

/// `/quotations/new?leadId=&edit=`
String quotationNewFor({String? leadId, String? editId}) => Uri(
  path: Routes.quotationNew,
  queryParameters: {'leadId': ?leadId, 'edit': ?editId},
).toString();
