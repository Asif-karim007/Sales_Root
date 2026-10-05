import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'hr_api.g.dart';

@RestApi()
abstract class HrApi {
  factory HrApi(Dio dio) = _HrApi;

  @GET('hr/leave/types')
  Future<dynamic> leaveTypes();

  @GET('hr/leave/balance')
  Future<dynamic> leaveBalance(@Queries() Map<String, dynamic> query);

  @GET('hr/leave')
  Future<dynamic> leaves(@Queries() Map<String, dynamic> query);

  @POST('hr/leave')
  Future<dynamic> createLeave(@Body() Map<String, dynamic> body);

  @POST('hr/leave/{id}/cancel')
  Future<void> cancelLeave(@Path('id') String id);

  @GET('hr/holidays')
  Future<dynamic> holidays(@Queries() Map<String, dynamic> query);

  @GET('hr/expenses/categories')
  Future<dynamic> expenseCategories();

  @GET('hr/expenses')
  Future<dynamic> expenses(@Queries() Map<String, dynamic> query);

  @POST('hr/expenses')
  Future<dynamic> createExpense(@Body() Map<String, dynamic> body);

  @DELETE('hr/expenses/{id}')
  Future<void> deleteExpense(@Path('id') String id);

  @GET('approvals')
  Future<dynamic> approvals(@Queries() Map<String, dynamic> query);

  @POST('approvals/{id}/{action}')
  Future<dynamic> decide(
    @Path('id') String id,
    @Path('action') String action,
    @Body() Map<String, dynamic> body,
  );

  @GET('hr/payslips/me')
  Future<dynamic> myPayslips();

  @GET('hr/payslips/{id}')
  Future<dynamic> payslip(@Path('id') String id);

  @GET('hr/payroll')
  Future<dynamic> payrollRuns();

  @GET('hr/payroll/{id}')
  Future<dynamic> payrollRun(@Path('id') String id);

  @GET('hr/salary/me')
  Future<dynamic> mySalary();

  @GET('hr/salary/{membershipId}/history')
  Future<dynamic> salaryHistory(@Path('membershipId') String membershipId);

  @PUT('hr/salary/{membershipId}')
  Future<dynamic> saveSalary(
    @Path('membershipId') String membershipId,
    @Body() Map<String, dynamic> body,
  );

  @GET('workspaces/members')
  Future<dynamic> members();

  @GET('visits')
  Future<dynamic> visits(@Queries() Map<String, dynamic> query);

  @GET('companies')
  Future<dynamic> companies(@Queries() Map<String, dynamic> query);

  @POST('tickets')
  Future<dynamic> createTicket(@Body() Map<String, dynamic> body);

  @GET('tickets/{id}')
  Future<dynamic> ticket(@Path('id') String id);

  @PATCH('tickets/{id}')
  Future<void> updateTicket(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('tickets/{id}/reply')
  Future<void> replyTicket(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('files')
  Future<dynamic> upload(@Body() FormData body);
}
