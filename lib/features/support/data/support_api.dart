import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'support_api.g.dart';

@RestApi()
abstract class SupportApi {
  factory SupportApi(Dio dio) = _SupportApi;

  @POST('help/ticket')
  Future<dynamic> createTicket(@Body() Map<String, dynamic> body);

  @GET('help/tickets')
  Future<dynamic> tickets();

  @GET('help/tickets/{id}')
  Future<dynamic> ticket(@Path('id') String id);

  @POST('help/tickets/{id}/reply')
  Future<void> reply(@Path('id') String id, @Body() Map<String, dynamic> body);

  @POST('help/feedback')
  Future<void> feedback(@Body() Map<String, dynamic> body);

  @GET('ai/status')
  Future<dynamic> aiStatus();

  @POST('ai/guide')
  Future<dynamic> guide(@Body() Map<String, dynamic> body);

  @POST('ai/guide/rate')
  Future<void> rateGuide(@Body() Map<String, dynamic> body);

  @POST('files')
  Future<dynamic> upload(@Body() FormData body);
}
