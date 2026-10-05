import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

/// Sign-in calls. Built on the bare client: the token, when one is needed,
/// is the pending sign-up session's and is passed explicitly.
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  @POST('auth/otp/request')
  Future<dynamic> requestCode(@Body() Map<String, dynamic> body);

  @POST('auth/otp/verify')
  Future<dynamic> verifyCode(@Body() Map<String, dynamic> body);

  @GET('auth/me')
  Future<dynamic> me(@Header('Authorization') String bearer);

  @PATCH('auth/me')
  Future<dynamic> updateMe(
    @Header('Authorization') String bearer,
    @Body() Map<String, dynamic> body,
  );

  @POST('auth/pin')
  Future<void> setPin(
    @Header('Authorization') String bearer,
    @Body() Map<String, dynamic> body,
  );

  @POST('auth/workspace/{id}')
  Future<dynamic> switchWorkspace(
    @Header('Authorization') String bearer,
    @Path('id') String id,
  );

  @POST('workspaces')
  Future<dynamic> createWorkspace(
    @Header('Authorization') String bearer,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('workspaces/current')
  Future<dynamic> updateWorkspace(
    @Header('Authorization') String bearer,
    @Body() Map<String, dynamic> body,
  );

  @POST('workspaces/invites/{id}/accept')
  Future<dynamic> acceptInvite(
    @Header('Authorization') String bearer,
    @Path('id') String membershipId,
  );

  @POST('workspaces/invites/{id}/decline')
  Future<dynamic> declineInvite(
    @Header('Authorization') String bearer,
    @Path('id') String membershipId,
  );

  @GET('public/referral/{code}')
  Future<dynamic> referral(@Path('code') String code);
}
