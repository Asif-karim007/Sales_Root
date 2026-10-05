import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'sales_api.g.dart';

@RestApi()
abstract class SalesApi {
  factory SalesApi(Dio dio) = _SalesApi;

  @GET('products')
  Future<dynamic> products(@Queries() Map<String, dynamic> query);

  @POST('products')
  Future<dynamic> createProduct(@Body() Map<String, dynamic> body);

  @PATCH('products/{id}')
  Future<dynamic> editProduct(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('quotes')
  Future<dynamic> quotes(@Queries() Map<String, dynamic> query);

  @POST('quotes')
  Future<dynamic> createQuote(@Body() Map<String, dynamic> body);

  @GET('quotes/{id}')
  Future<dynamic> quote(@Path('id') String id);

  @PATCH('quotes/{id}')
  Future<dynamic> editQuote(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('quotes/{id}/approve')
  Future<dynamic> approveQuote(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('quotes/{id}/send')
  Future<dynamic> sendQuote(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('quotes/{id}/duplicate')
  Future<dynamic> duplicateQuote(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('quotes/{id}/convert')
  Future<dynamic> convertQuote(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('orders')
  Future<dynamic> orders(@Queries() Map<String, dynamic> query);

  @GET('orders/{id}')
  Future<dynamic> order(@Path('id') String id);

  @PATCH('orders/{id}')
  Future<dynamic> editOrder(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('orders/{id}/invoice')
  Future<dynamic> invoiceOrder(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('invoices')
  Future<dynamic> invoices(@Queries() Map<String, dynamic> query);

  @GET('invoices/{id}')
  Future<dynamic> invoice(@Path('id') String id);

  @POST('invoices/{id}/instalments')
  Future<dynamic> splitInvoice(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('invoices/{id}/cancel')
  Future<dynamic> cancelInvoice(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('payments')
  Future<dynamic> payments(@Queries() Map<String, dynamic> query);

  @POST('payments')
  Future<dynamic> createPayment(@Body() Map<String, dynamic> body);

  @GET('payments/{id}')
  Future<dynamic> payment(@Path('id') String id);

  @POST('payments/{id}/cheque')
  Future<dynamic> chequeStatus(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('payments/{id}/cancel')
  Future<dynamic> cancelPayment(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('dues')
  Future<dynamic> dues(@Queries() Map<String, dynamic> query);

  @GET('dues/summary')
  Future<dynamic> duesSummary();

  @GET('companies')
  Future<dynamic> companies(@Queries() Map<String, dynamic> query);

  @GET('companies/{id}')
  Future<dynamic> company(@Path('id') String id);

  @GET('companies/{id}/dues')
  Future<dynamic> companyDues(@Path('id') String id);

  @GET('leads/{id}')
  Future<dynamic> lead(@Path('id') String id);

  @GET('workspaces/current')
  Future<dynamic> workspace();

  @GET('reports/sales')
  Future<dynamic> salesReport(@Queries() Map<String, dynamic> query);

  @GET('reports/collection')
  Future<dynamic> collectionReport(@Queries() Map<String, dynamic> query);
}
