import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'settings_api.g.dart';

@RestApi()
abstract class SettingsApi {
  factory SettingsApi(Dio dio) = _SettingsApi;

  @GET('auth/devices')
  Future<dynamic> devices();

  @POST('auth/logout-all')
  Future<void> logoutAll();

  @PATCH('auth/me')
  Future<dynamic> updateMe(@Body() Map<String, dynamic> body);

  @GET('workspaces/pipelines')
  Future<dynamic> pipelines();

  @POST('workspaces/pipelines/{id}/stages')
  Future<dynamic> addStage(
    @Path('id') String pipelineId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('workspaces/stages/{id}')
  Future<dynamic> editStage(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('workspaces/stages/reorder')
  Future<dynamic> reorderStages(@Body() List<String> stageIds);

  @GET('workspaces/pack')
  Future<dynamic> pack();

  @GET('sync')
  Future<dynamic> pull(@Queries() Map<String, dynamic> query);

  @POST('sync')
  Future<dynamic> push(@Body() Map<String, dynamic> body);

  @POST('companies/import')
  Future<dynamic> importCompanies(@Body() Map<String, dynamic> body);

  @GET('reports/{name}')
  Future<dynamic> report(
    @Path('name') String name,
    @Queries() Map<String, dynamic> query,
  );
}
