import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'growth_api.g.dart';

@RestApi()
abstract class GrowthApi {
  factory GrowthApi(Dio dio) = _GrowthApi;

  @GET('integrations')
  Future<dynamic> integrations();

  @DELETE('integrations/{id}')
  Future<void> deleteIntegration(@Path('id') String id);

  @POST('integrations/whatsapp/connect')
  Future<dynamic> connectWhatsApp(@Body() Map<String, dynamic> body);

  @GET('forms')
  Future<dynamic> forms();

  @POST('forms')
  Future<dynamic> createForm(@Body() Map<String, dynamic> body);

  @PATCH('forms/{id}')
  Future<dynamic> updateForm(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('inbox')
  Future<dynamic> inbox(@Queries() Map<String, dynamic> query);

  @GET('inbox/{id}')
  Future<dynamic> conversation(@Path('id') String id);

  @POST('inbox/{id}/take')
  Future<void> take(@Path('id') String id);

  @POST('inbox/{id}/assign/{membershipId}')
  Future<void> assign(
    @Path('id') String id,
    @Path('membershipId') String membershipId,
  );

  @POST('inbox/{id}/close')
  Future<void> close(@Path('id') String id);

  @POST('inbox/{id}/reply')
  Future<dynamic> reply(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('workspaces/members')
  Future<dynamic> members();

  @GET('templates')
  Future<dynamic> templates(@Query('channel') String? channel);

  @POST('ai/draft')
  Future<dynamic> draft(@Body() Map<String, dynamic> body);

  @GET('campaigns')
  Future<dynamic> campaigns();

  @GET('campaigns/{id}')
  Future<dynamic> campaign(@Path('id') String id);

  @POST('campaigns')
  Future<dynamic> createCampaign(@Body() Map<String, dynamic> body);

  @POST('campaigns/preview')
  Future<dynamic> preview(@Body() Map<String, dynamic> body);

  @POST('campaigns/{id}/cancel')
  Future<void> cancelCampaign(@Path('id') String id);
}
