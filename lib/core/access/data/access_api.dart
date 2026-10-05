import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'access_api.g.dart';

@RestApi()
abstract class AccessApi {
  factory AccessApi(Dio dio) = _AccessApi;

  @GET('billing')
  Future<dynamic> billing();

  @PATCH('workspaces/members/me')
  Future<void> updateMe(@Body() Map<String, dynamic> body);
}
