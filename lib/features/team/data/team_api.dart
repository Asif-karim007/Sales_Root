import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'team_api.g.dart';

@RestApi()
abstract class TeamApi {
  factory TeamApi(Dio dio) = _TeamApi;

  @GET('workspaces/members')
  Future<dynamic> members();

  @POST('workspaces/members/invite')
  Future<dynamic> invite(@Body() Map<String, dynamic> body);

  @PATCH('workspaces/members/{id}')
  Future<dynamic> updateMember(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('attendance')
  Future<dynamic> attendance();

  @GET('targets')
  Future<dynamic> targets();

  @GET('leads')
  Future<dynamic> leads(@Queries() Map<String, dynamic> query);

  @GET('tasks')
  Future<dynamic> tasks(@Queries() Map<String, dynamic> query);

  @GET('billing/catalogue')
  Future<dynamic> catalogue();
}
