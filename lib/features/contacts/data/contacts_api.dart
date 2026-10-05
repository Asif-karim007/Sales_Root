import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'contacts_api.g.dart';

@RestApi()
abstract class ContactsApi {
  factory ContactsApi(Dio dio) = _ContactsApi;

  @GET('contacts')
  Future<dynamic> contacts(@Queries() Map<String, dynamic> query);

  @POST('contacts')
  Future<dynamic> createContact(@Body() Map<String, dynamic> body);

  @GET('contacts/{id}')
  Future<dynamic> contact(@Path('id') String id);

  @PATCH('contacts/{id}')
  Future<dynamic> editContact(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('contacts/{id}')
  Future<void> deleteContact(@Path('id') String id);

  @GET('companies')
  Future<dynamic> companies(@Queries() Map<String, dynamic> query);

  @POST('companies')
  Future<dynamic> createCompany(@Body() Map<String, dynamic> body);

  @GET('companies/{id}')
  Future<dynamic> company(@Path('id') String id);

  @PATCH('companies/{id}')
  Future<dynamic> editCompany(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('companies/{id}')
  Future<void> deleteCompany(@Path('id') String id);

  @GET('workspaces/current')
  Future<dynamic> workspace();

  @GET('invoices')
  Future<dynamic> invoices(@Queries() Map<String, dynamic> query);

  @GET('quotes')
  Future<dynamic> quotes(@Queries() Map<String, dynamic> query);

  @POST('files')
  Future<dynamic> upload(@Body() FormData body);

  @GET('files/{key}')
  @DioResponseType(ResponseType.bytes)
  Future<dynamic> file(@Path('key') String key);
}
