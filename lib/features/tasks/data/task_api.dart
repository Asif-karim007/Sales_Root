import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'task_api.g.dart';

@RestApi()
abstract class TaskApi {
  factory TaskApi(Dio dio) = _TaskApi;

  @GET('tasks')
  Future<dynamic> list(@Queries() Map<String, dynamic> query);

  @POST('tasks')
  Future<dynamic> create(@Body() Map<String, dynamic> body);

  @PATCH('tasks/{id}')
  Future<dynamic> edit(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('tasks/{id}')
  Future<void> delete(@Path('id') String id);

  @POST('tasks/{id}/done')
  Future<dynamic> done(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('tasks/{id}/move')
  Future<dynamic> move(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('tasks/{id}/assign')
  Future<dynamic> assign(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('leads')
  Future<dynamic> leads(@Queries() Map<String, dynamic> query);

  @GET('leads/{id}')
  Future<dynamic> lead(@Path('id') String id);

  @GET('workspaces/members')
  Future<dynamic> members();

  @GET('companies')
  Future<dynamic> companies(@Queries() Map<String, dynamic> query);
}
