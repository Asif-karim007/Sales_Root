import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'session_api.g.dart';

@RestApi()
abstract class SessionApi {
  factory SessionApi(Dio dio) = _SessionApi;

  @POST('auth/refresh')
  Future<dynamic> refresh(@Body() Map<String, dynamic> body);

  @POST('auth/workspace/{id}')
  Future<dynamic> switchWorkspace(@Path('id') String id);

  @POST('auth/logout')
  Future<void> logout(
    @Header('Authorization') String bearer,
    @Body() Map<String, dynamic> body,
  );

  @GET('auth/me')
  Future<dynamic> me();
}
