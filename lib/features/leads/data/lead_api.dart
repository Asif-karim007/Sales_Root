import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'lead_api.g.dart';

@RestApi()
abstract class LeadApi {
  factory LeadApi(Dio dio) = _LeadApi;

  @GET('leads')
  Future<dynamic> list(@Queries() Map<String, dynamic> query);

  @GET('leads/{id}')
  Future<dynamic> get(@Path('id') String id);

  @POST('leads')
  Future<dynamic> create(@Body() Map<String, dynamic> body);

  @PATCH('leads/{id}')
  Future<dynamic> edit(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('leads/{id}')
  Future<void> delete(@Path('id') String id);

  @POST('leads/{id}/restore')
  Future<dynamic> restore(@Path('id') String id);

  @GET('leads/check-phone')
  Future<dynamic> checkPhone(@Query('phone') String phone);

  @POST('leads/{id}/stage')
  Future<dynamic> moveStage(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('leads/{id}/won')
  Future<dynamic> won(@Path('id') String id, @Body() Map<String, dynamic> body);

  @POST('leads/{id}/lost')
  Future<dynamic> lost(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('leads/{id}/reopen')
  Future<dynamic> reopen(@Path('id') String id);

  @POST('leads/{id}/assign')
  Future<dynamic> assign(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('workspaces/pipelines')
  Future<dynamic> pipelines();

  @GET('workspaces/current')
  Future<dynamic> workspace();

  @GET('workspaces/members')
  Future<dynamic> members();

  @POST('activities')
  Future<dynamic> logActivity(@Body() Map<String, dynamic> body);

  @POST('tasks/{id}/done')
  Future<dynamic> completeTask(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('companies')
  Future<dynamic> companies(@Queries() Map<String, dynamic> query);

  @GET('companies/{id}')
  Future<dynamic> company(@Path('id') String id);

  @POST('companies')
  Future<dynamic> createCompany(@Body() Map<String, dynamic> body);

  @GET('contacts')
  Future<dynamic> contacts(@Queries() Map<String, dynamic> query);

  @GET('contacts/{id}')
  Future<dynamic> contact(@Path('id') String id);

  @GET('ai/status')
  Future<dynamic> aiStatus();

  @POST('ai/parse')
  Future<dynamic> parse(@Body() Map<String, dynamic> body);
}
