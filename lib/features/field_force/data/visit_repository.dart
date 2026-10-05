import 'package:salesroot/core/paging/paged.dart';
import 'package:salesroot/features/field_force/models/visit.dart';
import 'package:salesroot/features/field_force/models/visit_report.dart';

abstract interface class VisitRepository {
  Future<PageResult<Visit>> list(VisitQuery query);

  Future<Visit> get(String id);

  /// Starts a visit at a customer where the phone is.
  Future<Visit> start(VisitStartInput input);

  /// Ends [id] with an outcome; [photoPaths] are uploaded first and sent as
  /// file keys.
  Future<Visit> end(
    String id,
    VisitEndInput input, {
    List<String> photoPaths = const [],
  });

  /// Customers the user can visit.
  Future<PageResult<VisitTarget>> targets(String term, int page);

  Future<VisitTarget> target(String companyId);

  /// The lead's customer, with the lead attached; null when the lead has
  /// no customer.
  Future<VisitTarget?> leadTarget(String leadId);

  /// The workspace's visit outcomes.
  Future<List<VisitOutcomeOption>> outcomes();

  Future<VisitReport> report(VisitReportQuery query);

  Future<List<ReportMember>> members();
}
