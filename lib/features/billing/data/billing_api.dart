import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'billing_api.g.dart';

@RestApi()
abstract class BillingApi {
  factory BillingApi(Dio dio) = _BillingApi;

  @GET('billing/catalogue')
  Future<dynamic> catalogue();

  @GET('billing')
  Future<dynamic> billing();

  @POST('billing/quote')
  Future<dynamic> quote(@Body() Map<String, dynamic> body);

  @POST('billing/checkout')
  Future<dynamic> checkout(@Body() Map<String, dynamic> body);

  @POST('billing/verify/{txId}')
  Future<dynamic> verify(@Path('txId') String transactionId);

  @GET('billing/history')
  Future<dynamic> history();

  @GET('referrals')
  Future<dynamic> referrals(@Queries() Map<String, dynamic> query);

  @POST('referrals')
  Future<dynamic> refer(@Body() Map<String, dynamic> body);

  @GET('referrals/check')
  Future<dynamic> checkReferral(@Queries() Map<String, dynamic> query);

  @GET('wallet/transactions')
  Future<dynamic> walletTransactions(@Queries() Map<String, dynamic> query);

  @GET('contacts')
  Future<dynamic> contacts(@Queries() Map<String, dynamic> query);
}
