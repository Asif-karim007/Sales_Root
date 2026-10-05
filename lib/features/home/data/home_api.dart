import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'home_api.g.dart';

@RestApi()
abstract class HomeApi {
  factory HomeApi(Dio dio) = _HomeApi;

  @GET('home')
  Future<dynamic> home();

  @GET('reports/me')
  Future<dynamic> myReport(@Queries() Map<String, dynamic> query);

  @GET('reports/pipeline')
  Future<dynamic> pipeline();

  @GET('reports/targets')
  Future<dynamic> targetReport(@Queries() Map<String, dynamic> query);

  @GET('reports/activity')
  Future<dynamic> activityReport(@Queries() Map<String, dynamic> query);

  @GET('reports/collection')
  Future<dynamic> collectionReport(@Queries() Map<String, dynamic> query);

  @GET('reports/sales')
  Future<dynamic> salesReport(@Queries() Map<String, dynamic> query);

  @GET('quotes')
  Future<dynamic> quotes(@Queries() Map<String, dynamic> query);

  @GET('attendance')
  Future<dynamic> attendance();

  @GET('ai/daily-summary')
  Future<dynamic> dailySummary(@Queries() Map<String, dynamic> query);

  @GET('targets')
  Future<dynamic> targets();

  @GET('dues')
  Future<dynamic> dues(@Queries() Map<String, dynamic> query);

  @GET('notifications')
  Future<dynamic> notifications(@Queries() Map<String, dynamic> query);

  @POST('notifications/read')
  Future<void> markRead(@Body() List<String> ids);
}
