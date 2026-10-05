import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'field_api.g.dart';

@RestApi()
abstract class FieldApi {
  factory FieldApi(Dio dio) = _FieldApi;

  @GET('attendance/today')
  Future<dynamic> today();

  @POST('attendance/check-in')
  Future<dynamic> checkIn(@Body() Map<String, dynamic> body);

  @POST('attendance/check-out')
  Future<dynamic> checkOut(@Body() Map<String, dynamic> body);

  @GET('attendance')
  Future<dynamic> attendance(@Queries() Map<String, dynamic> query);

  @GET('reports/field')
  Future<dynamic> report(@Queries() Map<String, dynamic> query);

  @POST('visits/start')
  Future<dynamic> startVisit(@Body() Map<String, dynamic> body);

  @POST('visits/{id}/end')
  Future<dynamic> endVisit(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @GET('visits')
  Future<dynamic> visits(@Queries() Map<String, dynamic> query);

  @POST('locations')
  Future<dynamic> locations(@Body() Map<String, dynamic> body);

  @GET('team/map')
  Future<dynamic> teamMap(@Queries() Map<String, dynamic> query);

  @PATCH('field/settings')
  Future<dynamic> saveSettings(@Body() Map<String, dynamic> body);

  @GET('workspaces/current')
  Future<dynamic> workspace();

  @GET('workspaces/members')
  Future<dynamic> members();

  @GET('companies')
  Future<dynamic> companies(@Queries() Map<String, dynamic> query);

  @GET('companies/{id}')
  Future<dynamic> company(@Path('id') String id);

  @GET('leads/{id}')
  Future<dynamic> lead(@Path('id') String id);

  @POST('files')
  Future<dynamic> upload(@Body() FormData body);
}
