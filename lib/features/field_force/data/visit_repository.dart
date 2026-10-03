import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';

abstract interface class VisitRepository {
  /// One member's visits on one day, in route order.
  Future<PageResult<Visit>> list(VisitQuery query);

  Future<Visit> get(int id);

  /// Plans a visit to a lead.
  Future<Visit> create(VisitInput input);

  /// Saves the route order the user dragged the stops into.
  Future<void> reorder(List<int> ids);

  /// 409 when another visit is still open; 400 when a far check-in has no
  /// reason or photo.
  Future<Visit> checkIn(int id, VisitCheckInInput input);

  Future<Visit> addNote(int id, String text);

  Future<Visit> addPhoto(int id, String path);

  Future<Visit> setSamples(int id, List<int> productIds);

  Future<Visit> checkOut(int id, VisitEndInput input);

  /// Leads the user can plan a visit to.
  Future<PageResult<VisitTarget>> targets(String term, int page);

  Future<VisitTarget> target(int leadId);

  Future<List<VisitProduct>> products();

  Future<VisitReport> report(VisitReportQuery query);

  Future<List<ReportMember>> members();
}
