import 'package:salesroot/features/settings/models/report_models.dart';

abstract interface class ReportRepository {
  Future<ReportOverview> overview(ReportQuery query);

  Future<SalesReport> sales(ReportQuery query);
}
