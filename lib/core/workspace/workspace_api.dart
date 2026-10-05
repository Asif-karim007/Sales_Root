import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'workspace_api.g.dart';

@RestApi()
abstract class WorkspaceApi {
  factory WorkspaceApi(Dio dio) = _WorkspaceApi;

  @GET('auth/me')
  Future<dynamic> me();

  @POST('workspaces')
  Future<dynamic> create(@Body() Map<String, dynamic> body);
}
